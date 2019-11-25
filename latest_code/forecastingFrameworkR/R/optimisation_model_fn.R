#' Applies a price optimisation on top of fitted Prophet models
#'
#' This function will optimise the price for a given model, <Product>__<Shop>, from the models attribute within the ModelWorkflow object provided.
#' The optimisation takes several parameters to optimise according to the fitted model and also to the user specifications
#'
#' @param model_name character with the model name to apply the optimisation, <Product>__<Shop>
#' @param workflow, a ModelWorkflow() object of the package dmmfR, with the fitted Prophet models
#' @param sim_time_units: number of timepoints in future to apply the optimisation to (not used if use_test_data == FALSE);
#' @param time_unit: unit argument for difftime function to generate the future timstamps.
#'    - Could be any of those values: c("auto", "secs", "mins", "hours","days", "weeks")
#'    - Only used when use_test_data == FALSE and start_time is provided.
#' @param start_time: a Date or POSIXct specifying the starting time for the simulation. Only used if use_test_data == FALSE.
#'    - If not provided then the future timestamps are generated using prophet::make_future_dataframe()
#' @param use_test_data: Boolean indicating if you use the test dataset or predict sim_time_unit timepoints forward
#' @param min_price_ratio: numeric value specifying the constraint of the minimum price as a ratio of the product cost.
#'     - if min_price_ratio = 0.6 then minimum price will be cost*0.6
#' @param max_price_ratio: numeric value specifying the constraint of the maximum price as a ratio of the base price of the product.
#'     - if  max_price_ratio = 1.5 then the maximum price will be base price * 1.5
#' @param base_price: numeric value of the base price of the product.
#' @param base_cost: numeric value of the base cost of the product.
#' @param cost_col: character string specifying the column for cost, default is "COST". Only used if base_cost is not provided.
#' @param price_col: character string specifying the column for price, default is "PRICE". Only used if base_price is not provided.
#' @param sales_col: character string specifying the column for sales, default is "SALES"
#' @param target_sales_lst: named list, specifying the target sales for the given model, default is an empty list.
#' The names of the list is the different model names.
#' - if model_name is not one of the entries of target_sales_lst, then the optimisation problem will be unconstrained
#' and the optimisation target will be profit= `sum(units_sold * price) - (units_sold * unit_cost)`
#' - if model_name is one of the entries of target_sales_lst, then the optimisation problem is constrained to the available stock
#' and the optimisation target will be revenue= `sum(units_sold * price)`
#' @param extra_regressors: data.frame with the values of the extra regressors for the simulation.
#' - The number of rows should be sim_time_units
#' - And each column represents one extra regressor
#' If no regressors then provide an empty data.frame.
#'
#' @return a data.frame with the results of the optimisation. In case of error returns the erros message
#' @export
#'
#' @import dplyr dmmfR prophet
#'
optimisation_model_fn <- function(model_name,
                                  workflow,
                                  min_price_ratio,
                                  max_price_ratio,
                                  use_test_data=FALSE,
                                  sim_time_units=6,
                                  time_unit = "days",
                                  start_time=NULL,
                                  target_sales_lst=list(),
                                  base_price=NULL,
                                  base_cost=NULL,
                                  cost_col="COST",
                                  price_col="PRICE",
                                  sales_col = "SALES",
                                  extra_regressors = data.frame()
                                  ){
  init_ptm <- proc.time()
  Optimisation_res <- tryCatch({

    opt_var <- workflow@metadata$opt_var
    logged_price <- workflow@metadata$logged_price
    logged_sales <- workflow@metadata$logged_sales

    # Define Target Sales for the model
    # if target sales is not defined for the model, then it will be an unconstrained problem
    target_sales <- ifelse(model_name %in% names(target_sales_lst), target_sales_lst[[model_name]], -1)
    print(ifelse(target_sales<0,
                 "Running an Unconstrained optimisation problem",
                 "Running a Constrained optimisation problem"))


    # Obtain Model and params -------------------------------------------------
    mod <- workflow@model_factory@models[[model_name]]

    # Filter Data -------------------------------------------------------------
    filter_factors <- unlist(strsplit(model_name, "__"))
    grouping_variables <- workflow@metadata$model_factory$grouping_variables

    if(length(filter_factors) == length(grouping_variables)){
      filter_string <- paste(
        paste0(grouping_variables, '=="', filter_factors, '"'),
        collapse = ' & ')
      train_df <- workflow@data@training_set %>% filter_(filter_string)
    } else{
      throw("Filter factors from models do not have the same length as the grouping variables")
    }

    # Obtain simulation data set ----------------------------------------------
    # Define Simulation data; specify base Cost & Price and Target Sales
    if(use_test_data){
      test_df <- workflow@data@test_set %>%
        filter_(filter_string) %>% tail(sim_time_units)
      sim_df_no_price <- test_set
      sim_df_no_price[opt_var] = 0

      # in case test_df has less than sim_time_units then update sim_time_units
      sim_time_units <- min(sim_time_units, nrow(test_df))

      # base cost/price are based on the test data set if not provided
      base_cost <- if(is.null(base_cost)){test_df[[cost_col]]} else{rep(base_cost,sim_time_units)}
      base_price <- if(is.null(base_price)){test_df[[price_col]]} else{rep(base_price,sim_time_units)}

    } else {
      if(!is.null(start_time)){
        times <- as.POSIXct(start_time) + as.difftime(0:(sim_time_units-1), unit=time_unit)
        sim_df_no_price <- data.frame(ds=times)
      } else {
        sim_df_no_price <- make_future_dataframe(mod, periods = sim_time_units, include_history = FALSE)
        }
      if(nrow(extra_regressors) == nrow(sim_df_no_price)) sim_df_no_price <- cbind(sim_df_no_price, extra_regressors)
      sim_df_no_price[opt_var] <- 0
      # base cost/price are based on the train data set if not provided
      base_cost <- if(is.null(base_cost)){rep(median(train_df[[cost_col]], na.rm=TRUE), sim_time_units)} else{rep(base_cost,sim_time_units)}
      base_price <- if(is.null(base_price)){rep(median(train_df[[price_col]], na.rm=TRUE), sim_time_units)} else{rep(base_price,sim_time_units)}
    }

    # Obtain predictions without price component ------------------------------
    preds_no_price <- predict(mod, sim_df_no_price)[["yhat"]]

    # Obtain price coefficient  -----------------------------------------------
    # generate seasonality features from sample to understand order of all features and match the price feature to the betas
    seasonal.features <- names(prophet:::make_all_seasonality_features(mod, train_df[1,])$seasonal.features)
    betas <- mod$params$beta
    beta_price_pos <- (1:length(seasonal.features))[seasonal.features==opt_var]
    if(length(beta_price_pos) == 0) throw(paste0("Could not find coefficient for the optimisation variable: ", opt_var))

    beta_price <- betas[beta_price_pos] * mod$y.scale

    # Margin function to optimise ---------------------------------------------
    # Constrained (target_sales > 0) or unconstrained (target_sales=-1)
    # 1. if dependent on available stock then the incurred cost is fixed and a constant (no relevant for optimisation)
    #     so margin to optimise is only on the revenue.
    #     If I have 100 units produced and they will get perished in the upcoming 6 weeks. I want to optimise the revenue on them, disregarding on the cost.
    # 2. if no constraints on stock, ie assuming I could produce whatever products needed to meet the demand, then
    #     The margin to optimise should be the revenue - cost of the units (which is a more classical price optimisation)
    margin_optim <- function(x_price, target_sales=-1, extra_output=FALSE){
      preds <- preds_no_price + x_price * beta_price

      demand <- round(if(logged_sales){exp(preds) - 1}else{preds}, 0)
      prices <- if(logged_price){exp(x_price)}else{x_price}

      # if target_sales > 0 then constrained to target sales
      if(target_sales > 0){
        demand_cumsum = cumsum(demand)
        sold_cumsum = pmin(demand_cumsum, target_sales)
        units_sold = c(sold_cumsum[1], diff(sold_cumsum))
      } else {
        units_sold = demand
      }

      # if unit_cost is provided and target sales is not (unconstrained problem)
      margin <- ifelse(target_sales < 0,
                              sum(units_sold * prices) - sum(units_sold * base_cost),
                              sum(units_sold * prices) - target_sales * mean(base_cost))

      revenue <- sum(units_sold * prices)

      if(extra_output) return(list(margin=margin, prices=prices,
                                   demand=demand, units_sold=units_sold,
                                   revenue=revenue))

      return(margin)
    }

    # To optimise wihtout constraints in the price parameter we can use a logistic transformation to create lower/upper bound
    p_transform <- function(pt, l, u, c=0.1){
      (u-l) / (exp(-c*pt) + 1) + l
    }

    neg_margin_optim<- function(p_t, target_sales, lower_p, upper_p){
      return(- margin_optim(p_transform(p_t, l=lower_p, u=upper_p), target_sales, extra_output=FALSE))
    }

    # Parameters for optimisation ----------------------------------------------

    # initial Price Parameters
    init_pars <- rep(-10, sim_time_units)

    # Minimum/Maximum Price Parameters
    if(logged_price){
      min_pars <- ifelse(base_cost == 0, -10, log(base_cost * min_price_ratio))
      max_pars <- log(base_price * max_price_ratio)
    } else{
      min_pars <- base_cost * min_price_ratio
      max_pars <- base_price * max_price_ratio
    }

    # Run Optimisation --------------------------------------------------------
    opt_ptm <- proc.time()
    # Mode #1
    # res <- optim(
    #   par = init_pars,
    #   fn = margin_optim,
    #   target_sales=target_sales,
    #   method = 'L-BFGS-B',
    #   lower = min_pars,
    #   upper = max_pars,
    #   control=list(
    #     fnscale=-1,
    #     maxit=2000)
    # )
    res <- nlm(
      p = init_pars,
      f = neg_margin_optim,
      lower_p=min_pars,
      upper_p=max_pars,
      target_sales=target_sales
    )
    opt_time <- proc.time() - opt_ptm

    print(paste0("It took: ", round(opt_time["elapsed"], 3), " seconds for optimisation"))
    # Output for optimised price
    optimised_output <- margin_optim(p_transform(res$estimate, min_pars, max_pars), target_sales=target_sales, extra_output = TRUE)

    # Output for actual price
    actual_prices_transf <- if(logged_price){log(base_price)}else{base_price}
    actual_price_output <- margin_optim(actual_prices_transf, target_sales=target_sales, extra_output = TRUE)

    # Save Optim results ------------------------------------------------------
    if(logged_price){
      min_prices <- exp(min_pars)
      max_prices <- exp(max_pars)
    } else{
      min_prices <- min_pars
      max_prices <- max_pars
    }

    if(use_test_data){
      # Actual_value depends if problem is (1) unconstrained or (2) constrained
      test_df_actual_value <- ifelse(target_sales < 0,
                             sum(test_df[sales_col] * actual_price_output$prices) - sum(test_df[sales_col] * base_cost),
                             sum(test_df[sales_col] * actual_price_output$prices))
    } else{test_df_actual_value <- NA}

    data.frame(ds=sim_df_no_price$ds,
               min_prices=min_prices,
               max_prices=max_prices,
               optim_prices=optimised_output$prices,
               actual_prices=actual_price_output$prices,
               margin_optim_price=optimised_output$margin,
               margin_actual_price=actual_price_output$margin,
               revenue_optim_price=optimised_output$revenue,
               revenue_actual_price=actual_price_output$revenue,
               demand_optim_price=optimised_output$demand,
               demand_actual_price=actual_price_output$demand,
               units_sold_optim_price=optimised_output$units_sold,
               units_sold_actual_price=actual_price_output$units_sold,
               target_sales=target_sales,
               test_df_actual_value = test_df_actual_value,
               base_cost = base_cost)
  }, error = function(e) {
    print("error")
    return(e$message)
  })

  exec_time <- proc.time() - init_ptm
  print(paste0("Model ", model_name, " took ", round(exec_time["elapsed"],3), "sec for execution time"))

  return(Optimisation_res)
}


