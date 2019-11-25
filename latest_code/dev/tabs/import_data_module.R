
results_data <- readRDS("/Users/sk186089/Desktop/latest_code/dev/data/results.rds")
#################  ######################
#print(results_data %>% head(2) )
#saveRDS(product_data, file = 'data/products.rds')
product_data <- readRDS("/Users/sk186089/Desktop/latest_code/dev/data/products.rds")
###############################################################
#print(product_data %>% head(2) )


#saveRDS(Price_Store_Wise, file = 'data/Price_Store_Wise_opi.rds')
Price_Store_Wise_Data <- readRDS("/Users/sk186089/Desktop/latest_code/dev/data/Price_Store_Wise_opi_latest.rds")
print('printing Price_Store_Wise_Data data')
print(Price_Store_Wise_Data %>% head(2) )
######################data For Address  ##################

#saveRDS(Store_Date, file = 'data/Store_LOC_Date.rds')
Store_Date <- readRDS("/Users/sk186089/Desktop/latest_code/dev/data/Store_LOC_Date.rds")
#print('printing store data')
#print(Store_Date %>% head(2) )
################# data for store clustering  ####################################

#saveRDS(Store_Date, file = 'data/Store_Graph_Date.rds')
store <- readRDS("/Users/sk186089/Desktop/latest_code/dev/data/Store_Graph_Date_latest.rds")
#print('printing store Store_Graph_Date.rds')
#print(store %>% head(2) )
#################################################################
Competitor_data<- readRDS("/Users/sk186089/Desktop/latest_code/dev/data/Competitor_data.rds")
#print('printing store Competitor_data.rds')

#print(Competitor_data %>% head(2) )
#################################################




if(!("NAME" %in% names(product_data))) product_data$NAME <- product_data$PRODUCT

df_processed <-  results_data %>%
  mutate(SALES = DEMANDED_PRODUCT - LOST_DEMAND,
         OOS = ifelse(STOCK_LEVEL < DEMANDED_PRODUCT, 1, 0),
         log_sales = log(SALES + 1),
         log_demand = log(DEMANDED_PRODUCT + 1),
         log_price = log(PRICE),
         #log_price = log(abs(PRICE)),
         ds = as.POSIXct(DATE)) %>%
  inner_join(product_data %>%
               select(PRODUCT, NAME, CATEGORY, COST, ROTATION_CLASS, PRICE_ELASTICITY), by = 'PRODUCT') %>%
  select(ds, PRODUCT, SHOP
         , CLUSTER
         , NAME, CATEGORY, ROTATION_CLASS, DEMANDED_PRODUCT, log_demand,
         STOCK_LEVEL, OOS, PRICE, log_price, SALES, log_sales, APPLIED_MKDOWN, LICOST, PRICE_ELASTICITY
         , RAIN
         , SNOW
         ,NEARBYCAR,DIRECT_COMPETITOR, INDIRECT_COMPETITOR, STORE_SATURATION,IS_HOLIDAY 
  ) %>%
  # mutate(PRODUCT = factor(PRODUCT),
  #        SHOP = factor(SHOP)) %>%
  group_by(PRODUCT, SHOP) %>%
  mutate(STOCK_MORNING = lag(STOCK_LEVEL)) %>%
  #mutate(STOCK_MORNING = (STOCK_LEVEL)) %>%
  ungroup 


# print(df_processed)



if(REMOVE_OOS){
  df_processsed <- df_processed %>%
    filter(!is.na(STOCK_MORNING),
           STOCK_MORNING > 0,
           STOCK_LEVEL > 0) 
}

if(!is.null(products_filter)){
  df_processed <- df_processed %>% 
    filter(PRODUCT %in% products_filter)
}

if(!is.null(shops_filter)){
  df_processed <- df_processed %>% 
    filter(SHOP %in% shops_filter)
}

if(!is.null(categories_filter)){
  df_processed <- df_processed %>% 
    filter(CATEGORY %in% categories_filter)
}

prod_weekly_demand <- df_processed %>% 
  group_by(PRODUCT, SHOP) %>% 
  mutate(week_demand = RcppRoll::roll_sum(DEMANDED_PRODUCT, 7, align ="left", na.rm=TRUE, fill=NA)) %>%
  group_by(PRODUCT) %>%
  summarise(mean_week_demand = round(mean(week_demand, na.rm=TRUE),0))



product_data <- product_data %>% inner_join(prod_weekly_demand, by="PRODUCT")




df_processed <- df_processed %>% 
  mutate_(y = Y) %>% 
  select(ds, y, log_price
         , RAIN
         , SNOW, PRODUCT, SHOP, NAME, ROTATION_CLASS
         , IS_HOLIDAY 
         ,NEARBYCAR
         ,DIRECT_COMPETITOR
         ,INDIRECT_COMPETITOR
         ,STORE_SATURATION
         ,CLUSTER
  )

