#' Pulls data from local data source and adds to the data slot
#'
#' @export
#'
#' @param workflow and object of class ModelWorkflow
#' @param path data.frame or character string for the path to the object in the S3 bucket
#'
#' @importFrom aws.s3 get_location
#' @importFrom stringr str_extract
#'
#' @return an object of class ModelWorkflow with updated data and metadata slots
add_raw_data <- function(workflow, path) UseMethod("add_raw_data")

#' @export
#' @method add_raw_data ModelWorkflow
#' @rdname add_raw_data
add_raw_data.ModelWorkflow <- function(workflow, path){
  if(is.character(path)){
    file_suffix <- tolower(stringr::str_extract(path, '\\..+$'))
    import_map <- list('.csv' = readr::read_csv,
                       '.tsv' = readr::read_tsv,
                       '.rds' = readr::read_rds)
    assertthat::assert_that(!is.null(import_map[[file_suffix]]),
                            msg = 'Unknown data file format.')

    pulled_data <- import_map[[file_suffix]](path)
    workflow@data <- MMdata(raw_data = pulled_data)
    message('Data loaded from ', path)
  } else if(is.data.frame(path)){
    workflow@data <- MMdata(raw_data = path)
    path <- paste('data.frame', deparse(substitute(path)), sep = ':')
  } else {
    stop('Provide a path to a data set or a local dataframe')
  }

  ## Update
  update_metadata(workflow,
                  Data = list(source = 'local',
                              region = '',
                              bucket = '',
                              object_path = paste('local', path, sep = ":"),
                              raw_data_loaded = TRUE))
}

