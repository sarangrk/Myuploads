#' Put PMML
#'
#' @description Puts a pmml object into an S3 bucket
#'
#' @family awsS3
#'
#' @param file a character string containing the filename (or full path) of the file you want to upload to S3.
#' @param model_id a character string containing the model id from the metadata
#' @param object_path a character string containing the path to store the oject inside an S3 bucket.
#' @param bucket a character string with the name of the bucket
#' @param aws_credentials_path a character string containing the path where the aws credentials are stored; by default it looks in the project root directory; see \code{\link{s3HTTP}} for more details
#'
#' @importFrom aws.s3 put_object
#' @importFrom aws.signature locate_credentials use_credentials
#'
#' @keywords internal
#'
s3_put_pmml <- function(file, model_id, object_path, bucket, aws_credentials_path = "~/.aws/credentials"){

  # AWS connection credentials taken from the config location stored in the root of the project (i.e. .aws/credentials)
  aws_key <- aws.signature::locate_credentials(verbose = F)$key

  if (is.null(aws_key)) {
    aws.signature::use_credentials(file = normalizePath(aws_credentials_path))
  }

  object <- file.path(object_path, paste0(model_id, ".pmml"))

  aws.s3::put_object(file, object = object, bucket = bucket)

}
