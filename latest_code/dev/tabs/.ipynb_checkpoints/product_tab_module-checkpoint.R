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
product_tab_server <- function(input, output, session) {
  
  ns <- session$ns
  
  
  filtered_data <- reactive({
    
    filtered <- reactive_list$workflow@data@training_set %>% 
      filter(SHOP == input$store) %>% 
      filter(PRODUCT == input$product)
    
    return(filtered)
  })
  
  
  output$validate <- renderUI({
    if (!is.null(reactive_list$workflow@model_factory@models)) {
      actionButton(ns('validate_model'), 'Estimate elasticities')
    } else {
      'Train models before estimating elasticities'
    }
  })


  
  output$products <- DT::renderDataTable({
    if(reactive_list$validated){
      datatable(reactive_list$products %>% 
                  select(NAME, ROTATION_CLASS, mean_week_demand, COST, PRICE, PRICE_ELASTICITY, est_elasticity, perc_error_mean_elasticity),
                colnames=c('Product Name'=1, 'Rotation Class' = 2, 'Avg. Week Demand'=3, 'Cost per unit' = 4, 
                           'Base Price' = 5, 'Price elasticity' = 6, 'Estimated elasticity' = 7, 
                           'Elasticity percentage difference (%)' = 8),
                extensions = c('Buttons'),
                options=list(dom='Bt', ordering=FALSE, pageLength = nrow(reactive_list$products),
                             buttons = c('copy', 'csv','pdf','print'),
                             columnDefs = list(list(className = 'dt-center', targets ="_all"))),
                rownames=FALSE) %>% 
        formatCurrency(c(4,5),currency="$", digits=2) %>%
        formatPercentage(c(8), digits=2)
    } else {
      datatable(reactive_list$products%>% 
                  select(NAME, ROTATION_CLASS, mean_week_demand, COST, PRICE, PRICE_ELASTICITY),
                colnames=c('Product Name'=1, 'Rotation Class' = 2, 'Avg. Week Demand'=3, 'Cost per unit' = 4, 
                           'Base Price' = 5, 'Price elasticity' = 6),
                extensions = c('Buttons'),
                options=list(dom='Bt', ordering=FALSE, pageLength = nrow(reactive_list$products),
                             buttons = c('copy', 'csv','pdf','print'),
                             columnDefs = list(list(className = 'dt-center', targets ="_all"))),
                rownames=FALSE) %>%
        formatCurrency(c(4,5),currency="$", digits=2)
    }
  })
  
  observeEvent(input$validate_model, 
               {
	       print(reactive_list$products)
               withProgress({
	       reactive_list$workflow <- reactive_list$workflow %>%
                   elasticities_prophet_model_factory(elasticities_df = reactive_list$products,
                                                      group_vars = c('PRODUCT', 'SHOP'),
                                                      joining_vars = 'PRODUCT',
                                                      cores = num_cores)
						      })

                 reactive_list$products <- inner_join(reactive_list$products,
                                                     reactive_list$workflow@validation$elasticities %>% 
                                                       select(PRODUCT, est_elasticity, PE_elasticity) %>% 
                                                       group_by(PRODUCT) %>% 
                                                       summarise(est_elasticity = round(mean(est_elasticity), 2),
                                                                 mean_elasticity_perc_error = round(mean(abs(PE_elasticity)), 2)),
                                                     by = c('PRODUCT')) %>%
                   mutate(perc_error_mean_elasticity = abs((est_elasticity-PRICE_ELASTICITY)/PRICE_ELASTICITY))
		   print(reactive_list$products)
                 reactive_list$validated <- TRUE
               })

} 

