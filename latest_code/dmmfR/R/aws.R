#' Pulls an object from S3 and tries to unserialise it
#' 
#' Designed to work with serialised model workflow objects
#' 
#' @export
#' 
#' @param bucket AWS S3 bucket name
#' @param object file path inside the aws s3 bucket
#' @param aws_credentials_path a character string with the path where aws credentials are stored
#'
#' @importFrom aws.s3 save_object
#' @importFrom aws.signature locate_credentials use_credentials
#' 
#' @seealso unpack_object
#' 
#' @examples \dontrun{
#'  wf <- get_S3_unserialise('dslab-aops-dev-dmmf', 
#'                           'models/unapproved/demand-forecasting-demo/test_workflow_serialised')
#' } 
get_S3_unserialise <- function(bucket, object, aws_credentials_path = "~/.aws/credentials"){
  
  # AWS connection credentials taken from the config location stored in the root of the project (i.e. .aws/credentials)
  aws_key <- aws.signature::locate_credentials(verbose = FALSE)$key
  
  if (is.null(aws_key)) {
    aws.signature::use_credentials(file = normalizePath(aws_credentials_path))
  }
  model_temp_path <- tempfile(pattern = 's3stringobject', fileext = '.tmp')
  obj <- tryCatch({
    aws.s3::save_object(object = object, bucket = bucket, file = model_temp_path)
    unpack_object(readChar(model_temp_path, file.info(model_temp_path)$size))
  }, error = function(e){
    'Unable to Read file'
  })
  return(obj)
}







