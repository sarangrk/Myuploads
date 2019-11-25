#' @include class_model_workflow.R class_data.R helpers.R class_model.R class_scoring.R
#' class_data.R MMmetadata.R MMfeatures.R class_model.R class_scoring.R MMvalidation.R helpers.R
#' training.R
#' using S3 methods  - S4 too heavyhanded! #####
NULL





#' Define the variables used as features and target in the model
#'
#'Also defines grouping variables for model factory mode
#'
#' @export
#'
#' @param workflow an object of class ModelWorkflow
#' @param feature_names character vector
#' @param target_name character
#' @param grouping_variables character only used if model factory mode is set
#' @param fe_grouping_variables character vector used to define groups for feature engineering
#' @param \dots unused arguments
#'
#' @importFrom assertthat assert_that
#'
#' @return an object of class ModelWorkflow
#'
#' If the default '.' is supplied to `feature_names`, all variables except the target_name are used as features
#'
#'
define_features <- function(workflow, feature_names,
                            target_name, grouping_variables, fe_grouping_variables, ...) {
  UseMethod("define_features")
}

#' @export
define_features.ModelWorkflow <- function(workflow, feature_names = '.',
                                          target_name,
                                          grouping_variables = NULL,
                                          fe_grouping_variables = NULL, ...){

  assertthat::assert_that(!is.null(workflow@metadata$Data$raw_data_loaded),
                          workflow@metadata$Data$raw_data_loaded,
                          msg = 'Raw data not loaded')

  message('Defining features and targets...')

  if(feature_names[1] == '.'){
    field_names <- colnames(workflow@data@raw_data)
    feature_names <- field_names[field_names != target_name]
  }

  if(!is.null(workflow@metadata$model_factory)){
    assertthat::assert_that(!is.null(grouping_variables),
                            msg = 'You must select a grouping variable for Model Factory mode!')
    workflow <- update_metadata(workflow,
                                model_factory = list(grouping_variables = grouping_variables))
    workflow@model_factory@grouping_variables <- grouping_variables
  }
  if(!is.null(fe_grouping_variables)){
    workflow <- update_metadata(workflow,
                                feature_engineering = list(fe_grouping_variables = fe_grouping_variables))
  }

  features <- structure(
    lapply(feature_names,
           FUN = function(col_name, data){
             list(Name = col_name, Type = as.character(lapply(data[,col_name], class)))
           },
           data = workflow@data@raw_data),
    class = c('Feature', 'list'))

  target <- structure(
    list(Name = target_name, Type = class(workflow@data@raw_data[[target_name]])),
    class = c('Feature', 'list'))

  workflow <- update_metadata(workflow, Data = list(FeatureVariables = features,
                                                    TargetVariable = target))

  workflow@metadata$ModelHistory["StateEndDate"] <- as.character(Sys.time())

  workflow
}


#' Partitions the data into a test, training and validation sets
#'
#' @export
#'
#' @param workflow object of class ModelWorkflow
#' @param train_p proportion of the data to go in the training set
#' @param test_p proportion of the data to go in the test set
#' @param validation_p proportion of the data to go in the training set
#' @param audit_features logical should the features be audited
#'
#' @importFrom assertthat  assert_that
#' @importFrom caret createDataPartition
#' @importFrom methods is
#'
#' @return an object of class ModelWorkflow with an updated data slot
partition_data <- function(workflow, train_p, test_p, validation_p, audit_features){
  UseMethod("partition_data")
}

#' @export
partition_data.ModelWorkflow <- function(workflow, train_p, test_p, validation_p, audit_features = TRUE){
  assertthat::assert_that(is(workflow@data, 'MMdata'),
                          is(workflow@data@raw_data, 'data.frame'),
                          msg = 'Data not correctly loaded')
  message('Partitioning dataset...')

  assertthat::assert_that(sum(train_p, test_p, validation_p) == 1,
                          msg = 'probabilities do not sum to 1!')
  if(validation_p > 0){
    spec = c(train = train_p, test = test_p, validation = validation_p)
  } else {
    spec = c(train = train_p, test = test_p)
  }
  splits <- sample(cut(
    seq(nrow(workflow@data@raw_data)),
    nrow(workflow@data@raw_data) * cumsum(c(0, spec)),
    labels = names(spec)
  ))

  if(audit_features){
    message('Applying audit to features')
    features <- select_audit_features(workflow@data@audit,
                                      get_features(workflow))
    keeps <- c(workflow@metadata$Data$TargetVariable$Name,
               features,
               workflow@metadata$model_factory$grouping_variables)

  } else {
    keeps <- c(workflow@metadata$Data$TargetVariable$Name,
               get_features(workflow),
               workflow@metadata$model_factory$grouping_variables)
  }

  data_sets <- split(workflow@data@raw_data, splits)
  workflow@data@training_set <- data_sets$train[, keeps]
  workflow@data@test_set  <- data_sets$test[, keeps]
  if('validation' %in% names(data_sets)){
    workflow@data@validation_set  <- data_sets$validation[, keeps]
  }
  workflow
}



#' Set up and train a model based on the data in the MMWorkflow class object
#'
#' @export
#'
#' @param workflow an object of class MMWorkflow
#' @param formula a model formula. This overrides the automatic feature selection
#' @param training_engine a function for model training
#' @param print_model logical should the model diagnostics be printed out
#' @param cores number of processor cores to use
#' @param convert_to_dummy logical should the predictor dataset be converted to a model.matrix. Important for glmnet models
#' @param child logical should the dataset be removed from the returned object
#' @param \dots arguments to be passed to the training engine
#'
#' Examples of training engines are 'caret::train', 'randomForest', 'glmnet'. All training engines must have both
#' an x and y argument
#'
#' @importFrom assertthat assert_that
#'
train_model <- function(workflow, formula, training_engine, print_model, cores, convert_to_dummy, child, ...) {
  UseMethod("train_model")
}



#' @export
train_model.ModelWorkflow <- function(workflow, formula = NULL, training_engine,
                                      print_model = TRUE,
                                      cores = .MMoptions$cores,
                                      convert_to_dummy = FALSE,
                                      child = FALSE, ...){
  assertthat::assert_that(nrow(workflow@data@training_set) > 0, msg = 'Training data not loaded')
  assertthat::assert_that(length(workflow@metadata$Data$FeatureVariables) > 0,
                          length(workflow@metadata$Data$TargetVariable) > 0,
                          msg = 'Target and features not defined')
  features <- get_features(workflow)

  if(is.null(workflow@metadata$feature_engineering)){
    feature_eng <- NULL
    feature_eng_dat <- NULL
  } else if(workflow@metadata$feature_engineering$type == 'gam'){
    feature_eng <- workflow@metadata$feature_engineering$type
    feature_eng_dat <- workflow@features$univariate_gam
  }
  if(is.null(workflow@metadata$model_factory)){
    message('Training single model')


    workflow@model@model_object = train_single_model(dat = workflow@data@training_set,
                                                     features,
                                                     target = workflow@metadata$Data$TargetVariable$Name,
                                                     formula, training_engine,
                                                     feature_engineering = feature_eng,
                                                     feature_engineering_dat = feature_eng_dat,
                                                     dummy = convert_to_dummy,
                                                     ...)

    if(print_model){
      print(workflow@model)
    }
    workflow <- update_metadata(workflow, ModelHistory = list(ModelState = "Trained",
                                                  StateStartDate = as.character(Sys.time()),
                                                  StateEndDate = NA))

  } else {
    message('Training Model Factory')

    workflow@model_factory@models <- model_factory(dat = workflow@data@training_set,
                                                   grouping_variables = workflow@metadata$model_factory$grouping_variables,
                                                   features,
                                                   target = workflow@metadata$Data$TargetVariable$Name,
                                                   formula,
                                                   training_engine,
                                                   feature_engineering = feature_eng,
                                                   feature_engineering_dat = feature_eng_dat,
                                                   dummy = convert_to_dummy,
                                                   cores, ...)
    if(print_model){
      print(workflow@model_factory)
    }
    workflow <- update_metadata(workflow, ModelHistory = list(ModelState = "Trained",
                                                  StateStartDate = as.character(Sys.time()),
                                                  StateEndDate = NA))
  }
  if(child){
    workflow <- drop_data(workflow, drop = 'both')

  }
  workflow
}
