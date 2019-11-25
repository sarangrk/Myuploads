#' Sets up initial metadata for a ModelWorkflow object
#'
#' @export
#'
#' @param workflow and object of class ModelWorkflow
#' @param model_name character string for the name of the workflow object
#' @param model_type character string
#' @param is_model_factory logical
#' @param use_case_name character string
#' @param use_case_start_dt Date
#' @param use_case_end_dt Date or NULL
#'
#'
#' @return an object of class ModelWorkflow with an updated metadata slot
initialize_metadata <- function(workflow, model_name, model_type,
                                is_model_factory,
                                use_case_name,
                                use_case_start_dt,
                                use_case_end_dt){
  UseMethod("initialize_metadata")
}

#' @export
initialize_metadata.ModelWorkflow <- function(workflow, model_name, model_type,
                                              is_model_factory = FALSE,
                                              use_case_name,
                                              use_case_start_dt = Sys.Date(),
                                              use_case_end_dt = NULL){
  message('Initializing metadata...')
  workflow@metadata <- create_metadata(model_name, model_type,
                                       is_model_factory, use_case_name,
                                       use_case_start_dt, use_case_end_dt)
  workflow
}


#' Upload the metadata slot from a ModelWorkflow object to the couchbase data store
#'
#' S3 method forming part of a model workflow
#'
#' @export
#'
#' @param workflow object of class ModelWorkflow
#' @param cb_bucket character name of the couchbase bucket
#' @param cb_host character hostname of the couchbase data store
#'
#' @return object of class ModelWorkflow passed through
write_metadata_to_store <- function(workflow, cb_bucket, cb_host) UseMethod("write_metadata_to_store")

#' @export
write_metadata_to_store.ModelWorkflow <- function(workflow, cb_bucket, cb_host){
  message('Saving metadata to store... ', appendLF = FALSE)
  cb <- save_metadata(metadata = workflow@metadata, bucket = cb_bucket, host = cb_host)
  message('Done.')
  workflow
}
