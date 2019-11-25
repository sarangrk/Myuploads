# Train Model

##### UI #####
forecast_tab_ui <- function(id) {
  
  ns <- NS(id)
  
  fluidPage(
    fluidRow(
      box(width=12, align='left', title = 'Forecast Evaluation',
          column(
            column(uiOutput(ns('store')), width=2),
            column(uiOutput(ns('product_name')), width=4),
            column(selectInput(ns('data_set'), 'Select data set to forecast', choices=c('Training', 'All'), selected = "All"), width=3),
            column(style = "margin-top: 25px;", uiOutput(ns('forecast')), width=2),
            width=12)
      )),
    fluidRow(
      box(width=12, align='left', title = 'Store Details',
          column( width=12,
                  DT::dataTableOutput(ns('Datils_overview'))
          )
      )),
    
    
    fluidRow(
      box(width=12, align='left', title = 'Forecast Plot',
          column(
            plotlyOutput(ns("forecastplot")),
            width=12)
      )
    ),
    fluidRow(
      box(width=12, align='left', title = 'Forecast Components',
          column(
            selectInput(ns('component'), 'Select Component', choices=c( 'weekly'
                                                                        , 'SNOW'
                                                                        , 'log_price'
                                                                        , 'RAIN'
                                                                        , 'IS_HOLIDAY'
                                                                        , 'NEARBYCAR'
                                                                        , 'DIRECT_COMPETITOR', 'INDIRECT_COMPETITOR','STORE_SATURATION' 
            )
            
            , selected = 'Day of Week', width=150),
            plotlyOutput(ns("componentplot")),
            width=12)
      )
    ),
    fluidRow(
      box(width=12, align='left', title = 'Performance',
          column(
            DT::dataTableOutput(ns("performancetable"), width = "300px"),
            br(), br(),
            selectInput(ns('metric'), 'Select a Metric', choices=c('MAPE (14 days)', 'MAPE (28 days)'), selected = 'MAPE (14 days)', width=150),
            plotlyOutput(ns("performanceplot")),
            width=12)
      )
    )
  ) # end of fluidPage
}




##### SERVER #####
forecast_tab_server <- function(input, output, session) {
  
  
  
  model_selection <- reactive({
    model_name <- paste0(product_num(),"__",input$store)
    return(model_name)
  })
  
  output$Datils_overview <- DT::renderDataTable({
    store_selected = input$store
    
    StoreAddress <- Store_Date[Store_Date$License_Number == store_selected , 'Location_Address']
    City <- Store_Date[Store_Date$License_Number == store_selected , 'Location_City']
    State <- Store_Date[Store_Date$License_Number == store_selected , 'Location_State']
    Contact_Deatils <- Store_Date[Store_Date$License_Number == store_selected , 'Center_Email2']
    
    
    Stores_Address <- StoreAddress
    City <- City
    State <- State
    Contact_Deatils <- Contact_Deatils
    datatable(data.frame(Stores = Stores_Address,
                         Products = City, 
                         `Time period` = State,
                         years = Contact_Deatils,
                         stringsAsFactors = FALSE),
              colnames=c('Store Address'=1, 'City'=2, 'State'=3, 'Contact Details  [Mail id ]  '  =4),
              extensions = c('Buttons'),
              options=list(dom='Bt', ordering=FALSE,
                           buttons = c('pdf','print'),
                           
                           columnDefs = list(list(className = 'dt-center', targets ="_all"))),
              rownames=FALSE)
  })
  
  observeEvent(input$forecast, 
               {
                 withProgress({
                   model_name <- model_selection()
                   
                   
                   
                   
                   mod <- reactive_list$workflow@model_factory@models[[model_name]]
                   
                   #print("here is the mod ")
                   #print(mod)
                   
                   
                   filter_factors <- unlist(strsplit(model_name, "__"))
                   
                   
                   grouping_variables <- reactive_list$workflow@metadata$model_factory$grouping_variables
                   
                   
                   filter_string <- paste(
                     paste0(grouping_variables, '=="', filter_factors, '"'),
                     collapse = ' & ')
                   
                   
                   df <- c()
                   if(input$data_set %in% c("Training", "All")) df <- rbind(df, reactive_list$workflow@data@training_set %>% filter_(filter_string) %>% mutate(`Data set` = "Training sample"))
                   
                   
                   #if(input$data_set %in% c("Training", "All")) df <- rbind(df, reactive_list$workflow@data@training_set %>% mutate(`Data set` = "Training sample"))
                   
                   if(input$data_set %in% c("Test", "All")) df <- rbind(df, reactive_list$workflow@data@test_set %>% filter_(filter_string) %>% mutate(`Data set` = "Test sample"))
                   
                   
                   incProgress(0.05)
                   
                   forecasts <- predict(mod, df)   
                   print("Forecast run")
                   
                   # listnew <-((mod$component.modes$additive))
                   
                   incProgress(0.4)
                   
                   forecasts$actual_y <- df$y
                   forecasts$`Data set` <- df$`Data set`
                   
                   reactive_list$forecasts[[model_name]] <- forecasts   # getting use for performanceplot function 
                   reactive_list$plot_components[[model_name]] <- prophet_plot_components(mod, forecasts )
                   
                   feature_list <- list('weekly'
                                        , 'SNOW'
                                        , 'log_price'
                                        , 'RAIN'
                                        , 'IS_HOLIDAY'
                                        , 'NEARBYCAR'
                                        , 'DIRECT_COMPETITOR'
                                        , 'INDIRECT_COMPETITOR'
                                        ,'STORE_SATURATION'
                   ) 
                   
                   reactive_list$plot_components_new[[model_name]] = foreach(cur_feature = feature_list) %do%  plotly_build(plot_forecast_component(mod,forecasts,cur_feature))
                   names(reactive_list$plot_components_new[[model_name]]) <- feature_list
                   
                   print("End of forecast")
                   print(forecasts)
                   
                 },
                 min = 0,
                 message = 'Running forecast.')
               })
  
  
  
  output$store <- renderUI({
    ns <- session$ns
    model_names <- reactive_list$trained_models
    if(length(model_names) > 0){
      store_choices <- sort(unique(sapply(strsplit(model_names, "__"), function(v) v[2])))
      
      selectInput(ns('store'), 'Select a Store',
                  choices = store_choices, width="300px")
    } else{
      selectInput(ns('store'), 'Select a Store - train models first',
                  choices = c(), selected = c())
    }
    
  })
  
  output$product_name <- renderUI({
    ns <- session$ns
    
    
    model_names <- reactive_list$trained_models
    if(length(model_names) > 0){
      prod_choices <- unique(sapply(strsplit(model_names, "__"), function(v) v[1]))                                       
      
      
      prod_choices <- unique((reactive_list$products %>% filter(PRODUCT %in% prod_choices))$NAME)
      
      
      selectInput(ns('product_name'), 'Select a Product',
                  choices = prod_choices, width="500px")
    } else{
      selectInput(ns('product_name'), 'Select a Product - train models first',
                  choices = c(), selected = c())
    }
  } )
  
  product_num <- reactive({
    (reactive_list$products %>% filter(NAME == input$product_name))$PRODUCT[1]
  })
  
  output$forecast <- renderUI({
    ns <- session$ns
    
    if (!invalid(reactive_list$workflow@model_factory@models[[model_selection()]]) &&
        !invalid(reactive_list$workflow@model_factory@models[[model_selection()]]$n.changepoints) && 
        reactive_list$workflow@model_factory@models[[model_selection()]]$n.changepoints > 0)
    {
      actionButton(ns('forecast'), 'Forecast')
    } else {
      'Insufficient data for this store/product'
    }
  })
  
  
  output$forecastplot <- renderPlotly({
    req(input$store, product_num(), reactive_list$forecasts[[model_selection()]])
    m <- list(
      r = 70,
      t = 50
    )
    model_name <- model_selection()
    mod <- reactive_list$workflow@model_factory@models[[model_selection()]]
    forecasts <- reactive_list$forecasts[[model_selection()]]
    
    p <- forecasts %>% 
      ggplot2::ggplot(ggplot2::aes(x = ds)) +
      ggplot2::labs(x = 'Dates', y = Y) +
      ggplot2::geom_point(ggplot2::aes(y = actual_y, color = `Data set`), na.rm=TRUE) +
      ggplot2::geom_line(ggplot2::aes(y = yhat), na.rm = TRUE)
    
    if(all(c("yhat_lower", "yhat_upper") %in% names(forecasts))){
      p <- p + ggplot2::geom_ribbon(ggplot2::aes(ymin = yhat_lower, ymax = yhat_upper), alpha = 0.2, fill = "#0072B2", na.rm = TRUE) 
    }
    p
  })
  
  
  output$componentplot <- renderPlotly({
    req(input$store, product_num(), reactive_list$plot_components_new[[model_selection()]] , input$component)
    
    m <- list(
      r = 70,
      t = 50
    )
    p <- reactive_list$plot_components_new[[model_selection()]][[input$component]]
    p
  })                           
  
  
  
  
  
  
  output$performanceplot <- renderPlotly({
    req(input$store, product_num(), reactive_list$forecasts[[model_selection()]], input$metric)
    print("performanceplot")
    
    m <- list(
      r = 70,
      t = 50
    )
    
    perf_df <- reactive_list$forecasts[[model_selection()]] %>% 
      mutate(error = abs(actual_y-yhat),
             perc_error = ifelse(actual_y==0, NA, abs(error/actual_y)),
             se = (actual_y - yhat)^2
      )
    num_days <- ifelse(input$metric == "MAPE (14 days)", 14, 28)
    #print(input$metric )
    perf_df$perf_metric <- round(RcppRoll::roll_mean(perf_df$perc_error, num_days, align="right", fill=NA, na.rm = TRUE) *100, 2)
    p <- perf_df %>%
      plot_ly(x = ~ds, color = ~`Data set`) %>%
      add_trace(y = ~perf_metric, type='scatter', name = input$metric, mode = 'lines') %>%
      layout(
        yaxis=list(title=input$metric),
        legend = list(orientation = 'h', xanchor = 'center', x=0.5, y=1.1))
    p
  })
  
  output$performancetable <- DT::renderDataTable({
    req(reactive_list$forecasts[[model_selection()]])
    perf_df <- reactive_list$forecasts[[model_selection()]] %>% 
      mutate(error = abs(actual_y - yhat),
             perc_error = ifelse(actual_y ==0, 0, abs(error/actual_y)),
             se = (actual_y - yhat)^2
      ) %>% 
      group_by(`Data set`) %>%
      summarise(
        MAE = mean(error, na.rm=TRUE),
        MAPE = mean(perc_error, na.rm=TRUE),
        ymean = mean(actual_y),
        sse = sum(se),
        ssto = sum((actual_y-ymean)^2),
        R2 = 1 - sse/ssto
      ) %>% 
      select(`Data set`, MAPE) %>%
      datatable(., 
                colnames=c(' '=1, 'MAPE'=2),
                options=list(dom='t', ordering=FALSE,
                             columnDefs = list(list(className = 'dt-center', targets ="_all"))),
                rownames=FALSE) %>% 
      formatPercentage(c(2), digits=2)
    perf_df
  })
  
  
  
  # save values to pass to other tabs
  #  savevals <- reactiveValues()
  
  #  return(savevals)
} # end: tab_1_server()

