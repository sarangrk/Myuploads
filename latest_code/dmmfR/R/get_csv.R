#' AWS S3 Integration
#'
#' @description Connects to S3 and returns an object of type csv
#'
#' @family DataGathering awsS3
#'
#' @param bucket AWS S3 bucket name
#' @param object file path inside the aws s3 bucket
#' @param aws_credentials_path a character string with the path where aws credentials are stored
#'
#' @importFrom aws.s3 get_object
#' @importFrom aws.signature locate_credentials use_credentials
#' @importFrom readr read_csv
#'
#' @keywords internal
#'
s3_get_csv <- function(bucket, object, aws_credentials_path = "~/.aws/credentials"){

  # AWS connection credentials taken from the config location stored in the root of the project (i.e. .aws/credentials)
  aws_key <- aws.signature::locate_credentials(verbose = F)$key

  if (is.null(aws_key)) {
    aws.signature::use_credentials(file = normalizePath(aws_credentials_path))
  }

  r <- aws.s3::get_object(object = object, bucket = bucket)

  data <- readr::read_csv(rawToChar(r))

  return(data)
}
