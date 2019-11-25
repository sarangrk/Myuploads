#' An S4 class to represent the data component of a modelling workflow.
#'
#' @slot raw_data data frame for the data as imported
#' @slot training_set data frame for the data as imported
#' @slot test_set data frame for the data as imported
#' @slot validation_set data frame for the data as imported
#'
MMdata <- setClass('MMdata',
                   slots = list(
                     raw_data = 'data.frame',
                     training_set = 'data.frame',
                     test_set = 'data.frame',
                     validation_set = 'data.frame',
                     audit = 'data.frame'
                   )
)
