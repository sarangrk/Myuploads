#' @include class_data.R helpers.R class_model.R class_scoring.R
#' class_data.R MMmetadata.R MMfeatures.R class_model.R class_model_factory.R class_scoring.R MMvalidation.R helpers.R
NULL

##### S4 #####


#' An S4 class to represent a modelling workflow.
#'
#' @slot metadata list
#' @slot data object of class MMdata to contain the raw data, test and training sets
#' @slot features list of predictor features and their classes
#' @slot model object of class MMmodel
#' @slot model_factory object of class MMmodelFactory
#' @slot scores object of class MMscoring
#' @slot validation list for validation
#'
#' @export ModelWorkflow
#' @exportClass ModelWorkflow
ModelWorkflow <- setClass('ModelWorkflow',
                          slots = list(
                            metadata = 'list',
                            data = 'MMdata',
                            features = 'list',
                            model = 'MMmodel',
                            model_factory = 'MMmodelFactory',
                            scores = 'MMscoring',
                            validation = 'list'
                          )
)

#
# #' @export
# setMethod(f = "print", signature = signature(x = "ModelWorkflow"),
#           definition = function(x) {
#             print(x)
#           })

