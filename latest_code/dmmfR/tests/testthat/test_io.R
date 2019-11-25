# library(dmmfR)
# library(magrittr)

# mod_name <- 'test'
# mod_type <- 'randomForest'
# use_case <- 'prediction model'
# now <- Sys.Date()
# bucket <- 'dslab-data'
# object_path <- "dockerised_mmf_schema/data/train/Iris.csv"
# creds <- '~/.aws/credentials'
#
# wf0 <- ModelWorkflow() %>%
#   initialize_metadata(model_name = mod_name,
#                       model_type = mod_type,
#                       use_case_name = use_case,
#                       use_case_start_dt = now) %>%
#   add_raw_data_from_S3(bucket = bucket,
#                        data_object_path = object_path,
#                        aws_credentials_path = creds)
#
# context('Upload / download from S3')
#
# test_that('data load function operates sanely', {
#   expect_error(add_raw_data_from_S3((ModelWorkflow()), bucket = bucket,
#                                     data_object_path = object_path))
#   expect_s4_class(wf0, 'ModelWorkflow')
#   expect_is(wf0@metadata, 'list')
#   expect_s4_class(wf0@data, 'MMdata')
#   expect_s4_class(wf0@model, 'MMmodel')
#   expect_s4_class(wf0@scores, 'MMscoring')
# })
#
# test_that('Data is correctly downloaded from S3 bucket', {
#   expect_is(wf0@data@raw_data, 'data.frame')
#   expect_gt(nrow(wf0@data@raw_data), 0)
# })
#
#
# test_that('Metadata is correctly updated after download', {
#   expect_is(wf0@metadata$Data, 'list')
#   expect_equal(wf0@metadata$Data$source, 'S3')
#   expect_equal(wf0@metadata$Data$region, aws.s3::get_location(bucket))
#   expect_equal(wf0@metadata$Data$object_path, object_path)
#   expect_true(wf0@metadata$Data$raw_data_loaded)
# })
#
#
#
#
