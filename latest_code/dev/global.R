################################ LOAD LIBRARIES ################################
if(!require(shiny)){install.packages("shiny");library(shiny)}else{library(shiny)}
if(!require(shinydashboard)){install.packages("shinydashboard");library(shinydashboard)}else{library(shinydashboard)}
if(!require(DT)){install.packages("DT");library(DT)}else{library(DT)}
#devtools::install_github("r-lib/rlang", build_vignettes = TRUE)
#devtools::install_github('hadley/ggplot2')
###importnat 
#install.packages("https://cran.rstudio.com/bin/macosx/el-capitan/contrib/3.4/dplyr_0.7.8.tgz", repos = NULL)

##install.packages("https://cran.r-project.org/src/contrib/Archive/Rcpp/Rcpp_0.12.19.tar.gz", repos = NULL)
## install.packages("https://cran.rstudio.com/bin/macosx/el-capitan/contrib/3.4/bindrcpp_0.2.2.tgz", repos = NULL)
##install.packages("https://cran.rstudio.com/bin/macosx/el-capitan/contrib/3.4/bindr_0.1.1.tgz", repos = NULL)

######
library(tidyverse)
if(!require(ggplot2)){install.packages("ggplot2");library(ggplot2)}else{library(ggplot2)}
if(!require(plotly)){install.packages("plotly");library(plotly)}else{library(plotly)}
if(!require(foreach)){install.packages("foreach");library(foreach)}else{library(foreach)}
if(!require(dplyr)){install.packages("dplyr");library(dplyr)}else{library(dplyr)}
if(!require(RcppRoll)){install.packages("RcppRoll");library(RcppRoll)}else{library(RcppRoll)}

if(!require(prophet)){install.packages("prophet");library(prophet)}else{library(prophet)}
if(!require(gtools)){install.packages("gtools");library(gtools)}else{library(gtools)}
# if(!require(dmmfR)){
  # install.packages("dmmfR", repos=c("https://nexus.support.data-lab.io/repository/dslab-r", getOption("repos")), dependencies = TRUE);
  # library(dmmfR)}else{library(dmmfR)}

# if(!require(forecastingFrameworkR)){
#   install.packages("forecastingFrameworkR", repos=c("https://nexus.support.data-lab.io/repository/dslab-r", getOption("repos")), dependencies = TRUE)
#   library(forecastingFrameworkR)}else{library(forecastingFrameworkR)}

#if(!require(bigrquery)){install.packages("bigrquery");library(bigrquery)}else{library(bigrquery)}
#if(!require(shinyjs)){install.packages("shinyjs");library(shinyjs)}else{library(shinyjs)}

############################
## Data import parameters ##
############################

shops_filter <- NULL # NULL or vector of shops to filter
products_filter <- NULL #c(1, 2, 3, 25, 28, 33) # NULL or vector of products to filter
categories_filter <- NULL #c("cat_2") # NULL or vector of categories to filter
Y <- 'log_demand'
REMOVE_OOS <- FALSE


# Make sure all output goes to the log file

sink(file=stderr())
options(width=160)

###############################################
## Data imports in tabs/data_import_module.R ##
###############################################


####################
### LOAD MODULES ###
####################



my_modules <- list.files("tabs", pattern = "_module\\.R$", full.names = TRUE,
                         recursive = TRUE)

for(my_module in my_modules) source(my_module)

################
### Settings ###
################

num_cores <- 3  # number of processor cores
options(mc.cores = num_cores)

model_function <- function(data, ...){
  prophet(daily.seasonality = FALSE,
          #yearly.seasonality=FALSE,
          changepoint.prior.scale = 0.01
  ) %>%
    add_regressor('SNOW', standardize = FALSE) %>%
    add_regressor('log_price', standardize = FALSE) %>%
    add_regressor('RAIN', standardize = FALSE) %>%
    add_regressor('IS_HOLIDAY', standardize = FALSE) %>%
    add_regressor('NEARBYCAR', standardize = FALSE) %>%
    add_regressor('DIRECT_COMPETITOR', standardize = FALSE) %>%
    add_regressor('INDIRECT_COMPETITOR', standardize = FALSE) %>%
    add_regressor('STORE_SATURATION', standardize = FALSE) %>%
    fit.prophet(df = data #, algorithm='Newton'
    )
}



#########################
### support functions ###
#########################

formatTableCell <- function(df, cols=NULL, rows=NULL, currency="$", digits=0, color_lowerbound = list(red=-Inf, grey=-5, green=5)){
  rows <- if(is.null(rows)){1:nrow(df)}else{rows}
  cols <- if(is.null(cols)){1:ncol(df)}else{cols}
  
  vals <- df[rows, cols]
  # round to digits
  vals <- round(df[rows, cols], digits=digits)
  format_vals <- vals
  
  if(!is.null(currency) && currency != ""){
    format_curr <- sapply(vals, function(v) format(as.numeric(v), nsmall=0, big.mark=","))
    format_vals <- sapply(format_curr, function(v) paste0(currency, v))
  }
  
  if(!is.null(color_lowerbound) && length(color_lowerbound)>0){
    breaks = c(as.vector(color_lowerbound), Inf)
    color_vals <- sapply(vals, function(v) names(color_lowerbound)[cut(v,breaks = breaks, labels=FALSE, right =FALSE)])
    format_vals <- paste0('<span style="color:', color_vals,'"><b>',format_vals,'<b></span>')
  }
  
  df[rows, cols] <- format_vals
  return(df)
}


#####################
### reactive list ###
#####################                         

reactive_list <- reactiveValues()
reactive_cluster_list <- reactiveValues()

reactive_list$products <- product_data %>%
  mutate(PRODUCT = as.character(PRODUCT)) %>% 
  select(PRODUCT, NAME, ROTATION_CLASS, COST, PRICE, PRICE_ELASTICITY,  mean_week_demand)

reactive_cluster_list$products <- product_data %>%
  mutate(PRODUCT = as.character(PRODUCT)) %>% 
  select(PRODUCT, NAME, ROTATION_CLASS, COST, PRICE, PRICE_ELASTICITY,  mean_week_demand)

############# reactive_list Competitor #############

reactive_list$competitor <- Competitor_data %>%
  mutate(PRODUCT = as.character(PRODUCT)) %>% 
  select(PRODUCT, SHOP, maxPrice)

#######################################################


reactive_list$workflow <- ModelWorkflow() %>%
  initialize_metadata(model_name = "Price_optimization_prophet_demo",
                      model_type = "prophet",
                      is_model_factory = TRUE,
                      use_case_name = "Demo of price optimization and dynamic regression demand modelling") %>%
  add_raw_data(path = df_processed) %>%
  
  define_features(feature_names = c('log_price'
                                    ,'SNOW'
                                    , 'RAIN' 
                                    ,'IS_HOLIDAY'
                                    ,'NEARBYCAR'
                                    ,'DIRECT_COMPETITOR'
                                    ,'INDIRECT_COMPETITOR'
                                    ,'STORE_SATURATION' 
  ),
  target_name = 'y',
  grouping_variables = c('PRODUCT', 'SHOP')) %>%
  partition_ts_data(test_from = as.Date('2018-10-30'), train_p = 1, test_p = 0) %>%
  update_metadata(
    logged_price = TRUE,
    logged_sales = TRUE,
    opt_var = 'log_price',
    target_var = 'y'
  )

reactive_cluster_list$cluster_workflow <- ModelWorkflow() %>%
  initialize_metadata(model_name = "Price_optimization_by_cluster",
                      model_type = "prophet",
                      is_model_factory = TRUE,
                      use_case_name = "Demo of price optimization and dynamic regression demand modelling") %>%
  add_raw_data(path = df_processed) %>%
  define_features(feature_names = c('log_price'
                                    ,'SNOW'
                                    , 'RAIN' 
                                    ,'IS_HOLIDAY'
                                    ,'NEARBYCAR'
                                    ,'DIRECT_COMPETITOR'
                                    ,'INDIRECT_COMPETITOR'
                                    ,'STORE_SATURATION' 
  ),
  target_name = 'y',
  grouping_variables = c('PRODUCT', 'CLUSTER')) %>%
  partition_ts_data(test_from = as.Date('2018-10-30'), train_p = 1, test_p = 0) %>%
  update_metadata(
    logged_price = TRUE,
    logged_sales = TRUE,
    opt_var = 'log_price',
    target_var = 'y'
  )                     




reactive_list$validated <- FALSE
reactive_list$optim_results <- list()
reactive_list$trained_models <- c()
reactive_list$forecasts <- list()
reactive_list$plot_components <- list()

reactive_cluster_list$validated <- FALSE
reactive_cluster_list$optim_results <- list()
reactive_cluster_list$trained_models <- c()
reactive_cluster_list$forecasts <- list()
reactive_cluster_list$plot_components <- list()




################ Price Elasticity ###############
#reactive_list_Price <- reactiveValues()

#reactive_list_Price$Price_Store_Wise <- Price_Store_Wise_Data %>%
# select(storeNum1, ProductSubGroup, count_of_ReceiptID, AvgLineItemTotal )  


##############################################
