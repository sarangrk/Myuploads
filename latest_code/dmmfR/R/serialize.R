#' A function to pack models in a character string
#'
#' This function allows you to transform a model object to a character string
#' to be loaded into a sql db
#' @param object object you want to serialize
#' @param verbose logical print extra details on the serialized object
#' @keywords serialize
#' @export
#'
pack_object <- function(object, verbose = FALSE) {
  object <- base64enc::base64encode(memCompress(serialize(object, NULL, ascii = TRUE), type='xz'))
  if(verbose) print(object.size(object))
  object
}


#' Unserialize objects
#' @param object you want to unserialize
unpack_object <- function(object) {
  object <- unserialize(memDecompress(base64enc::base64decode(object), type='xz'))
  object
}



#' Serialize a model object to a character string if serialize_object is TRUE,
#' otherwise just return the object wrapped in a list
#' @param object any R object
#' @param serialize_object logical should the object be serialised?
#' @param verbose logical print extra details on the serialized object
#'
#'You wrap the object in a list so it can be stored in a single cell in a data frame
#'
#'
auto_serialize <- function(object, serialize_object = FALSE, verbose = FALSE){
  if(serialize_object){
    pack_object(object, verbose)
  } else {
    list(object)
  }
}


