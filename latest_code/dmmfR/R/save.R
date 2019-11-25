#' Save Model Metadata
#'
#' @description Saves model metadata as a json document into a couchbasedb bucket. It mimicks the \code{cb.upsert} methon in python
#'
#' @family metadata
#'
#' @param metadata a metadata object (a list for now), created using \code{\link{create_metadata}} function
#' @param bucket a character string with the name of the bucket where the metadata should be stored
#' @param host a character string with the couchbase hostname
#'
#' @importFrom reticulate import r_to_py use_condaenv
#' @importFrom jsonlite toJSON
#' @importFrom httr build_url parse_url
#'
#' @keywords internal
#'
save_metadata <- function(metadata, bucket, host = "ec2-52-215-64-233.eu-west-1.compute.amazonaws.com:8091"){

  Bucket <- reticulate::import("couchbase.bucket")$Bucket
  fmt_json <- reticulate::import("couchbase")$FMT_JSON

  host <- strsplit(host, split = ":")

  url <- httr::parse_url("couchbase:")
  url$hostname <- host[[1]][1]
  url$port <- host[[1]][2]
  url$path <- bucket

  cb_bucket_url <- httr::build_url(url)

  cb = Bucket(cb_bucket_url)

  metadata_json <- jsonlite::toJSON(metadata, auto_unbox = T)
  metadata_py <- reticulate::r_to_py(metadata)

  id <- metadata$id

  # save document
  cb$upsert(id, metadata_py, format = fmt_json)

  return(TRUE)
}
