
modelUI <- function(id) {
  
  ns <- NS(id)
  
  tags$div(
    checkboxInput(ns('customise_models'), 'Customise machine learning models', value = FALSE, width = '100%'),
    conditionalPanel(sprintf("input['%s'] == true", ns("customise_models")),
                     wellPanel(
                       checkboxInput(ns('enable_model_linear'), 'Run cox survival model', value = TRUE),
                       checkboxInput(ns('enable_model_dt'), 'Run decision tree survival model', value = TRUE),
                       checkboxInput(ns('enable_model_rf'), 'Run random forrest survival model', value = TRUE)
                     )
    )
  )
}


featureUI <- function(id) {
  
  ns <- NS(id)
  
  tags$div(
    checkboxInput(ns('customise_features'), 'Customise features to use in the Machine Learning models', value = FALSE, width = '100%'),
    conditionalPanel(sprintf("input['%s'] == true", ns("customise_features")),
                     wellPanel(
                       checkboxGroupInput(ns('features_excluded'), 'Features to exclude (by default all are included in the models)', 
                                          list(`None`=''), selected = '')
                     )
    )
  )
}


# Insights Tab UI
#' @export
trainingTabUI <- function(id) {
  
  ns <- NS(id)
  
  tabPanel('Training',
           fluidPage(
             fluidRow(
               column(12,
                      h2('Training'),
                      p('This page allows you to customise the training of the machine learning models by allowing you to select which types of models to use and which feature to include in them.')
               )
             ),
             hr(),
             fluidRow(
               column(12,
                      h3('Features'),
                      p('Checking the below box allows you to choose which features to include in the model, this can be useful if you have to exclude certain infomation for regulatory or other business reasons.'),
                      featureUI(id)
                      
               )
             ),
             hr(),
             fluidRow(
               column(12,
                      h3('Machine Learning Models'),
                      p('If you check the below box you will be able to choose the machine learning techniques to include in the analysis.'),
                      modelUI(id)
               )
             ),
             br(),
             br(),
             fluidRow(
               column(12,
                      actionButton(ns("process_models"), "Train Machine Learning Models"),
                      br(),
                      br(),
                      p(textOutput(ns("model_processing_results")))
               )
             )
           )
  )
}


# Server
#' @export
trainingTab <- function(input, output, session, navpage) {
  ## Build models on button fire ##
  observeEvent(input$process_models, {
    # Check data sets are available
    if(!globalDataReady()) {
      global_data_load_message(navpage())
      return()
    } 
    
    # Reset forecasts
    reset_forecasts()
    attributes_to_exclude_user$list <- features_excluded
    
    # Build the models
    build_models()
    
  })
  
  get_models_to_build <- reactive({
    models_to_build$list <<- c()
    if(input$enable_model_linear)
      models_to_build$list <<- c(models_to_build$list, "Cox Regression"="Cox Regression")
    if(input$enable_model_dt)
      models_to_build$list <<- c(models_to_build$list, "Decision Tree"="Decision Tree")
    if(input$enable_model_rf)
      models_to_build$list <<- c(models_to_build$list, "Random Forest"="Random Forest")
    
    return(models_to_build$list)
  })
  
  reset_survival_object <- reactive({
    survival_models$linear <<- NULL
    survival_models$linear_complete <<- FALSE
    survival_models$rf <<- NULL
    survival_models$rf_complete <<- FALSE
    survival_models$dt <<- NULL
    survival_models$dt_complete <<- FALSE
  })
  
  reset_forecasts <- function(){
    validation_forecast[, "completed"] <<- FALSE
    validation_forecast[, grepl("Predict_", colnames(validation_forecast))] <<- NULL
    test_forecast[, "completed"] <<- FALSE
    test_forecast[, grepl("Predict_", colnames(validation_forecast))] <<- NULL
  }
  
  ## Get forecast times ##
  forecast_times <- reactive({
    max_time <- max(global_dataset$processed$train$survival_time)
    times_to_forecast <- c(30, 90, 180, 360)
    times_to_forecast[times_to_forecast >= max_time] <- max_time
    return(times_to_forecast)
  })
  
  
  build_models <- reactive({
    # Which models to build and update which attributes from training
    get_models_to_build()
    reset_survival_object()
    num_mods <- length(models_to_build)
    
    # Build models
    # NB: INCLUDE STRATA at a later data
    withProgress(message="Building Models And validating....", value = 0, {
      
      if("Cox Regression" %in% models_to_build$list) {
        build_linear_model_and_validate()
        incProgress(1/num_mods, detail="Building Linear Survival Model")
      }
      
      if("Decision Tree" %in% models_to_build$list) {
        build_dt_model_and_validate()
        incProgress(1/num_mods, detail="Building Survival Decision Tree")
      }
      
      if("Random Forest" %in% models_to_build$list) {
        build_rf_model_and_validate()
        incProgress(1/num_mods, detail="Building Survival Random Forest")
      }
      
    })
    
    validation_forecast[, "completed"] <<- TRUE
    test_forecast[, "completed"] <<- TRUE
  })
  
  build_linear_model_and_validate <- reactive({
    # Get model formula and
    attribs <- attributes_for_modelling(global_dataset$processed$train)
    mf <- get_model_formula(attribs)
    times <- forecast_times()
    survival_models$linear <<- coxph(mf, data=global_dataset$processed$train)
    
    # Validate CoxPH linear fit
    lin_probs <- predictSurvProb(survival_models$linear, newdata = global_dataset$processed$validate, times=times)
    lin_probs_test <- predictSurvProb(survival_models$linear, newdata = global_dataset$processed$test, times=times)
    lin_probs <- ifelse(is.na(lin_probs), 0, lin_probs)
    lin_probs_test <- ifelse(is.na(lin_probs_test), 0, lin_probs_test)
    colnames(lin_probs) <- paste("Predict_SL_", times, sep="")
    colnames(lin_probs_test) <- paste("Predict_SL_", times, sep="")
    
    # Bind together along with survival time and event occurrence
    validation_forecast <<- cbind(validation_forecast, lin_probs)
    test_forecast <<- cbind(test_forecast, lin_probs_test)
    
    
    # Linear set to complete
    survival_models$linear_complete <<- TRUE
    
  })
  
  build_rf_model_and_validate <- reactive({
    attribs <- attributes_for_modelling(global_dataset$processed$train)
    mf <- get_model_formula(attribs)
    times <- forecast_times()
    survival_models$rf <<- rfsrc(mf, data=global_dataset$processed$train, ntree=500, importance = TRUE)
    
    # Validate Random Forest
    rf_probs <- predictSurvProb(survival_models$rf, newdata = global_dataset$processed$validate, times=times)
    rf_probs_test <- predictSurvProb(survival_models$rf, newdata = global_dataset$processed$test, times=times)
    incProgress(1/3, detail="Validating Survival Random Forest")
    rf_probs <- ifelse(is.na(rf_probs), 0, rf_probs)
    rf_probs_test <- ifelse(is.na(rf_probs_test), 0, rf_probs_test)
    colnames(rf_probs) <- paste("Predict_SRF_", times, sep="")
    colnames(rf_probs_test) <- paste("Predict_SRF_", times, sep="")
    
    
    # Bind together along with survival time and event occurrence
    validation_forecast <<- cbind(validation_forecast, rf_probs)
    test_forecast <<- cbind(test_forecast, rf_probs_test)
    
    survival_models$rf_complete <<- TRUE
  })
  
  build_dt_model_and_validate <- reactive({
    attribs <- attributes_for_modelling(global_dataset$processed$train)
    mf <- get_model_formula(attribs)
    times <- forecast_times()
    survival_models$dt <<- pecRpart(mf, data=global_dataset$processed$train, maxdepth=5)
    
    # Validate Decision Tree
    dt_probs <- predictSurvProb(survival_models$dt, newdata = global_dataset$processed$validate, times=times)
    dt_probs_test <- predictSurvProb(survival_models$dt, newdata = global_dataset$processed$test, times=times)
    dt_probs <- ifelse(is.na(dt_probs), 0, dt_probs)
    dt_probs_test <- ifelse(is.na(dt_probs_test), 0, dt_probs_test)
    colnames(dt_probs) <- paste("Predict_ST_", times, sep="")
    colnames(dt_probs_test) <- paste("Predict_ST_", times, sep="")
    
    # Bind together along with survival time and event occurrence
    validation_forecast <<- cbind(validation_forecast, dt_probs)
    test_forecast <<- cbind(test_forecast, dt_probs_test)
    
    survival_models$dt_complete <<- TRUE
    
  })
  
  categorised_columns <- reactive({
    col_list <- attributes_for_modelling(global_dataset$processed$full, ignore.user = TRUE)
    categorised_column_names <- list()
    for (col in col_list) {
      found_in <- NULL
      for (dataset_name in c('asset_data', 'repair_data', 'replacement_data', 
                             'planned_data', 'asset_attribute_data_1', 'asset_attribute_data_2',
                             'asset_attribute_data_3', 'asset_attribute_data_4')) {
        if (is.null(found_in) && !is.null(global_dataset$raw[[dataset_name]])) {
          if (col %in% colnames(global_dataset$raw[[dataset_name]])) {
            found_in <- dataset_name
          }
        }
      }
      
      nice_ds_name <- 'Uncategorised'
      if (is.null(found_in)){
        print(paste0(col, ": not found in raw dataset"))
      } else {
        nice_ds_name <- global_dataset$raw_names[[found_in]]
      }
      
      if (!(nice_ds_name %in% names(categorised_column_names))) {
        categorised_column_names[[nice_ds_name]] <- list(col)
      } else {
        position <- length(categorised_column_names[[nice_ds_name]]) + 1
        categorised_column_names[[nice_ds_name]][[position]] <- col
      }
    }
    return(categorised_column_names)
  })
  
  observe({
    if (is.null(global_dataset$processed)) return()
    
    # modelling_attribs <- attributes_for_modelling(global_dataset$processed$validate, ignore.user = TRUE)
    # to_choose <- as.list(modelling_attribs)
    to_choose <- unlist(categorised_columns())
    names(to_choose) <- paste(gsub('\\d+$', '', names(to_choose)), to_choose, sep = ': ')
    updateCheckboxGroupInput(session, 'features_excluded', choices = to_choose)
  })
}


