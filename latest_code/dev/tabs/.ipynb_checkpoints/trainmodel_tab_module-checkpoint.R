# Train Model

##### UI #####
trainmodel_tab_ui <- function(id) {
  
  ns <- NS(id)
  
  fluidPage(
    fluidRow(
      box(width=12,
          title = 'Overview',
          column(
              width=4,
           DT::dataTableOutput(ns('overview'))
             ), 
          br(),
         column( width=8,
          DT::dataTableOutput(ns('Datils_overview'))
             )
              
    )),
      
    fluidRow(
      box(width=3, align="center",
               actionButton(ns('train'), 'Train Model')
      )
      ),
    fluidRow(
      box(width=12,align='center', title = 'Inspect Data',
          column(
          column(uiOutput(ns('store')), width=2),
          column(uiOutput(ns('product_name')), width=4),
          br(),
          plotlyOutput(ns("salesdata")),
          width=12)
      )
    )
  ) # end of fluidPage
}




##### SERVER #####
trainmodel_tab_server <- function(input, output, session) {

  output$overview <- DT::renderDataTable({
    stores_num <- length(unique(reactive_list$workflow@data@training_set$SHOP)) 
    product_num <- length(unique(reactive_list$workflow@data@training_set$PRODUCT))
    timeperiod <- length(unique(reactive_list$workflow@data@training_set$ds))
    timeyears <- round(timeperiod/365,1)
    datatable(data.frame(Stores = stores_num, 
                         Products = product_num,  
                         `Time period` = timeperiod,
                         years = timeyears, 
                         stringsAsFactors = FALSE),
              colnames=c('Stores'=1, 'Products'=2, 'Time period [days]'=3, 'Time period [years]'=4),
              extensions = c('Buttons'),
              options=list(dom='Bt', ordering=FALSE,
                           buttons = c('copy', 'csv','pdf','print'),
                           columnDefs = list(list(className = 'dt-center', targets ="_all"))),
              rownames=FALSE)
  })
    
    output$Datils_overview <- DT::renderDataTable({
      store_selected = input$store
     # print(store_selected)
      #print(Store_Date)
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
              colnames=c('Store Address'=1, 'City'=2, 'State'=3,       '  Contact Details    [Mail id ]    '=4),
              extensions = c('Buttons'),
              options=list(dom='Bt', ordering=FALSE,
                           buttons = c('pdf','print'),
                           
                           columnDefs = list(list(className = 'dt-center', targets ="_all"))),
             rownames=FALSE)
  })
  
  observeEvent(input$train, 
               {
                 num_models <- nrow(unique(reactive_list$workflow@data@training_set[c("PRODUCT","SHOP")]))
                 
                 withProgress({
                   reactive_list$workflow <- reactive_list$workflow %>% 
                     train_model(workflow, formula = '',
                                 training_engine = model_function,
                                 print_model = FALSE,
                                 convert_to_dummy = FALSE,
                                 child = FALSE,
                                 cores = num_cores)
                   reactive_list$trained_models <- names(reactive_list$workflow@model_factory@models)
                 }, 
                 min = 0.5, 
                 message = sprintf('Running %d models on %d processor cores.', num_models, num_cores))
               })
    print("printing model_function")
    #print(reactive_list$workflow )
    
    
   output$store <- renderUI({
    ns <- session$ns
    
    store_choices <- sort(unique(reactive_list$workflow@data@training_set$SHOP))
    store_selected <- store_choices[1]
    
    selectInput(ns('store'), 'Select a Store',
                choices = store_choices, selected = store_selected)
  })
  output$product_name <- renderUI({
    ns <- session$ns
    
    prod_choices <- unique(reactive_list$products$NAME)
    prod_selected <- prod_choices[1]
    
    selectInput(ns('product_name'), 'Select a Product',
                choices = prod_choices, selected = prod_selected)
  })
  
  product_num <- reactive({
    (reactive_list$products %>% filter(NAME == input$product_name))$PRODUCT[1]
  })
  
  filtered_data <- reactive({
    
    filtered <- reactive_list$workflow@data@training_set %>% 
      filter(SHOP == input$store) %>% 
      filter(PRODUCT == product_num())
    
    return(filtered)
  })
  
  output$salesdata <- renderPlotly({
    req(input$store, product_num())
    m <- list(
      r = 70,
      t = 50
    )
    
    
    p <- filtered_data() %>%
      plot_ly(x = ~ds) %>%
      add_trace(y = ~exp(log_price), type='bar', name = 'price', opacity=0.2) %>%
      add_trace(y = ~exp(y)-1, type='scatter', name = 'demand',mode = 'markers', yaxis='y2') %>%
      layout(legend = list(orientation = 'h', xanchor = 'center', x = 0.5, y = -0.4)) %>%
      layout(yaxis2 = list(title = "Demand", side = "left", 
                           range = c(0, max(exp(filtered_data()$y) + 1) * 1.2),
                           overlaying = "y"), 
             yaxis=list(title='Price', side='right', range = c(0, max(exp(filtered_data()$log_price))*1.2)) ,
             margin=m) #%>% 
      #scale_x_date(date_breaks = '1 month')
    p$elementId <- NULL
    p
  })

  # save values to pass to other tabs
#  savevals <- reactiveValues()

#  return(savevals)
} # end: tab_1_server()

