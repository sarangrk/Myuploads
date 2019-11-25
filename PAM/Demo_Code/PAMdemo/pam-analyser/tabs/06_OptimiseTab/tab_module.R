#' UI
#' @export
optimiseTabUI <- function(id) {
  
  ns <- NS(id)
  
  tabPanel(
    optimise_tab(),
    fluidPage(
      fluidRow(
        column(12,
               h2("Maintenance optimisation"),
               p("This page allows you to examine the benefits of using an algorithm to predict asset failures and decide on when to intervene and send maintenance teams to repair your assets."),
               p('Fill in your planned maintenance and unplanned failure costs, choose a time period that you\'re interested in and click the "Run optimisation" button. This will find the optimal time to replace assets using the predicted failure probability; if the failure probabilty of an asset is larger than the alarm threshold it is recommended to send a maintenance team to the asset.'),
               p('After running the optimisation, the two yellow boxes just below this text compare key metrics of predictive asset maintenance and your company\'s previous maintenance methodology; the savings are highlighted in bold.')
        )
      ),
      br(),
      fluidRow(
        sidebarPanel(
          selectInput(ns("modelSelect"), label="Machine learning model", choices=initial_models),
          numericInput(ns("RepairCost"), label="Planned maintenance cost", value=500),
          numericInput(ns("UPFailureCost"), label="Unplanned failure cost", value=default_cost_unplanned_failure()),
          sliderInput(ns("TimeHorizonInput"), label="Failure time frame (days)", value=45, max=365, min=0),
          actionButton(ns('optimise_model'), 'Run optimisation')
        ),
        mainPanel(
          conditionalPanel(sprintf("input['%s'] != 0", ns("optimise_model")),
                           fluidRow(
                             column(6,
                                    tags$div(class='bs-callout bs-callout-warning',
                                             h4('Standard maintenance'),
                                             uiOutput(ns("nominal_stats"))
                                    )
                             ),
                             column(6,
                                    tags$div(class='bs-callout bs-callout-warning',
                                             h4('Predictive maintenance'),
                                             uiOutput(ns("model_stats"))
                                    )
                             )
                           ),
                           fluidRow(
                             column(12,
                                    sliderInput(ns("AlarmThreshold"), label="Alarm threshold (failure probability)", value=0.25, max=1, min=0)
                             )
                           ),
                           fluidRow(
                             column(6,
                                    plotlyOutput(ns("savingsFCPlot"))
                             ),
                             column(6,
                                    plotlyOutput(ns("savingsPerRepairPlot"))
                             )
                           ),
                           fluidRow(
                             column(6,
                                    plotlyOutput(ns("failuresFCPlot"))
                             ),
                             column(6,
                                    plotlyOutput(ns("repairsFCPlot"))
                             )
                           )
          )
        )
      )
    )
  )
}



#' Server script
#' @export
optimiseTab <- function(input, output, session, navpage){
  scale_factor <- reactive({
    length(unique(global_dataset$processed$full$asset_id))/length(unique(global_dataset$processed$validate$asset_id))
  })
  
  
  #### Reactives for calculating the risk threshold and benefits ####
  extractROCData <- reactive({
    time <- as.numeric(model_variables()$TimeHorizonInput)
    rocr_data <- calculate_validation_forecast() # Recalculate ROC data when time or model changed
    rocr_data$labels <- ifelse(rocr_data[,"event_occurred"] == 0, 0, ifelse(rocr_data[,"survival_time"]>=time, 0, 1))
    
    # rocr_data <- rocr_data[!((rocr_data$event_occurred == 0) && (rocr_data$survival_time < time)),]
    rocr_data$failure_probability <- 1 - rocr_data$predict # 1 - probability_of_survival = probability_failure
    return(rocr_data)
  })
  observe({
    if(!globalDataReady()) {
      message("optimise tab parent navpage: ", navpage())
      global_data_load_message(navpage()) #
      return()
    }
    
    page_bool <- navpage() == optimise_tab()
    message("page_bool: ", page_bool)
    message("navpage: ", navpage())
    
    if(!validationForecastReady() || !page_bool) return()
    
    rocr_data <- calculate_roc_stats()
    if (is.null(rocr_data)) return()
    
    best_treshold <- max(rocr_data[rocr_data$savings_per_repair == max(rocr_data$savings_per_repair), ]$threshold)
    
    updateNumericInput(session, 'AlarmThreshold', value = best_treshold)
  })
  
  observe({
    updateSelectInput(session, 'modelSelect', choices = models_to_build$list)
  })
  
  # Process RoC Data - Looping over time - from max to min
  calculate_roc_stats <- reactive({
    # Set-up output and get ROC data
    output <- list()
    rocr_data <- extractROCData()
    
    time <- as.numeric(model_variables()$TimeHorizonInput)
    
    nominal_repairs <- sum((rocr_data$event_type == 'repair') & (rocr_data$survival_time <= time)) * scale_factor()
    nominal_unplanned_failures <- sum((rocr_data$event_occurred == 1) & (rocr_data$survival_time <= time) & (rocr_data$planned == FALSE)) * scale_factor()
    nominal_cost <- (nominal_unplanned_failures * model_variables()$UPFailureCost) + (nominal_repairs * model_variables()$RepairCost)
    
    rocr_data <- rocr_data[!((rocr_data$event_occurred == 0) && (rocr_data$survival_time < time)),]
    
    # Loop over threshold
    for(threshold in seq(0, 1, by=0.01)){
      rocr_data$failures <- ifelse(rocr_data$failure_probability >= as.numeric(threshold), 1, 0)
      
      # calculate the amount of savings
      confusion_matrix <- table(Pred=rocr_data$failures, Truth=rocr_data$labels)
      # print(confusion_matrix)
      #    Truth
      # Pred   0   1
      #    0  70   0
      #    1 100  31
      
      # Cutoff so only predict one outcome
      if(dim(confusion_matrix)[1] == 1) {
        # No predictions of failures
        if(row.names(confusion_matrix)[1] == "0"){
          unexpected_failures <- round(confusion_matrix[1, 2] * scale_factor()) # All failures missed
          num_repairs <- round((0*scale_factor()) + nominal_repairs)
          
          cost <- unexpected_failures * model_variables()$UPFailureCost + num_repairs * model_variables()$RepairCost
        } else { # Only predict failures
          unexpected_failures <- 0 # Miss no failures
          num_repairs <- round((confusion_matrix[1, 1] + confusion_matrix[1, 2]) * scale_factor() + nominal_repairs)
          
          cost <- unexpected_failures * model_variables()$UPFailureCost + num_repairs * model_variables()$RepairCost
        }
      } else {
        unexpected_failures <- round((confusion_matrix[1, 2]) * scale_factor())
        num_repairs <- round((confusion_matrix[2,1] + confusion_matrix[2,2]) * scale_factor() + nominal_repairs)
        
        cost <- unexpected_failures * model_variables()$UPFailureCost + num_repairs * model_variables()$RepairCost
      }
      
      # Update output
      output$threshold <- c(output$threshold, threshold)
      output$cost <- c(output$cost, cost)
      output$num_failures <- c(output$num_failures, unexpected_failures)
      output$num_repairs <- c(output$num_repairs, num_repairs)
      output$nominal_cost <- c(output$nominal_cost, nominal_cost)
      output$nominal_repairs <- c(output$nominal_repairs, nominal_repairs)
      output$nominal_unplanned_failures <- c(output$nominal_unplanned_failures, nominal_unplanned_failures)
      
    }
    output$savings <- output$nominal_cost - output$cost
    output$savings_per_repair <- output$savings / output$num_repairs
    return(as.data.frame(output))
  })
  
  
  #### Update Validation Forecast on change of
  calculate_validation_forecast <- reactive({
    selected_model <- model_variables()$modelSelect
    forecast_time <- as.numeric(model_variables()$TimeHorizonInput)
    valid_suffix <- validationSuffix(selected_model)
    
    # Make predictions on validation set
    withProgress(message="Forecasting...", value=0, {
      # Get model to forecast
      model_to_forecast <- fitted_model(selected_model)
      
      # Validate CoxPH linear fit
      probs <- predictSurvProb(model_to_forecast, newdata = global_dataset$processed$validate, times=forecast_time)
      incProgress(1, detail="Forecasting... Complete")
    })
    
    # Make sure that NAs are set to 0
    probs <- ifelse(is.na(probs), 0, probs)
    
    # Update names and bind to forecast
    colnames(probs) <- "predict"
    
    # Bind together along with survival time and event occurrence
    new_forecast <- cbind(global_dataset$processed$validate, probs)
    
    return(new_forecast)
  })
  
  format_money <- function(number) {
    number <- format(number, big.mark = ',', scientific = FALSE)
    paste0('€', number)
  }
  
  blank_ggplot <- function() {
    df <- data.frame()
    return(ggplotly(ggplot(df) + geom_blank()))
  }
  
  plotly_config <- function(plot){
    config(
      p = plot,
      staticPlot = FALSE,
      displayModeBar = FALSE,
      workspace = FALSE,
      editable = FALSE,
      displaylogo = FALSE
    )
  }
  
  #### Plots ####
  output$savingsFCPlot <- renderPlotly({
    if(!globalDataReady()) return(blank_ggplot())
    
    # Reload output on tab reload
    page_bool <- navpage() == optimise_tab()
    if(validationForecastReady() && page_bool) {
      roc_stats <- calculate_roc_stats()
      if (is.null(roc_stats)) return(blank_ggplot())
      
      ## Plot Savings Forecast
      return(
        plot_ly(roc_stats, x = ~threshold, y = ~savings, type = 'scatter', mode = 'lines', name='Savings') %>%
          add_trace(x = c(input$AlarmThreshold, input$AlarmThreshold), y=c(min(roc_stats$savings), max(roc_stats$savings)), mode = "lines", line = list(dash = 'dash'), name='Alarm threshold') %>%
          layout(yaxis = list(title = "Savings", tickprefix ='€'), xaxis = list(title = "Failure probability"), legend = list(xanchor = 'right', bgcolor='transparent')) %>%
          plotly_config())
    } else {
      return(NULL)
    }
  })
  
  output$savingsPerRepairPlot <- renderPlotly({
    if(!globalDataReady()) return(blank_ggplot())
    
    # Reload output on tab reload
    page_bool <- navpage() == optimise_tab()
    if(validationForecastReady() && page_bool) {
      roc_stats <- calculate_roc_stats()
      if (is.null(roc_stats)) return(blank_ggplot())
      
      ## Plot Savings Forecast
      return(
        plot_ly(roc_stats, x = ~threshold, y = ~savings_per_repair, type = 'scatter', mode = 'lines', name='Savings per repair') %>%
          add_trace(x = c(input$AlarmThreshold, input$AlarmThreshold), y=c(min(roc_stats$savings_per_repair), max(roc_stats$savings_per_repair)), mode = "lines", line = list(dash = 'dash'), name='Alarm threshold') %>%
          layout(yaxis = list(title = "Savings per repair", tickprefix ='€'), xaxis = list(title = "Failure probability"), legend = list(xanchor = 'right', bgcolor='transparent')) %>%
          plotly_config()
      )
    } else {
      return(NULL)
    }
  })
  
  output$failuresFCPlot <- renderPlotly({
    if(!globalDataReady()) return(blank_ggplot())
    
    # Reload output on tab reload
    page_bool <- navpage() == optimise_tab()
    if(validationForecastReady() && page_bool) {
      roc_stats <- calculate_roc_stats()
      if (is.null(roc_stats)) return(blank_ggplot())
      
      ## Plot number forecasted failures ##
      return(
        plot_ly(roc_stats, x = ~threshold, y = ~num_failures, type = 'scatter', mode = 'lines', name='Number of unplanned failures') %>%
          add_trace(x = c(input$AlarmThreshold, input$AlarmThreshold), y=c(min(roc_stats$num_failures), max(roc_stats$num_failures)), mode = "lines", line = list(dash = 'dash'), name='Alarm threshold') %>%
          layout(yaxis = list(title = "Number of unplanned failures"), xaxis = list(title = "Failure probability"), legend = list(xanchor = 'right', bgcolor='transparent')) %>%
          plotly_config()
      )
    } else {
      return(NULL)
    }
  })
  
  output$repairsFCPlot <- renderPlotly({
    if(!globalDataReady()) return(blank_ggplot())
    
    # Reload output on tab reload
    page_bool <- navpage() == optimise_tab()
    if(validationForecastReady() && page_bool) {
      roc_stats <- calculate_roc_stats()
      if (is.null(roc_stats)) return(blank_ggplot())
      
      ## Plot number forecasted repairs
      return(
        plot_ly(roc_stats, x = ~threshold, y = ~num_repairs, type = 'scatter', mode = 'lines', name='Number of repairs') %>%
          add_trace(x = c(input$AlarmThreshold, input$AlarmThreshold), y=c(min(roc_stats$num_repairs), max(roc_stats$num_repairs)), mode = "lines", line = list(dash = 'dash'), name='Alarm threshold') %>%
          layout(yaxis = list(title = "Number of repairs"), xaxis = list(title = "Failure probability"), legend = list(xanchor = 'right',bgcolor='transparent')) %>%
          plotly_config()
      )
    } else {
      return(blank_ggplot())
    }
  })
  
  output$model_stats <- renderUI({
    if(!globalDataReady()) return()
    
    roc_data <- calculate_roc_stats()
    if (is.null(roc_data)) return()
    
    epsilon = 0.0001
    roc_data <- roc_data[((input$AlarmThreshold - epsilon) < roc_data$threshold) & (roc_data$threshold < (input$AlarmThreshold + epsilon)), ]
    return(tags$ul(
      tags$li(paste0('Cost: €', format(roc_data$cost, big.mark=","))),
      tags$li(paste0('Assets: ', length(unique(global_dataset$processed$full$asset_id)))),
      tags$li(paste0('Repairs: ', roc_data$num_repairs)),
      tags$li(paste0('Unplanned failures: ', roc_data$num_failures)),
      tags$li(tags$strong(paste0('Savings: €', format(roc_data$savings, big.mark=","))))
    ))
  })
  
  output$nominal_stats <- renderUI({
    if(!globalDataReady()) return()
    
    roc_data <- calculate_roc_stats()
    if (is.null(roc_data)) return()
    
    epsilon = 0.0001
    roc_data <- roc_data[((input$AlarmThreshold - epsilon) < roc_data$threshold) & (roc_data$threshold < (input$AlarmThreshold + epsilon)), ]
    return(tags$ul(
      tags$li(paste0('Cost: €', format(roc_data$nominal_cost, big.mark=","))),
      tags$li(paste0('Assets: ', length(unique(global_dataset$processed$full$asset_id)))),
      tags$li(paste0('Repairs: ', roc_data$nominal_repairs)),
      tags$li(paste0('Unplanned failures: ', roc_data$nominal_unplanned_failures)),
      tags$li('Existing maintenance')
    ))
  })
  
  model_variables <- eventReactive(input$optimise_model, {
    list(
      modelSelect = input$modelSelect,
      RepairCost = input$RepairCost,
      UPFailureCost = input$UPFailureCost,
      TimeHorizonInput = input$TimeHorizonInput
    )
  })
  
  ## Warning Message If Models not ready ##
  # output$Warning <- renderText({
  #   page_bool <- navpage == optimise_tab()
  #   if(!validationForecastReady() && page_bool)
  #     return("UPLOAD DATA TO PERFORM ANALYSIS")
  # })
}


