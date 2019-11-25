#' Load Metadata
#'
#' @description Load Metadata of a given model id from Couchbase
#'
#' @family metadata
#' @param model_id a string
#' @param bucket a character string
#' @param host a url string of couchbase host; Default points to the couchbase hosted on kubernetes
#'
#' @importFrom httr add_headers content POST
#' @importFrom jsonlite fromJSON
#'
#' @keywords internal
#'
load_metadata <- function(model_id, bucket, host = "http://ec2-52-215-64-233.eu-west-1.compute.amazonaws.com:8093"){

  query <- paste0("select * from `", bucket, "` where ModelID = \"", model_id, '\"')

  cbServer <- paste0(host, "/query/service")

  req <- httr::POST(cbServer,
                    httr::add_headers("Content-Type" = "application/x-www-form-urlencoded;charset=UTF-8"),
                    body = paste("statement=", query))

  res <- jsonlite::fromJSON(httr::content(req, "text"))

  return(as.list(res$result$`model-metadata`))
}
