#' Interpolate missing days from a daily time series
#'
#' This function extends the time series to the full extent of the
#' minimum and maximum values and interpolated the values in a flexible way.
#' The data frame must have a ds column of dates
#'
#'
#' @param ts_dat data.frame of ts data with dates to be interpolated
#' @param interp named vector with the names being the columns to be interpolated the values are the type of interpolation (see details)
#' @param \dots arguments to be passed to the interpolation function
#'
#' @return a data frame with missing values interpolated
#' @export
#'
#' Types of interpolate are 'linear', 'spline', other generic function names are also supported
#' such as 'mean' and 'median'
#'
#' @importFrom dplyr data_frame
#' @importFrom zoo na.approx na.spline
#'
interpolate_ts_data <- function(ts_dat, interp, ...){
  ts_start <- min(ts_dat$ds)
  ts_stop <- max(ts_dat$ds)

  full_ts <- data_frame(ds = seq.Date(ts_start, ts_stop, by = 'day'))

  ts_out <- left_join(full_ts, ts_dat, by = 'ds')

  for(v in names(interp)){
    if(interp[v] == 'linear'){
      ts_out[[v]] <- na.approx(ts_out[[v]])
    } else if(interp[v] == 'spline'){
      ts_out[[v]] <- na.spline(ts_out[[v]])
    } else {
      ts_out[[v]][is.na(ts_out[[v]])] <- get(interp[v])(ts_out[[v]], ...)
    }
  }
  ts_out
}

#' Applies interpolation to the raw data slot in a workflow
#'
#' @param workflow a workflow object
#' @param interp named vector with the names being the columns to be interpolated the values are the type of interpolation (see `interpolate_ts_data`)
#' @param \dots arguments to be passed to the interpolation function
#' @return a workflow object
#'
#'
#' @seealso interpolate_ts_data
#' @export
interpolate_raw_data <- function(workflow, interp, ...){
  UseMethod('interpolate_raw_data')
}

#' @export
interpolate_raw_data.ModelWorkflow <- function(workflow, interp, ...){
  assertthat::assert_that(nrow(workflow@data@raw_data) > 0)
  message('Interpolating missing data')
  workflow@data@raw_data <- interpolate_ts_data(workflow@data@raw_data, interp, ...)
  workflow
}


