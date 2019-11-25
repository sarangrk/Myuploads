# Train Model
 
##### UI #####
PE_tab_ui <- function(id) {
 
  ns <- NS(id)
 
  fluidPage(
    fluidRow(
      box(width=12,
          title = ' Store Overview',
          DT::dataTableOutput(ns('overview'))
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
PE_tab_server <- function(input, output, session) {
 
    output$overview <- DT::renderDataTable({
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
              colnames=c('Store Address'=1, 'City'=2, 'State'=3, 'Contact Details'=4),
              extensions = c('Buttons'),
              options=list(dom='Bt', ordering=FALSE,
                           buttons = c('pdf','print')
                           ,
                           columnDefs = list(list(className = 'dt-center', targets ="_all"))),
             rownames=FALSE)
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
    prod_selected  <- prod_choices[1]
   
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
   
#####################################################
    
    
    
#####################################################
    
    
filtered_data_new <- reactive({
   
    filtered_new <- Price_Store_Wise_Data  %>%
                    filter(storeNum1 == input$store) %>%
                      filter(PRODUCT == product_num())  %>%
                      select ('count_of_ReceiptID' , 'AvgLineItemTotal')

    return(filtered_new)
  })
    
    
  output$salesdata <- renderPlotly({
    req(input$store, product_num())
    m <- list(
      r = 40,
      t = 30
    )
      Set_values <- filtered_data_new()
     
                       # m <- loess(filtered_data_new()$AvgLineItemTotal ~ filtered_data_new()$count_of_ReceiptID, data = filtered_data_new())

                            p <- filtered_data_new() %>% 
                              plot_ly( x = ~filtered_data_new()$count_of_ReceiptID, color = I("orange")) %>%
                              add_markers(y = ~filtered_data_new()$AvgLineItemTotal, text = rownames(filtered_data_new()), showlegend = FALSE) %>%
                           #   add_lines(x = ~filtered_data_new()$count_of_ReceiptID, y = fitted(qfit1)) %>%
                            # add_trace(x=~filtered_data_new()$count_of_ReceiptID, y=~filtered_data_new()$AvgLineItemTotal) %>%
      
                              add_lines(y = ~fitted(loess(filtered_data_new()$AvgLineItemTotal ~ filtered_data_new()$count_of_ReceiptID)),
                                        line = list(color = 'rgba(7, 164, 181, 1)'),
                                        name = "Loess Smoother") %>%
                              layout(xaxis = list(title = 'count_of_ReceiptID'),
                                     yaxis = list(title = 'Avg LineItemTotal'))
                        
                    
    p$elementId <- NULL
    p
  })
 
  # save values to pass to other tabs
#  savevals <- reactiveValues()
 
#  return(savevals)
} # end: tab_1_server()
 