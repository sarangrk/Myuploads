#' An S4 class to represent the model component of a modelling workflow.
#'
#' @slot model_object representation of a model e.g. a train object
#'
MMmodel <- setClass('MMmodel',
                   slots = list(
                     model_object = 'ANY'
                   )
)

#' print method for MMmodel object
#'
#' @export
#'
#' @param x an object of class MMmodel
#' @param \dots arguments to be passed to the print method for the model object
print.MMmodel <- function(x, ...){
  if(!is.null(x@model_object)){
    print(x@model_object, ...)
  } else {
    print('Model has not yet been trained for this object')
  }
}
