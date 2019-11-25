#' An S4 class to represent the model factory component of a modelling workflow.
#'
#' Model factories are lists of models of the same type that run over multiple splits of the
#' dataset. e.g. over products and stores.
#'
#' @slot grouping_variables character name of the  variable to split the data by
#' @slot model_object representation of a model e.g. a train object
#'
MMmodelFactory <- setClass('MMmodelFactory',
                   slots = list(
                     grouping_variables = 'character',
                     models = 'ANY'
                   ))



#' print method for MMmodelFactory object
#'
#' By default prints the first model in the factory
#'
#' @export
#'
#' @param x an object of class MMmodel
#' @param n which model in the factory should be printed
#' @param \dots arguments to be passed to the print method for the model object
print.MMmodelFactory <- function(x, n = 1, ...){
  if(!is.null(x@models)){
    s <- paste('Model factory containing',
               length(x@models),
               'models.', '\nGrouping variables:',
               paste(x@grouping_variables, collapse = ', '),
               '\nModel object number', n, ':')
    print(x@models[[n]], ...)
  } else {
    print('No models have been trained for this object yet')
  }
}
