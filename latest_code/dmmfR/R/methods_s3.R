#' Pulls data from S3 and adds to the data slot
#'
#' @export
#'
#' @param workflow and object of class ModelWorkflow
#' @param bucket character string for the name of the S3 bucket to pull
#' @param data_object_path character string for the path to the object in the S3 bucket
#' @param aws_credentials_path character string for the path to the aws credentials
#'
#' @importFrom aws.s3 get_location
#'
#' @return an object of class ModelWorkflow with updated data and metadata slots
add_raw_data_from_S3 <- function(workflow, bucket, data_object_path,
                                 aws_credentials_path) UseMethod("add_raw_data_from_S3")

#' @export
#' @method add_raw_data_from_S3 ModelWorkflow
#' @rdname add_raw_data_from_S3
add_raw_data_from_S3.ModelWorkflow <- function(workflow, bucket, data_object_path,
                                               aws_credentials_path = '~/.aws/credentials'){
  message('Getting data from S3...')
  pulled_data <- s3_get_csv(bucket, data_object_path, aws_credentials_path)
  workflow@data <- MMdata(raw_data = pulled_data)
  ## Update
  update_metadata(workflow,
                  Data = list(source = 'S3',
                              region = aws.s3::get_location(bucket),
                              bucket = bucket,
                              object_path = data_object_path,
                              raw_data_loaded = TRUE))
}


#' Translate the model object to pmml format and then export to S3
#'
#' @export
#'
#' @param workflow an object of class ModelWorkflow
#' @param bucket character name of the S3 bucket to write to
#' @param object_path character path to the location of the model store
#' @param aws_credentials_path character path to aws credentials
#'
#' @importFrom r2pmml r2pmml
#'
#' @return an object of class ModelWorkflow with updated data and metadata slots
#' Models are saved in the object_path with `ModelID` (from the metadata) suffixed by 'pmml'
write_model_to_S3 <- function(workflow, bucket, object_path,
                             aws_credentials_path) UseMethod("write_model_to_S3")

#' @export
#' @rdname write_model_to_S3
write_model_to_S3.ModelWorkflow <- function(workflow, bucket, object_path,
                              aws_credentials_path = '~/.aws/credentials'){

  model_temp_path <- tempfile(pattern = workflow@metadata$ModelName, fileext = '.pmml')

  message('Building pmml file')

  r2pmml::r2pmml(workflow@model@model_object, model_temp_path)

  message('Saving model artefects to S3...', appendLF = FALSE)

  s3_put_pmml(file = model_temp_path,
              model_id = workflow@metadata$ModelID,
              object_path = object_path,
              bucket = bucket,
              aws_credentials_path = aws_credentials_path)

  message(' Done.')

  update_metadata(workflow, ModelSource = file.path(bucket, object_path, paste0(workflow@metadata$ModelID, ".pmml")))
}





