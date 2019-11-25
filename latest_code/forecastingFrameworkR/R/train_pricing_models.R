#' Trains prophet models giving optimisation parameters. Used to try different attempts in fiding the best solution.
#'
#' This function allows to train models trying different parameters, such as if the target variable should be logged or not.
#' To then consolidate all the results and make a decision of what is the best approach.
#'
#' @param optim_params list with parameters to take into consideration:
#'  - opt_var: character with the variable to optimise, it needs to be added as a regressor;
#'  - logged_price: boolean stating if the price variable is logged;
#'  - logged_sales: boolean indicating if the target variable is Demand or the given y, ie log(Sales+1)
#' @param df data.frame with the data to be trained and tested
#' @param attempt_id an identifier of the attempt to save the results.
#' @param data_path chracter indicating where to find the data and where to save the particular data for the attempt
#' @param cores_nr integer indicating the number of cores used in the workflow object to train the models
#'
#' @return a ModelWorkflow object from dmmfR package with the fitted models across Products and Shops
#' @export
#'
#' Types of interpolate are 'linear', 'spline', other generic function names are also supported
#' such as 'mean' and 'median'
#'
#' @import dplyr dmmfR prophet
#'
train_pricing_models <- function(df, attempt_id, data_path="data-raw",
                                 opt_var="log_price",
                                 target_var="log_sales",
                                 grouping_variables = c('PRODUCT', 'SHOP'),
                                 cores_nr=1,
                                 logged_sales=ifelse(target_var=="log_sales", TRUE, FALSE),
                                 logged_price=ifelse(opt_var=="log_price", TRUE, FALSE),
                                 test_from = as.Date('2017-10-01')){

  # Define Target - logged or not
  df_attempt <- df
  df_attempt["y"] = df_attempt[target_var]

  data_attempt_path = paste0(data_path,"/data_",attempt_id,".rds")
  saveRDS(df_attempt, data_attempt_path)

  prophet_fun <- function(data, ...){
    prophet() %>%
      add_regressor(opt_var, standardize = FALSE) %>%
      fit.prophet(df = data)
  }

  # Define model
  workflow <- ModelWorkflow() %>%
    initialize_metadata(model_name = attempt_id,
                        model_type = "prophet",
                        is_model_factory = TRUE,
                        use_case_name = "Demo of price optimization and dynamic regression demand modelling") %>%
    add_raw_data(path = data_attempt_path) %>%
    define_features(feature_names = c(opt_var),
                    target_name = 'y',
                    grouping_variables = grouping_variables) %>%
    partition_ts_data(test_from = test_from, train_p = 1, test_p = 0) %>%
    train_model(formula = '',
                training_engine = prophet_fun,
                print_model = FALSE,
                convert_to_dummy = FALSE,
                child = FALSE,
                cores = cores_nr) %>%
    update_metadata(
      logged_price = logged_price,
      logged_sales = logged_sales,
      opt_var = opt_var,
      target_var = target_var
    )

  return(workflow)
}
