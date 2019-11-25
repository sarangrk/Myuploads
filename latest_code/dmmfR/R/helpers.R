#' Generic function for updating metadata in a ModelWorkflow object
#' NOTE: should replace with recursive internal function for arbitrarily nested lists
#'
#' @param workflow object of class ModelWorkflow
#' @param \dots metadata name and value pairs
#'
#'
#' @return object of class ModelWorkflow with updated metadata
#'
#' @export
update_metadata <- function(workflow, ...){
  assertthat::assert_that(is(workflow, 'ModelWorkflow'), msg = 'Not a ModelWorkflow object')
  updates <- list(...)
  if(length(workflow@metadata)){
    for(u in names(updates)){
      if(is.list(workflow@metadata[[u]])){
        for(sl in names(updates[[u]])){
          workflow@metadata[[u]][[sl]] <- updates[[u]][[sl]]
        }
      } else {
        workflow@metadata[[u]] <- updates[[u]]
      }
    }
    workflow
  } else {
    stop('Metadata not initialized')
  }
}

#' Get Feature Names from the Metadata
#'
#' Iterates through the feature list stored in the metadata of an oject of class `ModelWorkflow` and gets the feature names
#'
#' @param workflow object of class ModelWorkflow
#'
#' @return an array of defined features names used for model training
#'
#' @export
#'
get_features <- function(workflow) {

  features <- vapply(workflow@metadata$Data$FeatureVariables,
         FUN = function(l) l[['Name']], character(1))
  features[!features %in% c(workflow@metadata$model_factory$grouping_variables,
                            workflow@metadata$feature_engineering$fe_grouping_variables)]
}



#' convert all categorical variables to dummy vars
#'
#' @param X a dataframe
#'
#' @return a matrix
#'
#' @importFrom stats model.matrix
#'
#' @keywords internal
to_dummy <- function(X){
  stats::model.matrix(~ . - 1, data = X)
}
