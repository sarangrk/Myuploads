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
    ),
    
    fluidRow(
      box(width=12,align='center', title = 'Inspect Data by Cluster',
          column(
            column(uiOutput(ns('Cluster')), width=2),
            column(uiOutput(ns('product_name_cl')), width=4),
            br(),
            plotlyOutput(ns("ByCluster")),
            width=12)
      )
    ),
    
    
    fluidRow(
      box(width=12,
          align='left', title = 'Store Cluster ',
          column(
            plotlyOutput(ns("StoreCluster")),
            width=12)
      )
    )
    
    
  ) # end of fluidPage
}




##### SERVER #####
trainmodel_tab_server <- function(input, output, session) {
  #reactive_Train_running <- reactiveVal( TRUE)   ### to disable button 
  
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
                 
                 #reactive_Train_running(TRUE)
                 
                 num_cluster_models <- nrow(unique(reactive_cluster_list$cluster_workflow@data@training_set[c("PRODUCT","CLUSTER")]))
                 print(num_cluster_models)
                 print("I am here 124")
                 print(reactive_cluster_list$cluster_workflow)
                 withProgress({
                   reactive_cluster_list$cluster_workflow <- reactive_cluster_list$cluster_workflow %>% 
                     train_model(cluster_workflow
                                 ,formula = ''
                                 ,training_engine = model_function
                                 ,print_model = FALSE
                                 ,convert_to_dummy = FALSE
                                 ,child = FALSE
                                 ,cores = num_cores)
                   reactive_cluster_list$trained_cluster_models <- names(reactive_cluster_list$cluster_workflow@model_factory@models)
                 }, 
                 min = 0.5, 
                 message = sprintf('Running %d models on %d processor cores.', num_cluster_models, num_cores))
                 print('Line number 140')
                 validmodelcount <- 0
                 invalidmodelcount <- 0
                 for (curmodel_name in names(reactive_cluster_list$cluster_workflow@model_factory@models)) {
                   curmodel = reactive_cluster_list$cluster_workflow@model_factory@models[[curmodel_name]]
                   if (!invalid(curmodel) && curmodel$n.changepoints > 0) {
                     validmodelcount <- validmodelcount + 1
                     print(curmodel$params$beta)
                     reactive_cluster_list$cluster_workflow@validation$example_beta <- curmodel$params$beta
                   }
                   else {
                     invalidmodelcount <- invalidmodelcount + 1
                     print(paste("Invalid model", curmodel_name, "found."))
                     print(curmodel)
                   }
                 }
                 print(paste("Trained", validmodelcount, "models successfully."))
                 print(paste("Failed to train", invalidmodelcount, "models."))
                 
                 
                 num_models <- nrow(unique(reactive_list$workflow@data@training_set[c("PRODUCT","SHOP")]))
                 
                 
                 withProgress({
                   reactive_list$workflow <- reactive_list$workflow %>% 
                     train_model(workflow
                                 , formula = ''
                                 ,training_engine = model_function
                                 ,print_model = FALSE
                                 ,convert_to_dummy = FALSE
                                 ,child = FALSE
                                 ,cores = num_cores)
                   reactive_list$trained_models <- names(reactive_list$workflow@model_factory@models)
                   
                 }, 
                 min = 0.5, 
                 message = sprintf('Running %d models on %d processor cores.', num_models, num_cores))
                 
                 validmodelcount <- 0
                 invalidmodelcount <- 0
                 for (curmodel_name in names(reactive_list$workflow@model_factory@models)) {
                   curmodel = reactive_list$workflow@model_factory@models[[curmodel_name]]
                   if (!invalid(curmodel) && curmodel$n.changepoints > 0) {
                     validmodelcount <- validmodelcount + 1
                     reactive_list$workflow@validation$example_beta <- curmodel$params$beta
                   }
                   else {
                     invalidmodelcount <- invalidmodelcount + 1
                     print(paste("Invalid model", curmodel_name, "found."))
                     print(curmodel)
                   }
                 }
                 print(paste("Trained", validmodelcount, "models successfully."))
                 print(paste("Failed to train", invalidmodelcount, "models."))
                 
                 
                 
               })
  
  
  
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
  
  
  ############################# kaptan  #####################################  
  
  output$Cluster <- renderUI({
    ns <- session$ns
    
    Cluster_choices <- sort(unique(reactive_cluster_list$cluster_workflow@data@training_set$CLUSTER))
    Cluster_selected <- Cluster_choices[1]
    
    selectInput(ns('Cluster'), 'Select a Cluster',
                choices = Cluster_choices, selected = Cluster_selected)
  })
  
  
  output$product_name_cl <- renderUI({
    ns <- session$ns
    
    prod_choices_cl <- unique(reactive_cluster_list$cluster_workflow@data@training_set$PRODUCT)
    prod_selected_cl <- prod_choices_cl[1]
    
    selectInput(ns('product_name_cl'), 'Select a Product for cluster',
                choices = prod_choices_cl, selected = prod_selected_cl)
  })
  
  
  
  product_name_cluster <- reactive({
    (reactive_cluster_list$products %>% filter(NAME == input$product_name_cl))$PRODUCT[1]
  })
  
  
  
  
  
  filtered_data_cl <- reactive({
    filtered_cl <- reactive_cluster_list$cluster_workflow@data@training_set %>% 
      filter(as.numeric(CLUSTER) == as.numeric(input$Cluster))  %>% 
      filter(PRODUCT == product_name_cluster() )
    return(filtered_cl)  
  })   
  
  
  
  output$ByCluster <- renderPlotly({
    req(input$Cluster, product_name_cluster())
    m <- list(
      r = 70,
      t = 50
    )
    
    
    q <- filtered_data_cl() %>%
      plot_ly(x = ~ds) %>%
      add_trace(y = ~exp(log_price), type='bar', name = 'price', opacity=0.2) %>%
      add_trace(y = ~exp(y)-1, type='scatter', name = 'demand',mode = 'markers', yaxis='y2') %>%
      layout(legend = list(orientation = 'h', xanchor = 'center', x = 0.5, y = -0.4)) %>%
      layout(yaxis2 = list(title = "Demand", side = "left", 
                           range = c(0, max(exp(filtered_data_cl()$y) + 1) * 1.2),
                           overlaying = "y"), 
             yaxis=list(title='Price', side='right', range = c(0, max(exp(filtered_data_cl()$log_price))*1.2)) ,
             margin=m) 
    q$elementId <- NULL
    q    
    
  })
  
  
  
  ###############################  END   ####################################################
  
  
  
  output$StoreCluster <- renderPlotly({
    
    store$q <- store$clustername
    levels(store$q) <- paste(c("Medium Volume, Conventional preferred", "High Volume, Synth preferred", "Low Volume", "Medium Volume, Synth preferred", "High Volume, Conventional preferred"), "Cluster")
    store$q <- as.ordered(store$q)
    store$storenum <- as.integer(store$storenum)
    g <- list(
      scope = 'usa',
      projection = list(type = 'albers usa'),
      showland = TRUE,
      landcolor = toRGB("gray85"),
      subunitwidth = 1,
      countrywidth = 1,
      subunitcolor = toRGB("white"),
      countrycolor = toRGB("white")
    )
    
    
    m <- plot_geo(store, locationmode = 'USA-states' , sizes = c(1, 150)
    ) %>%
      add_markers(
        x = ~Location_Longitude, y = ~Location_Latitude, size = ~storenum, color = ~q, hoverinfo = "text",
        # x = ~Location_Longitude, y = ~Location_Latitude, size = ~storenum, color = ~q, hoverinfo = "text",
        text = ~paste(store$storenum, "<br />", store$clustername , "clustername")
      ) %>%
      layout(title = 'Store Clustering <br>(Click legend to toggle)', geo = g, height= 500)
    
    m
  })
  
  
  
  
  # save values to pass to other tabs
  #  savevals <- reactiveValues()
  #return(reactive_Train_running)
  
  
  #  return(savevals)
} # end: tab_1_server()

