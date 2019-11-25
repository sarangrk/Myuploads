library(dmmfR)
library(magrittr)


mod_name <- 'test'
mod_type <- 'randomForest'
use_case <- 'prediction model'
now <- Sys.Date()
wf0 <- ModelWorkflow()
wf1 <- wf0 %>%
  initialize_metadata(model_name = mod_name,
                      model_type = mod_type,
                      use_case_name = use_case,
                      use_case_start_dt = now)
wf2 <- wf0 %>%
  initialize_metadata(model_name = mod_name,
                      model_type = mod_type,
                      use_case_name = use_case,
                      use_case_start_dt = now,
                      use_case_end_dt = now)

context('ModelWorkflow_S4.R')

test_that('Class definitions are correct', {
  expect_s4_class(wf0, 'ModelWorkflow')
  expect_is(wf0@metadata, 'list')
  expect_s4_class(wf0@data, 'MMdata')
  expect_s4_class(wf0@model, 'MMmodel')
  expect_s4_class(wf0@scores, 'MMscoring')
})


context("ModelWorkflow_S3.R")


test_that("metadata is correctly initialized", {

  expect_equivalent(as.character(methods(initialize_metadata)), 'initialize_metadata.ModelWorkflow')
  expect_s4_class(wf1, 'ModelWorkflow')
  expect_is(wf1@metadata, 'list')
  expect_s4_class(wf1@data, 'MMdata')
  expect_s4_class(wf1@model, 'MMmodel')
  expect_s4_class(wf1@scores, 'MMscoring')

  expect_length(wf1@metadata, 19)
  expect_equal(wf1@metadata$ModelName, mod_name)
  expect_equal(wf1@metadata$ModelType, mod_type)
  expect_equal(wf1@metadata$UseCase$UseCaseName, use_case)
  expect_equal(wf1@metadata$UseCase$UseCaseStartDate, as.character(now))
  expect_equal(wf1@metadata$UseCase$UseCaseEndDate, character(0))

  expect_equal(wf2@metadata$UseCase$UseCaseEndDate, as.character(now))
})






