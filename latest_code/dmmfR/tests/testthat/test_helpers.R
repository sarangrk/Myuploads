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

context('Updating metadata')

test_that('Correct objects are updated', {
  expect_error(update_metadata(list(workflow = data.frame())))
  expect_error(update_metadata(wf0, test_update = 'testing'))
  expect_equal(update_metadata(wf1, test_update = 'testing')@metadata$test_update, 'testing')
  expect_is(update_metadata(wf1, test_update = list(internal = 'testing'))@metadata$test_update, 'list')
})

