#' simple variable audit
#'
#'
#' This function allows you to calculate basic metrics on each variable of a dataset.
#' It evaluates one single variable at a time
#'
#' @param dat data.table - analytical data set containing the target and the explicative variables
#' @param variable a string or a number defining a column to run through audit
#'
#' @return The result is a 1-row data.table with 16 columns:
#' \itemize{
#' \item name_var - the name of the variable audited
#' \item varClass - the class of the variable audited
#' \item unique_values - number of unique values of the variable audited
#' \item pct_numeric - \% of rows consisting of only numbers or "-"
#' \item pct_na -  \% of NA values
#' \item pct_num_or_na - \% of NA values or rows rows consisting of only numbers or "-"
#' \item pct_null - \% of NULL values
#' \item pct_0 - \% of 0 values
#' \item list_values - first 5 unique values of the column
#' \item sums - sum
#' \item med - median
#' \item mea - mean
#' \item std - standard deviation
#' \item minimum - minimum
#' \item maximum - maximum
#' \item Flevels - "Levels of text variables (character or factor), "num" for numeric variables
#' }
#'
#' @keywords binomial univariate
#' @export
#'
#'
audit <- function(dat, variable) {

  variable <- ifelse(!length(variable)==1, variable[1], variable) #takes only the first variable
  #d   <- dat[, .SD, .SDcols = n][[1]]
  d <- dplyr::select(dat, variable)[[1]]
  varname<- ifelse(class(variable)=="numeric",colnames(dat)[variable], variable)

  numtest <- sum(ifelse(grepl("^[0-9.\\-]*$", d) == TRUE, 1, 0))
  natest <- sum(ifelse(is.na(d) == TRUE, 1, 0))
  nulltest <- sum(ifelse(is.null(d) == TRUE, 1, 0))
  test0  <- sum(ifelse(d == 0, 1, 0), na.rm = TRUE)

  length_d <- nrow(dat)

  valuesList <- ifelse(length(unique(d)) > 5,
                       paste((unique(d))[1:5], sep = '', collapse = ";"),
                       paste((unique(d)), sep = '', collapse = ";"))

  if(class(d) %in% c("character","factor")) {
    d <- as.factor(d)
    l <- paste(levels(d), collapse = '|')
  } else {
    l <- 'num'
  }

  dplyr::data_frame(
    name_var = varname,
    varClass = class(d),
    unique_values = length(unique(d)),
    pct_numeric = numtest / length(d),
    pct_na = natest / length_d,
    pct_num_or_na = (numtest + natest) / length_d,
    pct_null = nulltest / length_d,
    pct_0 = ifelse(is.numeric(d) == TRUE, (test0 / length_d), 0),
    list_values = valuesList,
    sums = ifelse(is.numeric(d) == TRUE, sum(as.numeric(d), na.rm = TRUE), 0),
    med = ifelse(is.numeric(d) == TRUE, median(as.numeric(d), na.rm = TRUE), 0),
    mea = ifelse(is.numeric(d) == TRUE, mean(as.numeric(d), na.rm = TRUE), 0),
    std = ifelse(is.numeric(d) == TRUE, sd(as.numeric(d), na.rm = TRUE), 0),
    minimum = ifelse(is.numeric(d) == TRUE, min(as.numeric(d), na.rm = TRUE), 0),
    maximum = ifelse(is.numeric(d) == TRUE, max(as.numeric(d), na.rm = TRUE), 0),
    Flevels = l
  )
}



#' Runs a variable audit on all variables
#'
#' @export
#'
#' @param workflow object of class ModelWorkflow
#' @param variables vector of variables
#' @param \dots arguments to be passed on to the audit function
audit_variables <- function(workflow, variables, ...) {
  UseMethod("audit_variables")
}

#' @export
audit_variables.ModelWorkflow <- function(workflow, variables = NULL, ...){
  if(is.null(variables)){
    variables <- names(workflow@data@raw_data)
  }
  message('Generating variable audit table')
  workflow@data@audit <- parallel_bind(workflow@data@raw_data, variables, audit, ...)
  workflow
}


#' Use the audit to reduce the numbers of feartures
#'
#' More can be added here
#'
#' @param audit data.frame the audit table
#' @param features character vector of features
#'
#' @return character vector of audited features
select_audit_features <- function(audit, features){
  intersect(with(audit, audit[unique_values > 1, 'name_var', drop = TRUE]), features)
}
