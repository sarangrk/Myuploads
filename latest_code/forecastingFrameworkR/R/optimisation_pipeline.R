#' Applies a price optimisation on top of fitted Prophet models
#'
#'
#' @param workflow, a ModelWorkflow() object of the package dmmfR, with the fitted Prophet models
#' @param optim_params list with parameters to take into consideration:
#'  #' @param optim_params list with parameters to take into consideration:
#'  - opt_var: character with the variable to optimise, it needs to be added as a regressor;
#'  - logged_price: boolean stating if the price variable is logged or the raw price;
#'  - logged_sales: boolean indicating if the target variable is Demand or the given y, ie log(Sales+1)
#'  - sim_time_units: number of timepoints in future to apply the optimisation to (not used if use_test_data == FALSE);
#'  - use_test_data: Boolean indicating if you use the test dataset or predict sim_time_unit timepoints forward
#'  - min_price_ratio: numeric value specifying the constraint of the minimum price as a ratio of the product cost.
#'     - if min_price_ratio = 0.6 then minimum price will be cost*0.6
#'  - max_price_ratio: numeric value specifying the constraint of the maximum price as a ratio of the base price of the product.
#'     - if  max_price_ratio = 1.5 then the maximum price will be max( actual price) * 1.5
#' @param attempt_id character string id for the optimisation run
#' @param cores number of processor cores to run over
#' @return a data.frame with the results of the optimisation. In case of error returns the erros message
#' @export
#'
#' @importFrom parallel mclapply
#'
#' @seealso optimisation_model_fn
price_optimisation <- function(workflow, list_models, cores, optimisation_id, ...){
  UseMethod("price_optimisation")
}

#' @export
price_optimisation.ModelWorkflow <- function(workflow, list_models=c(), cores = 1, optimisation_id="", ...){
  message('Running price optimisation')

  if(length(list_models)==0){
    list_models <- as.list(names(workflow@model_factory@models))
    names(list_models) <- as.vector(list_models)
  } else{
    list_models <- as.list(list_models)
    names(list_models) <- as.vector(list_models)
  }
  optimisation_results <- parallel::mclapply(list_models, FUN = optimisation_model_fn,
                                   workflow = workflow, mc.cores = cores, ...)
  if(is.null(workflow@validation$price_optimisation)){
    workflow@validation$price_optimisation <- list()
  }

  if(optimisation_id==""){
    optimisation_id <- paste0("Optimisation#",length(workflow@validation$price_optimisation)+1)
  }

  # optim_attempt <- list(...)
  # optim_attempt$optimisation_results <- optimisation_results
  # optim_attempt$optimisation_id <- optimisation_id
  workflow@validation$price_optimisation[[optimisation_id]] <- optimisation_results
  workflow
}


