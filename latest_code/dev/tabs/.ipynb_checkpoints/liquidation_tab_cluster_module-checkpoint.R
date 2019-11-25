##### LIQUIDATION TAB #####

##### UI #####
liquidation_tab_cluster_ui <- function(id) {
  
  ns <- NS(id)
  
  fluidPage(
    box(width=3,
        column(width=12, title='Cluster and Product selection',
               br(),
               uiOutput(ns('cluster')),
               br(),
               uiOutput(ns('product_name')),
               br(),
              # sliderInput(ns('target_sales'), 'Set the value of target sales', value = 200, min=0, max=1000),
               sliderInput(ns('discount'), 'Set a max discount %', value = 20, min=0, max=100),
               br(),
              # sliderInput(ns('minprice'), 'Set min price in % of production cost', value = 100, min=0, max=100),
               br(),
               sliderInput(ns('sim_time_units'), 'Number of days', value = 30 , min=1, max=60),
               br(),
               br(),
               #selectInput(ns('rain'), 'Will it be raining?', choices = c("Yes", "No"), selected="No"),
               #selectInput(ns('snow'), 'Will it be snowing?', choices = c("Yes", "No"), selected="No"),
               selectInput(ns('is_holiday'), 'Will it be holiday?', choices = c("Yes", "No"), selected="No"),
               br(),
               
               #selectInput(ns('nearbycar'), 'Do we have competior with in 5 mile ?', choices = c("Yes", "No"), selected="No"),
               #selectInput(ns('direct_competitor'), 'do we have direct competitor?', choices = c("Yes", "No"), selected="No"),
               #selectInput(ns('indirect_competitor'), 'do we have indirect competitor?', choices = c("Yes", "No"), selected="No"),
               #selectInput(ns('store_saturation'), 'do we need to consider store saturation?', choices = c("Yes", "No"), selected="No"),
               
               dateInput(ns('start_date'), 'Set the starting date', format="yyyy-mm-dd", weekstart=1),
               
               uiOutput(ns('optimise'))
               )
        ),
         box(width=9,
        column(width=12, 
          DT::dataTableOutput(ns("Datils_overview"))
        )
    ),
    br(),
      
    box(width=9,
        column(width=12, 
          DT::dataTableOutput(ns("product_desc"))
        )
    ),
     br(),
      
    box(width=9,
        column(width=12, 
               plotlyOutput(ns("optimplot"))
               )
        ),
      
      br(),
      br(),
      
    box(width=9,
        column(width=12, 
               DT::dataTableOutput(ns("optim_desc"))
        )
    )
  )
} # end: tab_2_ui()





##### SERVER #####

liquidation_tab_cluster_server <- function(input, output, session, createvals) {
    output$Datils_overview <- DT::renderDataTable({
      cluster_selected = input$store
       
      #print(Store_Date)
      ClusterName <- unique(store[store$cluster == cluster_selected, 'clustername'])
        
      datatable(data.frame(ClusterName = ClusterName,
                           stringsAsFactors = FALSE),
              colnames=c('Cluster Name'=1),
              extensions = c('Buttons'),
              options=list(dom='Bt', ordering=FALSE,
                           buttons = c('pdf','print'),
                           
                           columnDefs = list(list(className = 'dt-center', targets ="_all"))),
             rownames=FALSE)
  })
    

    
    
  output$cluster <- renderUI({
    ns <- session$ns
    model_names <- reactive_cluster_list$trained_cluster_models
    if(length(model_names) > 0){
      cluster_choices <- sort(unique(sapply(strsplit(model_names, "__"), function(v) v[2])))
      
      selectInput(ns('store'), 'Select a Cluster',
                  choices = cluster_choices)
    } else{
      selectInput(ns('store'), 'Select a Cluster - train models first',
                  choices = c(), selected = c())
    }                                        
  })
  
  output$product_name <- renderUI({
    ns <- session$ns
    model_names <- reactive_cluster_list$trained_cluster_models
    
    if(length(model_names) > 0){
      prod_choices <- unique(sapply(strsplit(model_names, "__"), function(v) v[1]))
      prod_choices <- unique((reactive_list$products %>% filter(PRODUCT %in% prod_choices))$NAME)
  
      selectInput(ns('product_name'), 'Select a Product',
                  choices = prod_choices)
    } else{
      selectInput(ns('product_name'), 'Select a Product - train models first',
                  choices = c(), selected = c())
    }
  })
  
  product_num <- reactive({
    (reactive_list$products %>% filter(NAME == input$product_name))$PRODUCT[1]
  })
                             

  
  model_selection <- reactive({
    model_name <- paste0(product_num(),"__",input$store)
    return(model_name)
  })
                            
                             
                             
                             
output$optimise <- renderUI({
    ns <- session$ns
     if (!invalid(reactive_cluster_list$cluster_workflow@model_factory@models[[model_selection()]]) &&
            !invalid(reactive_cluster_list$cluster_workflow@model_factory@models[[model_selection()]]$n.changepoints) && 
            reactive_cluster_list$cluster_workflow@model_factory@models[[model_selection()]]$n.changepoints > 0)
        {
          actionButton(ns('optimise'), 'Optimize')
        } else {
          'Insufficient data for this store/product'
        }
  })

                                                       
                             
                             
  prod_desc_df <- reactive({
    reactive_list$products %>% 
      filter(PRODUCT==product_num()) 
  })

#################### kaptan test ######################
                             
 competitor_df <- reactive({
    reactive_list$competitor %>% 
      filter(PRODUCT==product_num()) 
  })                          

                             
                             
###################### complete here ##################                             
  
    extra_regressors <- reactive({
    #snow_feature <- (0:1)[c("No","Yes")==input$snow]
    #rain_feature <- (0:1)[c("No","Yes")==input$rain]
    snow_feature <- (0:1)[c("No","Yes")=="No"]
    rain_feature <- (0:1)[c("No","Yes")=="No"]
    is_holiday_feature <- (0:1)[c("No","Yes")==input$is_holiday]
      
    nearbycar_feature <- (0:1)[c("No","Yes")== "Yes" ]
    direct_competitor_feature <- (0:1)[c("No","Yes")=="Yes"]
    indirect_competitor_feature <- (0:1)[c("No","Yes")=="Yes"]
    store_saturation_feature <- (0:1)[c("No","Yes")=="Yes"]
     
    data.frame(SNOW = rep(snow_feature, input$sim_time_units)
               , RAIN = rep(rain_feature, input$sim_time_units)
               ,IS_HOLIDAY = rep(is_holiday_feature, input$sim_time_units)
               
               ,NEARBYCAR = rep(nearbycar_feature, input$sim_time_units)
               ,DIRECT_COMPETITOR = rep(direct_competitor_feature, input$sim_time_units)
               ,INDIRECT_COMPETITOR = rep(indirect_competitor_feature, input$sim_time_units)
               ,STORE_SATURATION = rep(store_saturation_feature, input$sim_time_units)
               
              )
          
    })
   
                             
  observeEvent(input$optimise,
               {
                                   
                   
                   #if(input$target_sales <= 0){target_sales<- -1}else{target_sales<-input$target_sales}
                 
                 model_name <- model_selection()
              
                   
                # target_sales_lst <- list(target_sales)
                 #names(target_sales_lst) <- model_name
                 
                 base_cost <- prod_desc_df()[["COST"]][1]
                 base_price <- prod_desc_df()[["PRICE"]][1]
                
                 max_price <- competitor_df()[["maxPrice"]][1]
                 
                max_pre <- max(max_price/base_price,1)

                   
                 
                 reactive_cluster_list$cluster_workflow <- reactive_cluster_list$cluster_workflow %>% price_optimisation(list_models=model_name,
                                                                                         cores = 1,
                                                                                         optimisation_id = model_name,
                                                                                       #  target_sales_lst=target_sales_lst,
                                                                                         use_test_data = FALSE,
                                                                                         start_time = input$start_date,
                                                                                         sim_time_units = input$sim_time_units,
                                                                                         min_price_ratio = input$minprice/100,
                                                                                         #min_price_ratio = 0/1,           
                                                                                         max_price_ratio = max_pre,
                                                                                         base_cost = base_cost,
                                                                                         base_price = base_price,
                                                                                         extra_regressors=extra_regressors()
                                                                                         
                                                                            )
                 
                 if(is.null(reactive_cluster_list$optim_results)) {reactive_cluster_list$optim_results <- list()}
                 
                 reactive_cluster_list$optim_results[[model_name]] <- reactive_cluster_list$cluster_workflow@validation$price_optimisation[[model_name]][[model_name]]
                
                
               })
                             
                        
    output$optimplot <- renderPlotly({
    req(input$store, product_num(), reactive_cluster_list$optim_results[[model_selection()]])
        
    plotdata <- reactive_cluster_list$optim_results[[model_selection()]]
    if(is.data.frame(plotdata)){
      
      plotdata <- plotdata %>% 
        select(ds, optim_prices, actual_prices, units_sold_optim_price, units_sold_actual_price
               #, target_sales
              ) %>% 
        mutate(cumsum_units_sold_optim = cumsum(units_sold_optim_price),
               cumsum_units_sold_actual = cumsum(units_sold_actual_price),
              # units_left_optim = ifelse(target_sales > 0, target_sales - cumsum_units_sold_optim, NA),
               #units_left_actual = ifelse(target_sales > 0, target_sales - cumsum_units_sold_actual, NA),
               ds = as.Date(ds)
        )
      
      ay <- list(
        overlaying = "y",
        side = "left",
        title = "volume",
        rangemode = "tozero"
      )
      m <- list(
        r = 70,
        t = 50,
        b = 70
      )
      
      p <- plotdata %>%
        plot_ly(x = ~ds) %>%
        add_trace(y = ~optim_prices, type='bar', name = 'Suggested price', opacity=0.6) %>%
        add_trace(y = ~actual_prices, type='bar', name = 'Actual price', opacity=0.6) %>%
        add_trace(y = ~units_sold_optim_price, type='scatter', name = 'Units sold (optim price)',mode = 'lines', line=list(color="green", dash = 'Line'), yaxis='y2') %>%
        add_trace(y = ~units_sold_actual_price, type='scatter', name = 'Units sold (actual price)',mode = 'lines', line=list(color="grey", dash = 'dot'), yaxis='y2') %>%
        #add_trace(y = ~units_left_actual, type='scatter', name = 'Stock available (actual price)',mode = 'lines', line=list(color="grey"), yaxis='y2') %>%
        #add_trace(y = ~units_left_optim, type='scatter', name = 'Stock available (suggested price)', mode='lines', line=list(color="green"), yaxis='y2') %>%
        layout(legend = list(orientation = 'h', xanchor = 'center')) %>% #, x=0.5, y=1.1
        layout(yaxis=list(title='price', side='right', rangemode = "tozero"), yaxis2=ay,
               margin=m,
               xaxis=list(title=' ', #autotick=FALSE,
                          nticks = nrow(plotdata),
                          ticks = "outside",
                          tickvals = plotdata$ds,
                          ticktext = plotdata$ds))
      
      p
    }else{
      plot_ly()
   }
    
  })
  
  output$product_desc <- DT::renderDataTable({
    req(input$store, product_num(), reactive_list$products)
    prod_desc_df() %>%
      select(Product = PRODUCT, `Base Price`= PRICE, `Base Cost` = COST
             #, `Rotation class`=ROTATION_CLASS
             , `Price Elasticity`= PRICE_ELASTICITY) %>%
      datatable(.,
                options=list(dom='t', ordering=FALSE,
                             columnDefs = list(list(className = 'dt-center', targets ="_all"))),
                rownames=FALSE) %>% 
        formatCurrency(c(2,3), currency ="$", digits=2)
  })
  
  
  output$optim_desc <- DT::renderDataTable({
    req(input$store, product_num(), reactive_cluster_list$optim_results[[model_selection()]])
      

      
    optim_df <- reactive_cluster_list$optim_results[[model_selection()]]
     

      
    if(is.data.frame(optim_df)){
        
      
        
        
      optim_df <- optim_df %>% 
        summarise(margin_actual_price=sum(margin_actual_price),
                  margin_optim_price=sum(margin_optim_price),
                  revenue_actual_price=sum(revenue_actual_price),
                  revenue_optim_price=sum(revenue_optim_price),
                  target_sales=max(target_sales),
                  sum_weight_avg_optim_price = sum(units_sold_optim_price * optim_prices),
                  sum_weight_avg_actual_price = sum(units_sold_actual_price * actual_prices),
                  sum_units_sold_optim_price=sum(units_sold_optim_price),
                  sum_units_sold_actual_price=sum(units_sold_actual_price),
                  avg_cost = mean(base_cost)
                  ) %>%
        mutate(
          #benefit = value_optim_price - value_actual_price,
          #perc_benefit = benefit/value_actual_price,
          units_left_optim_price = target_sales-sum_units_sold_optim_price,
          units_left_actual_price = target_sales-sum_units_sold_actual_price,
          units_left_cost_optim_price = units_left_optim_price * avg_cost,
          units_left_cost_actual_price = units_left_actual_price * avg_cost,
          average_price_optim_price = sum_weight_avg_optim_price/sum_units_sold_optim_price,
          average_price_actual_price = sum_weight_avg_actual_price/sum_units_sold_actual_price
        ) 
      lkpis <- c("margin","revenue"  #,"units_left"  , "units_left_cost"
                 , "average_price")
       
        
        
      lkpis_res <- lapply(lkpis, function(kpi){
                            data.frame(Actual=ceiling(optim_df[[paste0(kpi,"_actual_price")]]), 
                                       Optimal=ceiling(optim_df[[paste0(kpi,"_optim_price")]]))
                          })
    
        
      names(lkpis_res)<-lkpis
       optim_df <- data.table::rbindlist(lkpis_res, idcol="kpi") %>%
        mutate(Benefit = Optimal - Actual) %>% 
        data.table::melt(id.vars="kpi", variable.name = "actualvsoptimal") %>%
        data.table::dcast(actualvsoptimal ~ kpi) %>% tibble::column_to_rownames('actualvsoptimal') %>%
        select(margin
               ,revenue
               #,units_left
               #,units_left_cost
               ,average_price ) %>%
        ##formatCurrency(c(2,3),currency ="$", digits=0) %>% 
        ##formatCurrency(c(4), currency ="$", digits=2) %>% 
        formatTableCell(rows = c(3), cols = c('margin'),
                        color_lowerbound = list(red=-Inf, grey=-5, green=5)) %>%
        datatable(., 
                  escape = FALSE,
                  colnames=c(' '=1, 
                             'Margin'=2, 
                             'Revenue'=3
                            # , 'Units Left'=4
                             #, 'Cost of Units Left'=5
                             , 'Average Price'=4),
                  options=list(dom='t', ordering=FALSE,
                               columnDefs = list(list(className = 'dt-center', targets ="_all"))),
                  rownames=TRUE) %>% 
        formatCurrency(c(2,3),currency ="$", digits=0) %>% 
        formatCurrency(c(4), currency ="$", digits=2) 
    }else{
      datatable()
    }
    
  })

} # end: tab_2_server()