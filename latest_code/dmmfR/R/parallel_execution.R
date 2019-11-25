#' Generic function to run parallelised lapply and bind according to arbitrary binding functions
#'
#' @param dat a data frame
#' @param variables vector of variables to iterate over in lapply
#' @param fun function to apply at each iteration
#' @param binding_fn function to bind the individual list elements together with e.g. bind_rows
#' @param cores number of processor cores to assign to the task
#' @param \dots arguments to be passed to fun
#'
#' @return a dataframe or object returned from binding_fn
parallel_bind <- function(dat, variables, fun,
                          binding_fn = dplyr::bind_rows, cores = .MMoptions$cores, ...){
 if(.Platform$OS.type != 'unix')
   {
   message('Parallel mode not available on Windows! Running single threaded')
   cores <- 1
  }
  binding_fn(parallel::mclapply(variables, function(v) fun(dat, v, ...),
                                mc.cores = cores))
}






