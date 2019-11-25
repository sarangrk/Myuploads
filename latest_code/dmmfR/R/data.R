#' Simulated sales data over 3 years.
#'
#' A dataset containing the sales for 45 products and 12 stores.
#'
#' @format A data frame with 591300 rows and 7 variables:
#' \describe{
#'   \item{ds}{date}
#'   \item{y}{log(sales)}
#'   \item{log_price}{log(price)}
#'   \item{SNOW}{binary variable signifying whether it was snowing}
#'   \item{PRODUCT}{product id}
#'   \item{SHOP}{shop id}
#'   \item{ROTATION_CLASS}{rotation class of product, low, medium or high}
#' }
#' @source Simulation using simpy.
"salesdata"
