#'univariate analysis for continuous target variables
#'
#' This function allows you to identify the information potential of each explicative variable
#' @param dat data.frame containing the target and the explicative
#' @param predictor name of predictor variable
#' @param target character name of the target variable in dat
#' @param nuke_mod logical reduce size of the model
#' @param serialize_model serialize the model to a string
#'
#' @return data.frame of 1 row
#'
#' @importFrom stats median sd predict
#' @importFrom utils object.size
#'
#' @export
univariate_gam <- function(dat, predictor, target, nuke_mod = TRUE,
                                  serialize_model = .MMoptions$serialize_feature_engineering_models){

  update_model_info <- function(out, mod){
    if("try-error" %in% class(mod)) {
      out$formula <- '!model failure!'
    }
    else {
      mods <- summary(mod)
      #quick patch to make the MAPE calculation executable when tgt = 0
      tgt <- ifelse(tgt == 0, 1, tgt)
      pred <- ifelse(predict(mod,  type = "response") < 0, 0, predict(mod,  type = "link"))
      if(nuke_mod) mod <- nuke_gam(mod)
      out$formula <- Reduce(paste, deparse(mod$formula))
      out$Pvalue <- ifelse(is.null(mods$s.table[4]) == FALSE, mods$s.table[4], mods$p.table[8])
      out$deviance_explained <- mods$dev.expl
      out$r2 <- mods$r.sq
      out$MAPE <- mean(abs(pred - tgt) / tgt)
      out$gamModel <- auto_serialize(mod, serialize_model)
    }
    out
  }

  d <- dat[,predictor, drop = TRUE]
  tgt <- dat[[target]]
  out <- dplyr::data_frame(
    name_var = predictor,
    varClass = class(d),
    unique_values = length(unique(d)),
    formula = NA,
    Pvalue = NA,
    deviance_explained = NA,
    r2 = NA,
    MAPE = NA,
    gamModel = NA,
    line_size = NA
  )

  if(length(unique(d)) == 1) out$formula = '!unique values!'

  if(class(d) %in% c('character','factor', 'logical') & length(unique(d)) > 1) {
    d <- as.factor(d)
    mod <- try(mgcv::gam(tgt  ~  d, method = "REML", silent = TRUE))
    out <- update_model_info(out, mod)
  }

  #numeric variable analysis
  if(class(d) %in% c('numeric','integer') & length(unique(d)) > 1) {
    mod <- try(mgcv::gam(tgt ~ s(d, bs = "cr"), method = "REML"), silent = TRUE)
    if(("try-error" %in% class(mod)) == TRUE){
      mod <- try(mgcv::gam(tgt ~ s(d, k = 3, bs = "cr"), method="REML"), silent = TRUE)
    }
    if(("try-error" %in% class(mod)) == T){
      mod <- try(mgcv::gam(tgt ~ d, method = "REML"), silent = TRUE)
    }
    out <- update_model_info(out, mod)
  }
  out$line_size <- as.numeric(object.size(out))
  out
}

#' Runs a univariate gam on all features
#'
#' @export
#'
#' @param workflow ModelWorkflow object
#' @param variables vector of variables
#' @param \dots arguments to be passed on to the audit function
feature_engineer_gam <- function(workflow, variables, ...) {
  UseMethod("feature_engineer_gam")
}

#' @export
feature_engineer_gam.ModelWorkflow <- function(workflow, variables = NULL, ...){
  if(is.null(variables)){
    variables <- get_features(workflow)
  }
  message('Running univariate GAMs...')
  workflow@features$univariate_gam <- parallel_bind(dat = workflow@data@raw_data, variables, univariate_gam,
                                     target = workflow@metadata$Data$TargetVariable$Name, ...)
  update_metadata(workflow, feature_engineering = list(type = 'gam'))
}


#' filter for the univariate models with the specified criteria
#'
#' @param univariate_gam data.frame with feature engineering data
#'
#' This does basic filtering for sane variables
#'
#' @return filtered data.frame
select_univariate_gams <- function(univariate_gam){
  dplyr::filter(univariate_gam,
                unique_values > 1,
                r2 > 0,
                !is.na(gamModel))
}


#' construct a matrix of the engineered features from the gam univariate analysis
#'
#' @param dat data.frame containing original features
#' @param feature_name character matching one of the columns in dat
#' @param univariate_gams data.frame containing the model information for the univariate gam
#'
#' @return data.frame
#'
#' @export
build_model_matrix <- function(dat, feature_name, univariate_gams) {

  feature <- dplyr::select(dat, feature_name)
  feature_class <- class(feature[[1]])
  if(feature_class %in% c('numeric','integer')){
    if(is.null(univariate_gam)){
      if(any(is.na(feature))) feature[is.na(feature)] <- 0
      X <- as.matrix(feature)
    }
    else {
      mdl <- unpack_object(univariate_gams$gamModel[univariate_gams$name_var == feature_name])
      names(feature) <- 'd'
      X <- data.frame(
        feature = feature[[1]],
        response = predict(mdl, feature, type = "response"),
        predict(mdl, feature, type = "terms"),
        predict(mdl, feature, type = "lpmatrix")[, -1]  #remove the intercept
      )
      colnames(X) <- paste(feature_name, names(X), sep='_')
      if(any(is.na(X))) X[is.na(X)] <- 0
    }
  }
  else if(feature_class %in% c('factor','character')) {
    d <- feature[[1]]
    if(any(is.na(d))) d[is.na(d)] <- 0
    d <- as.factor(d)
    levs <- levels(d)
    if(length(levs) == 1){
      d <- rep(1, length(d))
      X <- model.matrix(~d - 1)
      colnames(X) <- paste(feature_name, levs[1], sep = '_')
    } else {
      X <- model.matrix(~d - 1)
      colnames(X) <- paste(feature_name, colnames(X), sep = '_')
    }
  }
  as.data.frame(X)
}


#' Wraps around build_model_matrix to construct a data frame of new engineered variables
#'
#'
#' @param feature_dat data.frame of variables to construct new features from
#' @param variables NULL or character vector of names of variables in feature_dat
#' @param univariate_gams data.frame
#'
#'
#' @export
generate_new_features_gam <- function(feature_dat, variables, univariate_gams){
  message('Constructing new features from GAM analysis...')
  parallel_bind(feature_dat, variables,
                fun = build_model_matrix,
                binding_fn = dplyr::bind_cols,
                univariate_gams = univariate_gams)
}


#a <- generate_new_features_gam(wf@data@training_set, get_features(wf), wf@features$univariate_gam)
