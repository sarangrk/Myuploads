#' Currently only works with a single external regressor and model factory
#'
#' @param workflow model workflow object
#' @param elasticties_df data.frame containing elasticities data
#' @param group_vars names of model factory grouping variables
#' @param mod_name character id of the model in the workflow object
#' @param joining_vars named vector of joining variables with the elasticities_df
#' @param elasticity_var character name of the elasticity variable in elasticities_df
#' @param evaluation_funs list of names of functions to calculate elasticities for. Typically functions from MLmetrics
#'
#' @return data.frame
#'
#' @export
validate_single_prophet_model <- function(workflow, elasticities_df,
                                  group_vars = c('PRODUCT', 'SHOP'),
                                  mod_name = '1__1',
                                  joining_vars = c('PRODUCT'),
                                  elasticity_var = 'PRICE_ELASTICITY',
                                  evaluation_funs = list('MAPE', 'Poisson_LogLoss')){
  groups <- vapply(1:length(group_vars), function(x) strsplit(mod_name, '__')[[1]][x], character(1))
  names(groups) <- group_vars
  ## Absolute percentage error of price elasticities
  mod <- workflow@model_factory@models[[mod_name]]
  coef_dat <- data_frame(beta = mod$params$beta[,length(mod$params$beta)],
                         y_scale = mod$y.scale,
                         coef = beta * y_scale)
  for(v in names(groups)){
    coef_dat[v] <- groups[v]
  }
  coef_dat <- coef_dat %>%
    inner_join(elasticities_df , by = joining_vars) %>%
    mutate(APE_elasticity = (abs(PRICE_ELASTICITY - coef) / PRICE_ELASTICITY))

  ## Validate predictions
  filter_string <- paste(vapply(names(groups),
                                function(v) paste0(v, '== "', groups[v], '"'),
                                character(1)),
                         collapse = ' & ')

  preds <- workflow@scores@test_set_predictions$predictions[[mod_name]]
  trues <- dplyr::filter_(workflow@data@test_set, filter_string)

  names(evaluation_funs) <- evaluation_funs
  evaluation_results <- lapply(evaluation_funs, function(x) get(x)(preds$yhat, trues$y))
  for(res in names(evaluation_results)){
    coef_dat[res] <- evaluation_results[res]
  }
  coef_dat
}

#' Currently only works with a single external regressor and model factory
#'
#' @param workflow model workflow object
#' @param elasticties_df data.frame containing elasticities data
#' @param group_vars names of model factory grouping variables
#' @param joining_vars named vector of joining variables with the elasticities_df
#' @param elasticity_var character name of the elasticity variable in elasticities_df
#' @param evaluation_funs list of names of functions to calculate elasticities for. Typically functions from MLmetrics
#' @param cores number of processor cores to use
#' @return data.frame
#'
#' @export
validate_prophet_model_factory <- function(workflow, elasticities_df,
                                           group_vars = c('PRODUCT', 'SHOP'),
                                           joining_vars = c('PRODUCT'),
                                           elasticity_var = 'PRICE_ELASTICITY',
                                           evaluation_funs = list('MAPE', 'Poisson_LogLoss'),
                                           cores){

  model_names <- names(workflow@model_factory@models)
  names(model_names) <- model_names
  validations <- dplyr::bind_rows(parallel::mclapply(model_names,
                     function(m_name) validate_single_prophet_model(workflow = workflow,
                                                                      elasticities_df = elasticities_df,
                                                                      group_vars = group_vars,
                                                                      mod_name = m_name,
                                                                      joining_vars = joining_vars,
                                                                      elasticity_var = elasticity_var,
                                                                      evaluation_funs = evaluation_funs),
                     mc.cores = cores))
  workflow@validation$model_validation <- validations
  workflow
}



