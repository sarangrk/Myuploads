#' Score the model based on the test or validation set based on the data in the MMWorkflow class object
#'
#' @export
#'
#' @param workflow an object of class MMWorkflow
#' @param score_set character - test_set or validation_set
#' @param print_scores logical flag to print the confusion matrix
#' @param prediction_fun a function to produce predictions. Must include arguments for object and newdata or newx
#' @param scoring_fun function to score the predictions
#' @param preprocess_fun optional function to convert obs and pred data to the correct format in the scoring function
#' @param features character vector of features or NULL to select feature names from metadata
#' @param predictions_item_name name of the list item the predictions are assigned to. Allows for multiple sets of predictions
#' @param scores_item_name name of the list item the scores are assigned to. Allows for multiple sets of predictions
#' @param convert_to_dummy logical should the predictor dataset be converted to a model.matrix. Important for glmnet models
#' @param cores number of processor cores to run in model factory mode
#' @param \dots unused
#'
#'
#'
#' scores are assigned to either the test or validation slots in the scores slot
#'
#' @importFrom caret predict.train confusionMatrix
#' @importFrom methods slot is new slot<-
score_model <- function(workflow, score_set, print_scores,
                        prediction_fun, scoring_fun, preprocess_fun,
                        features,
                        predictions_item_name,
                        scores_item_name,
                        convert_to_dummy, cores,  ...) UseMethod("score_model")

#' @export
score_model.ModelWorkflow <- function(workflow, score_set = c('test_set', 'validation_set', 'training_set'),
                                      print_scores = TRUE,
                                      prediction_fun = NULL,
                                      scoring_fun = NULL,
                                      preprocess_fun = NULL,
                                      features = NULL,
                                      predictions_item_name = 'predictions',
                                      scores_item_name = 'scores',
                                      convert_to_dummy = FALSE,
                                      cores = 1, ...){
  score_set <- match.arg(score_set)
  if(is.null(workflow@metadata$feature_engineering)){
    feature_eng <- NULL
    feature_eng_dat <- NULL
  } else if(workflow@metadata$feature_engineering$type == 'gam'){
    feature_eng <- workflow@metadata$feature_engineering$type
    feature_eng_dat <- workflow@features$univariate_gam
  }
  if(is.null(workflow@metadata$model_factory)){

    if(is(workflow@model@model_object, 'train')){
      if(is.null(features)){
        features <- get_features(workflow)
      }
      new_X <- slot(workflow@data, score_set)[, features]

      predictions <- caret::predict.train(workflow@model@model_object,
                                          newdata = new_X,
                                          testY = slot(workflow@data,
                                                       score_set)[[workflow@metadata$Data$TargetVariable$Name]],
                                          type = 'prob')
      predictions$raw <- caret::predict.train(workflow@model@model_object,
                                              newdata = new_X,
                                              testY = slot(workflow@data,
                                                           score_set)[[workflow@metadata$Data$TargetVariable$Name]],
                                              type = 'raw')
      # predictions$test_data <- factor(slot(workflow@data,
      #                                      score_set)[[workflow@metadata$Data$TargetVariable$Name]])
      slot(workflow@scores, paste(score_set, 'predictions', sep = '_'))[[predictions_item_name]] <- predictions

      if(!is.null(scoring_fun)){
        scores <- scoring_fun(slot(workflow@data,
                                   score_set)[[workflow@metadata$Data$TargetVariable$Name]],
                              predictions,
                              preprocess_fun)
        #confusion_matrix <- caret::confusionMatrix(predictions$raw, predictions$test_data)
        slot(workflow@scores, paste(score_set, 'predictions', sep = '_'))[[scores_item_name]] <- scores

      }
      if(print_scores && !is.null(scoring_fun)) {
        print(scores)
      }
      return(workflow)
      # return(update_metadata(workflow, ModelTests = list(TestName = 'Accuracy',
      #                                                    TestDate = as.character(Sys.Date()),
      #                                                    TestScore = confusion_matrix$overall['Accuracy'],
      #                                                    AllTests = confusion_matrix$overall)))

    } else {
      assertthat::assert_that(!is.null(prediction_fun), msg = 'You must supply a prediction function')
      predictions <- predict_single_group(model = workflow@model@model_object,
                                          dat = slot(workflow@data,
                                                     score_set),
                                          features = get_features(workflow),
                                          target = workflow@metadata$Data$TargetVariable$Name,
                                          prediction_fun = prediction_fun,
                                          feature_engineering = feature_eng,
                                          feature_engineering_dat = feature_eng_dat,
                                          dummy = convert_to_dummy, ...)
      slot(workflow@scores, paste(score_set, 'predictions', sep = '_'))[[predictions_item_name]] <- predictions

      if(!is.null(scoring_fun)){
        scores <- scoring_fun(slot(workflow@data,
                                   score_set)[[workflow@metadata$Data$TargetVariable$Name]],
                              predictions,
                              preprocess_fun)
        slot(workflow@scores, paste(score_set, 'predictions', sep = '_'))[[scores_item_name]] <- scores

      }
      return(workflow)
    }
  } else {

    assertthat::assert_that(!is.null(prediction_fun), msg = 'You must supply a prediction function')
    if(is.null(features)){
      features <- get_features(workflow)
    }
    predictions <- predict_factory(models = workflow@model_factory@models,
                                   dat = slot(workflow@data, score_set),
                                   grouping_variables = workflow@metadata$model_factory$grouping_variables,
                                   features = features,
                                   target = workflow@metadata$Data$TargetVariable$Name,
                                   prediction_fun = prediction_fun,
                                   feature_engineering = feature_eng,
                                   feature_engineering_dat = feature_eng_dat,
                                   dummy = convert_to_dummy,
                                   cores = cores, ...)

     # combined_predictions <- bind_score_factory(predictions,
     #                                            dat = slot(workflow@data,
     #                                                       score_set),
     #                                            grouping_variables = workflow@metadata$model_factory$grouping_variables,
     #                                            target = workflow@metadata$Data$TargetVariable$Name,
     #                                            cores = cores)

    slot(workflow@scores, paste(score_set, 'predictions', sep = '_'))[[predictions_item_name]] <- predictions

    if(!is.null(scoring_fun)){
      scores <- scoring_fun(dplyr::select(combined_predictions, obs),
                            dplyr::select(combined_predictions, -obs),
                            preprocess_fun)
      slot(workflow@scores, paste(score_set, 'predictions', sep = '_'))[[scores_item_name]] <- scores
    }

    return(workflow)
  }
}



#' Calculate a series of metrics for model evaluation.
#'
#' @export
#'
#' @param observed a vector of observed values
#' @param predicted a vector of predicted values
#' @param metrics a character vector of metric names, metric functions named here need to be previously defined
#'
#' @import Metrics
calc_metrics <- function(observed, predicted, metrics=c('mape', 'rsquared', 'mase', 'rmse', 'mae')){
  all_metrics <- sapply(metrics, do.call, list(observed, predicted))
  return(all_metrics)
}

#' Calculate metrics for data across grouping variables.
#'
#' @export
#'
#' @param predicted list of predictions with names of models
#' @param dat test set data
#' @param grouping_variables character vector of grouping variables
#' @param target character name of target
#' @param predicted_var character name of prediction column in prediction data
#' @param metric_fun function for evaluation metric calculation
#' @param cores number of processor cores to run the function in
#'
metrics_factory <- function(predicted, dat, grouping_variables, target, predicted_var, metric_fun, cores=1){
  ## Grid of group combinations for factory
  grouping_grid <- expand.grid(lapply(grouping_variables,
                                      function(x) unique(as.character(dat[[x]]))),
                               stringsAsFactors = FALSE)
  names(grouping_grid) <- grouping_variables
  message('Running on ', cores, ' cores')
  ## Filter dataset to subgroup
  subgroup_metrics <- parallel::mclapply(1:nrow(grouping_grid), function(group){
    filter_string <- paste(vapply(grouping_variables,
                                  function(v) paste0(v, '== "', as.character(grouping_grid[group, v]), '"'),
                                  character(1)),
                           collapse = ' & ')
    model_name <- paste(grouping_grid[group,], collapse='__')
    message(filter_string)
    message(model_name)
    predicted_dat <- predicted[[model_name]] %>% as.data.frame() %>% pull(predicted_var)
    observed_dat <- filter_(dat, filter_string) %>% pull(target)
    # if(is.list(observed_dat)){
    #   observed_dat <- as.numeric(observed_dat[[1]])
    # }
    # if(is.list(predicted_dat)){
    #   predicted_dat <- as.numeric(predicted_dat[[1]])
    # }
    if(is.null(predicted_dat)){
      message('No predictions available for subgroup!')
      return(list(NULL))
    }
    preds <- tryCatch(metric_fun(observed_dat, predicted_dat),
                      error = function(e){
                        message('Scoring failed for subgroup ', paste(grouping_grid[group, ], collapse = '__'))
                        list(e)
                      })

  }, mc.cores = cores)
  names(subgroup_metrics) <- vapply(1:nrow(grouping_grid),
                                    function(x) paste(grouping_grid[x, ], collapse = '__'), character(1))

  return(subgroup_metrics)
}

#' Definition of rsquared error measure
#'
#' @export
#'
#' @param observed a vector of observed values
#' @param predicted a vector of predicted values
#'
rsquared <- function(observed, predicted){
  rss <- sum((predicted - observed) ^ 2)
  tss <- sum((observed - mean(observed)) ^ 2)
  rsq <- 1 - rss/tss
  return(rsq)
}





#' Generic prediction function
#'
#' @export
#'
#' @param model a model object
#' @param dat data frame for generating X for predictions
#' @param features character vector of feature names
#' @param target character name of target
#' @param prediction_fun function for predicting
#' @param feature_engineering engineering NULL or character
#' @param feature_engineering_dat data set for feature engineering models
#' @param dummy logical convert X to model.matrix
#' @param ts_model logical use syntax for forecasting package models
#' @param \dots passed to prediction_fn
predict_single_group <- function(model, dat, features, target, prediction_fun,
                                 feature_engineering, feature_engineering_dat, dummy, ts_model=FALSE, ...){
  dots <- list(...)
  target <- dat[[target]]
  if(is.null(feature_engineering)){
    new_X <- dat[, features]
  } else if(feature_engineering == 'gam'){
    assertthat::assert_that(!is.null(feature_engineering_dat), msg = 'You must supply a feature engineering dataset')
    new_X <- generate_new_features_gam(dat, features, feature_engineering_dat)
  } else if(feature_engineering == 'ts'){
    new_X <- length(target)
  }
  else {
    stop('Feature engineering type "', feature_engineering, '" not yet implemented!')
  }
  if(dummy){
    new_X <- to_dummy(new_X)
  }

  if(!ts_model){
    preds <- prediction_fun(model, new_X, ...)
    if(!is.null(target)){
      preds$y_target <- target
    }
    preds
  } else{
    if(!is.null(dots[['fourier_K']])){
      train_ts <- ts(train_y, start = 1, frequency = frequency)
      prediction_fun(model, xreg = cbind(dots[['feat']], fourier(train_ts, K=dots[['fourier_K']], h = length(target))))
    } else{
      prediction_fun(model, h = length(target), ...)
    }
  }
}


# predict_single_group(wf_glmer@model_factory@models$A,
#                      dat = wf_glmer@data@test_set %>% filter(CATEGORY == 'A'),
#                      features = get_features(wf_glmer),
#                      target = 'SALES',
#                      prediction_fun = predict,
#                      dummy = FALSE,
#                      feature_engineering = wf_glmer@features$univariate_gam,
#                      feature_engineering_dat = wf_glmer@features$univariate_gam,
#                      type = 'response')




#' Generic prediction factory function
#'
#' @export
#'
#' @param models a list of model objects
#' @param dat data frame for generating X for predictions
#' @param grouping_variables character vector of variable names
#' @param features character vector of feature names
#' @param target character
#' @param prediction_fun function for predicting
#' @param feature_engineering engineering NULL or character
#' @param feature_engineering_dat data set for feature engineering models
#' @param dummy logical convert X to model.matrix
#' @param cores number of processor cores
#' @param ts_model logical use syntax for forecasting package models
#' @param \dots passed to prediction_fn
#'
predict_factory <- function(models, dat, grouping_variables, features, target,
                          prediction_fun,
                          feature_engineering,
                          feature_engineering_dat,
                          dummy, cores = .MMoptions$cores, ts_model=FALSE, ...){
  dots <- list(...)
  ## Grid of group combinations for factory
  grouping_grid <- expand.grid(lapply(grouping_variables,
                                      function(x) unique(as.character(dat[[x]]))),
                               stringsAsFactors = FALSE)
  names(grouping_grid) <- grouping_variables
  message('Running on ', cores, ' cores')
  ## Filter dataset to subgroup
  subgroup_predictions <- parallel::mclapply(1:nrow(grouping_grid), function(group){
    filter_string <- paste(vapply(grouping_variables,
                                  function(v) paste0(v, '== "', as.character(grouping_grid[group, v]), '"'),
                                  character(1)),
                           collapse = ' & ')
    message(filter_string)
    group_dat <- dplyr::filter_(dat, filter_string)
    if(!is.null(dots[['xreg']])){
      feat <- group_dat %>% dplyr::select_(dots[['xreg']])
    }else{
      feat <- NULL
    }
    if(!nrow(group_dat)){
      message('Empty dataset for subgroup!')
      return(list(NULL))
    }
    preds <- tryCatch(predict_single_group(model = models[[group]],
                                           dat = group_dat,
                                           features = features,
                                           target = target,
                                           prediction_fun = prediction_fun,
                                           feature_engineering = feature_engineering,
                                           feature_engineering_dat = feature_engineering_dat,
                                           dummy = dummy, ts_model = ts_model,
                                           feat = feat,
                                           ...),
                      error = function(e){
                        message('Prediction failed for subgroup ', paste(grouping_grid[group, ], collapse = '__'))
                        list(e)
                      })

  }, mc.cores = cores, mc.silent=FALSE)
  names(subgroup_predictions) <- vapply(1:nrow(grouping_grid),
                                   function(x) paste(grouping_grid[x, ], collapse = '__'), character(1))

  subgroup_predictions
}



#' flattens a list of predictions output from a model factory into a data frame
#'
#' @param predictions list of predictions
#' @param dat data.frame containing the grouping factors and the target variable
#' @param grouping_variables character vector of grouping_variables
#' @param target name of target variable
#' @param cores number of processor cores
#'
#' @return data.frame of bound predictions
#'
#' @export
#'
#' @importFrom magrittr %>%
#' @importFrom dplyr bind_rows transmute bind_cols
bind_score_factory <- function(predictions, dat, grouping_variables, target,
                               cores = .MMoptions$cores){
  grouping_grid <- expand.grid(lapply(grouping_variables,
                                      function(x) unique(as.character(dat[[x]]))),
                               stringsAsFactors = FALSE)
  names(grouping_grid) <- grouping_variables
  message('Running on ', cores, ' cores')
  ## Filter dataset to subgroup
  dplyr::bind_rows(parallel::mclapply(1:nrow(grouping_grid), function(group){
    filter_string <- paste(vapply(grouping_variables,
                                  function(v) paste0(v, '== "', as.character(grouping_grid[group, v]), '"'),
                                  character(1)),
                           collapse = ' & ')
    message(filter_string)
    group_preds <- predictions[[group]]
    if(is(group_preds, 'list') && (is.null(group_preds[[1]]) || 'error' %in% class(group_preds[[1]]))){
      group_preds <- NULL
    } else {
      group_preds <- as.data.frame(group_preds)
    }
    group_dat <- dat %>%
      dplyr::filter_(filter_string)

    if(!nrow(group_dat)){
      message('Empty dataset for subgroup')
      return(NULL)
    }

    group_dat <- group_dat %>%
      dplyr::transmute_(obs = target) %>%
      dplyr::bind_cols(group_preds)

  }, mc.cores = cores))

}

#' Very basic scoring function.
#'
#' implements defaultSummary from caret package
#'
#' @param obs vector of observed values
#' @param predictions matrix of predicted values
#' @param preprocess_fun optional preprocessing function to coerce obs and predictions into a single data frame
#'
#' Different predict methods produce different outputs. You can deal with this by defining a
#' custom preprocess_fun function
#'
#' @export
#'
#' @return list
score_defaultSummary <- function(obs, predictions, preprocess_fun = NULL){
  if(!is.null(preprocess_fun)){
    pred_dat <- preprocess_fun(obs, predictions)
  } else {
    pred_dat <- data.frame(obs = obs,
                           pred = predictions$raw)
  }
  list(n = length(pred_dat$obs),
       n_missing = sum(is.na(pred_dat[[1]])),
       scores = caret::defaultSummary(pred_dat))
}



#' Run predictions based on the data in the MMWorkflow class object, return a dataframe of predictions
#'
#' @export
#'
#' @param workflow an object of class MMWorkflow
#' @param score_set data.frame to predict from
#' @param prediction_fun a function to produce predictions. Must include arguments for object and newdata or newx
#' @param preprocess_fun optional function to convert obs and pred data to the correct format in the scoring function
#' @param features character vector of features or NULL to select feature names from metadata
#' @param convert_to_dummy logical should the predictor dataset be converted to a model.matrix. Important for glmnet models
#' @param cores number of processor cores to run in model factory mode
#' @param \dots unused
#'
#' @return a data.frame of predictions
#'
#'
#' @export
#'
#' @importFrom caret predict.train confusionMatrix
#' @importFrom methods is
#'
live_predict <- function(workflow, score_set,
                         prediction_fun = NULL,
                         preprocess_fun = NULL,
                         features = NULL,
                         convert_to_dummy = FALSE,
                         cores = 1, ...){
  feature_eng <- NULL  # depecated feature engineering functions
  feature_eng_dat <- NULL
  if(is.null(workflow@metadata$model_factory)){

    if(is(workflow@model@model_object, 'train')){
      if(is.null(features)){
        features <- get_features(workflow)
      }
      new_X <- score_set[, features]

      predictions <- caret::predict.train(workflow@model@model_object,
                                          newdata = new_X,
                                          testY = score_set[[workflow@metadata$Data$TargetVariable$Name]],
                                          type = 'prob')
      predictions$raw <- caret::predict.train(workflow@model@model_object,
                                              newdata = new_X,
                                              testY = score_set[[workflow@metadata$Data$TargetVariable$Name]],
                                              type = 'raw')

      return(predictions)

    } else {
      assertthat::assert_that(!is.null(prediction_fun), msg = 'You must supply a prediction function')
      predictions <- predict_single_group(model = workflow@model@model_object,
                                          dat = score_set,
                                          features = get_features(workflow),
                                          target = workflow@metadata$Data$TargetVariable$Name,
                                          prediction_fun = prediction_fun,
                                          feature_engineering = feature_eng,
                                          feature_engineering_dat = feature_eng_dat,
                                          dummy = convert_to_dummy, ...)
      return(predictions)
    }
  } else {

    assertthat::assert_that(!is.null(prediction_fun), msg = 'You must supply a prediction function')
    if(is.null(features)){
      features <- get_features(workflow)
    }
    predictions <- predict_factory(models = workflow@model_factory@models,
                                   dat = score_set,
                                   grouping_variables = workflow@metadata$model_factory$grouping_variables,
                                   features = features,
                                   target = workflow@metadata$Data$TargetVariable$Name,
                                   prediction_fun = prediction_fun,
                                   feature_engineering = feature_eng,
                                   feature_engineering_dat = feature_eng_dat,
                                   dummy = convert_to_dummy, cores = cores, ...)

    return(bind_rows(predictions))
  }
}





