#' Generic function to produce a single model object
#'
#' Works for either formula or x/y inputs
#'
#' should work for caret, cv.glmnet, lmer, glmer etc.
#'
#' @param dat a data frame
#' @param features character vector of training feature names
#' @param target character target variable name
#' @param formula a model formuka object e.g. for lmer models
#' @param training_engine function e.g. lmer, cv.glmnet, caret::train
#' @param feature_engineering NULL or character name of the type of FE used
#' @param feature_engineering_dat NULL or data.frame of FE data
#' @param dummy logical transform X to dummy variable matrix
#' @param ts_model logical use syntax for forecasting package models
#' @param \dots arguments to be passed on to the training engine
#'
#' Note that the formula interface cannot be used with feature engineering
#'
#' @return object of output class of the training engine
#'
#' @importFrom glmnet cv.glmnet
#'
#' @keywords internal
train_single_model <- function(dat, features, target, formula = NULL, training_engine,
                               feature_engineering = NULL,
                               feature_engineering_dat = NULL,
                               dummy = FALSE,
                               ts_model = FALSE,
                               ...){
  dots <- list(...)
  if(is.null(formula)){
    y <- dat[, target, drop = TRUE]
    if(is.null(feature_engineering)){
      x <- dat[, features]

    } else if(feature_engineering == 'gam'){
      assertthat::assert_that(!is.null(feature_engineering_dat), msg = 'You must supply a feature engineering dataset')
      x <- generate_new_features_gam(dat, features, feature_engineering_dat)
    } else {
      stop('Feature engineering type "', feature_engineering, '" not yet implemented!')
    }
    if(dummy){
      x <- to_dummy(x)
    }
    if(!ts_model){
      training_engine(x = x, y = y, ...)
    }else{
      if(!is.null(dots[['xreg']])){
        feat = dat[,dots[['xreg']]]
        training_engine(y, feat=feat, ...)
      }else{
        training_engine(y, ...)
      }
    }
  } else {
    training_engine(formula = formula, data = dat, ...)
  }
}




#' Runs multiple models of the same type over combinations of grouping variables
#'
#'
#' Calls train_single_model internally
#'
#' @param dat a data frame
#' @param grouping_variables character vector of names of grouping variables
#' @param features character vector of grouping variable names
#' @param target character name of target variable
#' @param formula a model formula object e.g. for lmer models
#' @param training_engine function e.g. lmer, cv.glmnet, caret::train
#' @param cores number of processor cores to run the model factory on
#' @param ts_model logical use syntax for forecasting package models
#' @param \dots arguments to be passed on to the training engine
#'
#' @return list of objects of output class of the training engine
#'
#' @importFrom dplyr filter
#' @importFrom parallel mclapply
#'
#' @keywords internal
model_factory <- function(dat, grouping_variables, features, target,
              formula = NULL, training_engine,
              feature_engineering = NULL,
              feature_engineering_dat = NULL,
              dummy = FALSE, cores = .MMoptions$cores, ts_model = FALSE, ...){
  ## Grid of group combinations for factory
  grouping_grid <- expand.grid(lapply(grouping_variables,
                                      function(x) unique(as.character(dat[[x]]))),
                               stringsAsFactors = FALSE)
  names(grouping_grid) <- grouping_variables
  ## Filter dataset to subgroup
  message('Running ', nrow(grouping_grid), ' models on ', cores, ' cores.')
  subgroup_models <- parallel::mclapply(1:nrow(grouping_grid), function(group){
    filter_string <- paste(vapply(grouping_variables,
                                  function(v) paste0(v, '== "', as.character(grouping_grid[group, v]), '"'),
                                  character(1)),
                           collapse = ' & ')
    message(filter_string)
    group_dat <- dplyr::filter_(dat, filter_string)
    if(!nrow(group_dat)){
      message('Empty dataset for subgroup!')
      return(list(NULL))
    }
    train_single_model(group_dat, features, target, formula, training_engine,
                       feature_engineering, feature_engineering_dat, dummy, ts_model, ...)

  }, mc.cores = cores)
  names(subgroup_models) <- vapply(1:nrow(grouping_grid),
                                   function(x) paste(grouping_grid[x, ], collapse = '__'), character(1))
  subgroup_models
}

# dat <- wf@data@test_set
# features = c('DOW', 'SEASONALITY', 'standard_trend',
#               'AVG_PREV_WEEKS_SLS_z', 'MA3_day_z', 'mean_fp_day_z')
# target = 'tot_sls'
# grouping_variables = c('BU_NUM', 'LINE_NUM')


