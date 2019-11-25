# Train Model

##### UI #####
product_tab_ui <- function(id) {
  
  ns <- NS(id)
  
  fluidPage(
    fluidRow(
      box(width=12,
          title = 'Product Information',
          DT::dataTableOutput(ns('products'))
      )
    ),
    fluidRow(
      box(width=4, align="center",
          uiOutput(ns('validate'))
      )
    )
  ) # end of fluidPage
}




##### SERVER #####
product_tab_server <- function(input, output, session 
                               # , train_model_running 
) {
  
  
  ns <- session$ns
  
  
  filtered_data <- reactive({
    
    filtered <- reactive_list$workflow@data@training_set %>% 
      filter(SHOP == input$store) %>% 
      filter(PRODUCT == input$product)
    
    return(filtered)
  })
  
  
  
  
  output$validate <- renderUI({
    # if (!train_model_running())
    if (!is.null(reactive_list$workflow@model_factory@models)) 
    {
      actionButton(ns('validate_model'), 'Estimate elasticities')
    } else {
      'Train models before estimating elasticities'
    }
  })
  
  
  
  
  output$products <- DT::renderDataTable({
    if(reactive_list$validated){
      datatable(reactive_list$products %>% 
                  select(NAME, 
                         # ROTATION_CLASS,
                         
                         mean_week_demand, COST, PRICE, est_cluster_elasticity, est_shop_elasticity),
                colnames=c('Product Name'=1,
                           #'Rotation Class' = 2, 
                           'Avg. Week Demand'=2, 'Cost per unit' = 3, 
                           'Base Price' = 4, 'Average cluster elasticity' = 5, 'Average shop elasticity' = 6),
                extensions = c('Buttons'),
                options=list(dom='Bt', ordering=FALSE, pageLength = nrow(reactive_list$products),
                             buttons = c('copy', 'csv','pdf','print'),
                             columnDefs = list(list(className = 'dt-center', targets ="_all"))),
                rownames=FALSE) %>% 
        formatCurrency(c(3,4),currency="$", digits=2) %>%
        formatRound(c(5,6), digits=10)
    } else {
      datatable(reactive_list$products%>% 
                  select(NAME, 
                         # ROTATION_CLASS, 
                         mean_week_demand, COST, PRICE, PRICE_ELASTICITY),
                colnames=c('Product Name'=1, 
                           # 'Rotation Class' = 2, 
                           'Avg. Week Demand'=2, 'Cost per unit' = 3, 
                           'Base Price' = 4, 'Price elasticity' = 5),
                extensions = c('Buttons'),
                options=list(dom='Bt', ordering=FALSE, pageLength = nrow(reactive_list$products),
                             buttons = c('copy', 'csv','pdf','print'),
                             columnDefs = list(list(className = 'dt-center', targets ="_all"))),
                rownames=FALSE) %>%
        formatCurrency(c(3,4),currency="$", digits=2) %>%
        formatRound(c(5), digits=2)
    }
  })
  
  
  observeEvent(input$validate_model, 
               {
                 
                 force(reactive_cluster_list$cluster_workflow@validation$example_beta)
                 for (curmodel_name in names(reactive_cluster_list$cluster_workflow@model_factory@models)) {
                   if (invalid(reactive_cluster_list$cluster_workflow@model_factory@models[[curmodel_name]])) {
                     reactive_cluster_list$cluster_workflow@model_factory@models[[curmodel_name]] <- list()
                     reactive_cluster_list$cluster_workflow@model_factory@models[[curmodel_name]]$params$beta <- reactive_cluster_list$cluster_workflow@validation$example_beta
                     reactive_cluster_list$cluster_workflow@model_factory@models[[curmodel_name]]$y.scale <- 0
                   }
                   force(reactive_cluster_list$cluster_workflow@model_factory@models[[curmodel_name]])
                   force(reactive_cluster_list$cluster_workflow@model_factory@models[[curmodel_name]]$params$beta)
                   force(reactive_cluster_list$cluster_workflow@model_factory@models[[curmodel_name]]$y.scale)
                 }
                 force(reactive_cluster_list$products)
                 force(reactive_cluster_list$cluster_workflow@model_factory@models)
                 force(reactive_cluster_list$cluster_workflow)
                 force(reactive_cluster_list$cluster_workflow@data@training_set)
                 force(reactive_cluster_list$cluster_workflow@data@training_set$y)
                 force(reactive_cluster_list$cluster_workflow@validation$elasticities)
                 print("Estimating cluster PE")
                 tmpwf2 <- isolate(reactive_cluster_list$cluster_workflow)
                 tmpprod2 <- isolate(reactive_cluster_list$products)
                 withProgress({
                   reactive_cluster_list$cluster_workflow <- tmpwf2 %>%
                     elasticities_prophet_model_factory(elasticities_df = tmpprod2,
                                                        group_vars = c('PRODUCT', 'CLUSTER'),
                                                        joining_vars = 'PRODUCT',
                                                        cores = num_cores)
                 })
                 reactive_cluster_list$cluster_products <- inner_join(reactive_cluster_list$products,
                                                                      reactive_cluster_list$cluster_workflow@validation$elasticities %>%
                                                                        filter(!invalid(est_elasticity) & !is.nan(est_elasticity)) %>%
                                                                        select(PRODUCT, est_elasticity, PE_elasticity) %>% 
                                                                        group_by(PRODUCT) %>% 
                                                                        summarise(est_cluster_elasticity = round(mean(est_elasticity), 20),
                                                                                  mean_cluster_elasticity_perc_error = round(mean(abs(PE_elasticity)), 2)),
                                                                      by = c('PRODUCT')) %>%
                   mutate(perc_error_mean_cluster_elasticity = abs((est_cluster_elasticity-PRICE_ELASTICITY)/PRICE_ELASTICITY)) %>%
                   mutate(CLUSTER_PRICE_ELASTICITY = est_cluster_elasticity)
                 print(reactive_cluster_list$cluster_products)
                 
                 
                 force(reactive_list$workflow@validation$example_beta)
                 for (curmodel_name in names(reactive_list$workflow@model_factory@models)) {
                   if (invalid(reactive_list$workflow@model_factory@models[[curmodel_name]])) {
                     reactive_list$workflow@model_factory@models[[curmodel_name]] <- list()
                     reactive_list$workflow@model_factory@models[[curmodel_name]]$params$beta <- reactive_list$workflow@validation$example_beta
                     reactive_list$workflow@model_factory@models[[curmodel_name]]$y.scale <- 0
                   }
                   force(reactive_list$workflow@model_factory@models[[curmodel_name]])
                   force(reactive_list$workflow@model_factory@models[[curmodel_name]]$params$beta)
                   force(reactive_list$workflow@model_factory@models[[curmodel_name]]$y.scale)		   
                 }
                 force(reactive_list$products)
                 force(reactive_list$workflow@model_factory@models)
                 force(reactive_list$workflow)
                 force(reactive_list$workflow@data@training_set)
                 force(reactive_list$workflow@data@training_set$y)
                 force(reactive_list$workflow@validation$elasticities)
                 
                 print("Estimating shop PE")
                 tmpwf <- isolate(reactive_list$workflow)
                 tmpprod <- isolate(reactive_list$products)
                 withProgress({
                   reactive_list$workflow <- tmpwf %>%
                     elasticities_prophet_model_factory(elasticities_df = tmpprod,
                                                        group_vars = c('PRODUCT', 'SHOP'),
                                                        joining_vars = 'PRODUCT',
                                                        cores = num_cores)
                 })
                 print(reactive_list$workflow@validation$elasticities[1,1])
                 print(reactive_list$workflow@validation)
                 reactive_list$shop_products <- inner_join(reactive_list$products,
                                                           reactive_list$workflow@validation$elasticities %>%
                                                             filter(!invalid(est_elasticity) & !is.nan(est_elasticity)) %>%
                                                             select(PRODUCT, est_elasticity, PE_elasticity) %>% 
                                                             group_by(PRODUCT) %>% 
                                                             summarise(est_shop_elasticity = round(mean(est_elasticity), 20),
                                                                       mean_shop_elasticity_perc_error = round(mean(abs(PE_elasticity)), 2)),
                                                           by = c('PRODUCT')) %>%
                   mutate(perc_error_mean_shop_elasticity = abs((est_shop_elasticity-PRICE_ELASTICITY)/PRICE_ELASTICITY)) %>%
                   mutate(SHOP_PRICE_ELASTICITY = est_shop_elasticity)
                 
                 
                 reactive_list$products <- inner_join(reactive_list$shop_products,
                                                      reactive_cluster_list$cluster_products %>%
                                                        select(PRODUCT, est_cluster_elasticity, mean_cluster_elasticity_perc_error, perc_error_mean_cluster_elasticity),
                                                      by = c('PRODUCT')) %>%
                   mutate(PRICE_ELASTICITY = est_cluster_elasticity) %>%
                   mutate(est_elasticity = est_cluster_elasticity) %>%
                   mutate(mean_elasticity_perc_error = mean_cluster_elasticity_perc_error) %>%
                   mutate(perc_error_mean_elasticity = abs((est_elasticity-PRICE_ELASTICITY)/PRICE_ELASTICITY))
                 
                 reactive_list$validated <- TRUE
                 
                 reactive_cluster_list$validated <- TRUE
                 #shinyjs::disable("validate_model")
                 
                 #removeUI(
                 # selector = "div:has(> #validate_model)"
                 #    )
                 
               })
  
  
} 

