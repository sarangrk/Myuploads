#' Partitions time series data into a test, training and validation sets
#'
#' @export
#'
#' @param workflow object of class ModelWorkflow
#' @param train_p proportion of the data to go in the training set
#' @param test_p proportion of the data to go in the test set
#'
#' @importFrom assertthat  assert_that
#' @importFrom caret createDataPartition
#' @importFrom methods is
#'
#' Following prophet, all time series data must have columns ds and y
#'
#' @return an object of class ModelWorkflow with an updated data slot
partition_ts_data <- function(workflow, test_from, train_p, test_p){
  UseMethod("partition_ts_data")
}

#' @export
partition_ts_data.ModelWorkflow <- function(workflow, test_from = NULL, train_p, test_p){
  assertthat::assert_that(is(workflow@data, 'MMdata'),
                          is(workflow@data@raw_data, 'data.frame'),
                          msg = 'Data not correctly loaded')
  message('Partitioning dataset...')

  if(is.null(test_from)){
    if(train_p == 1){
      message('No test set selected. Training on all available data.')
      workflow@data@training_set <- workflow@data@raw_data
      return(workflow)
    }
    assertthat::assert_that(sum(train_p, test_p) == 1,
                            msg = 'probabilities do not sum to 1!')
    spec = c(train = train_p, test = test_p)
    splits <- table(cut(
      seq(nrow(workflow@data@raw_data)),
      nrow(workflow@data@raw_data) * cumsum(c(0, spec)),
      labels = names(spec)
    ))

    workflow@data@test_set  <- dplyr::top_n(workflow@data@raw_data, n = splits['test'], ds)
    workflow@data@training_set  <- dplyr::filter(workflow@data@raw_data,
                                                 ! ds %in% workflow@data@test_set$ds)
  } else {
    message('All timepoints >= ', test_from, ' in test set.')
    workflow@data@test_set  <- dplyr::filter(workflow@data@raw_data, ds >= test_from)
    workflow@data@training_set  <- dplyr::filter(workflow@data@raw_data, ds < test_from)
  }
  workflow
}



