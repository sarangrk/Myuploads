#' An S4 class to represent the scoring component of a modelling workflow.
#'
#' @slot test_set_predictions data frame
#' @slot validation_set_predictions data frame
#' @slot training_set_predictions
#'
#' @export
MMscoring <- setClass('MMscoring',
                      slots = list(test_set_predictions = 'list',
                                   validation_set_predictions = 'list',
                                   training_set_predictions = 'list')
)
