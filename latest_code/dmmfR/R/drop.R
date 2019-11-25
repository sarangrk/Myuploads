#' Drops models and/or model factory ensembles
#'
#' Saves memory and helper for creating child workflows
#'
#' @param workflow an object of class ModelWorkFlow
#' @param drop character drop model, model factory or both
#' @param \dots passed through
#'
#' @return an object of class ModelWorkFlow
#'
#' @export
#'
drop_models <- function(workflow, drop, ...) {
  UseMethod("drop_models")
}


#' @export
drop_models.ModelWorkflow <- function(workflow, drop = c('both', 'model', 'factory'), ...){
  drop <- match.arg(drop)
  if(drop %in% c('both', 'model') && !is.null(workflow@model@model_object)){
    message('Dropping model')
    workflow@model <- MMmodel()
  }
  if(drop %in% c('both', 'factory') && !is.null(workflow@model_factory@models)){
    message('Dropping model factory')
    workflow@model_factory <- MMmodelFactory(grouping_variables = workflow@model_factory@grouping_variables)
  }
  workflow
}



#' Drops raw data and/or test/train/validation data
#'
#' Saves memory and helper for creating child workflows
#'
#' @param workflow an object of class ModelWorkFlow
#' @param drop character drop raw data, test/train/validation sets or all data
#' @param \dots passed through
#'
#' @return an object of class ModelWorkFlow
#'
#' @export
#'
drop_data <- function(workflow, drop) {
  UseMethod("drop_data")
}

#' Drops the data from the data slot
#'
#' @param workflow object of class ModelWorkflow
#' @param drop character one of both, raw or testtrainvalid
#' export
drop_data.ModelWorkflow <- function(workflow, drop = c('both', 'raw', 'testtrainvalid')){
  drop <- match.arg(drop)
  if(drop == 'both'){
    message('Dropping all data')
    workflow@data <- MMdata()
  } else if(drop == 'raw'){
    message('Dropping raw data')
    workflow@data@raw_data <- data.frame()
  } else if(drop == 'testtrainvalid'){
    message('Dropping test/train/validation data sets')
    workflow@data@training_set <- data.frame()
    workflow@data@test_set <- data.frame()
    workflow@data@validation_set <- data.frame()
  }
  workflow
}



#' A function to nuke GAM models
#'
#' This function allows you to reduce the GAM model object size for big datasets
#'
#' @param model GAM model object name you want to nuke
#' @param verbose logical print space saving details
#'
#' @export
nuke_gam <- function(model, verbose = FALSE) {

  S1 <- object.size(model)

  model$data <- c()
  model$y <- c()
  model$linear.predictors <- c()
  model$weights <- c()
  model$fitted.values <- c()
  model$model <- c()
  model$prior.weights <- c()
  model$residuals <- c()
  model$effects <- c()
  model$working.weights <- c()
  model$prior.weights <-c()
  model$offset <-c()
  model$hat <-c()
  model$dw.drho <- c()

  model$family$d2link <- c()
  model$family$d3link <- c()
  model$family$d4link <- c()
  model$family$dvar <- c()
  model$family$d2var <- c()
  model$family$d3var <- c()
  model$family$ls <- c()
  model$family$validmu <- c()
  model$family$simulate <- c()
  model$family$aic <- c()
  model$family$dev.resids <- c()
  model$family$variance <- c()
  model$family$initialize <- c()

  S2 <- object.size(model)
  if(verbose) {
    print(paste("model nuked from:", round(S1/1024/1024,2),"Mb to:", round(S2/1024/1024,2),"Mb", sep=" "))
    print("You cannot access the plots, gam.check and several stats anymore for that model")
    print("extract what you need before launching that function")
    print("Predict can still be executed")
  }

  model
}


#' replaces any named slots in the workflow with new instantiations of the class
#'
#' @param workflow object of class ModelWorkflow
#' @param \dots character names of slots to drop
#'
#' @return ModelWorkflow object with slots dropped
#'
#' @export
drop_slots <- function(workflow, ...){
  slots <- c(...)
  for(s in slots){
    slt <- tryCatch(slot(workflow, s),
                    error = function(e){
                      message('Slot "', s, '" does not exist')
                      NULL
                    })
    if(exists('slt') && !is.null(slt)){
      message('Dropping ', s)
      slot(workflow, s) <- new(class(slot(workflow, s)))
    }
  }
  workflow
}


