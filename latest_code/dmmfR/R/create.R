#' Create Metadata
#'
#' @description Creates a default metadata file with initialization
#'
#' @family metadata
#'
#' @param model_name a character string with the name of the model
#' @param model_type a character string specifying the type of the model
#' @param is_model_factory logical
#' @param use_case_name a character string
#' @param use_case_start_dt a dttm string
#' @param use_case_end_dt a dttm string; Default is null
#'
#' @importFrom uuid UUIDgenerate
#'
#' @keywords internal
#'
create_metadata <- function(model_name, model_type, is_model_factory,
                            use_case_name, use_case_start_dt, use_case_end_dt = NULL){

  model_id = uuid::UUIDgenerate()
  id = uuid::UUIDgenerate()

  dt_now = as.character(Sys.time())

  meta = list(
    MetaType = 'Model',
    MetaVersion = '1',
    id = id,
    ModelID = model_id,
    ModelName = model_name,
    ModelType = model_type,
    ModelSource = character(1),
    CreatedDate = dt_now,

    Language = list(Name = version$language,
                    Version = version$version.string),

    Library = list(Name = character(1),
                   Version = character(1)),

    UseCase = list(UseCaseName = use_case_name,
                   UseCaseStartDate = as.character(use_case_start_dt),
                   UseCaseEndDate = as.character(use_case_end_dt)),

    Data = list(DataSource = character(1),
                FeatureVariables = list(Name = character(1),
                                        Type = character(1)),
                TargetVariable = list(Name = character(1),
                                      Type = character(1))),

    ModelHistory = list(ModelState = 'Initialised',
                        StateStartDate = dt_now,
                        StateEndDate = dt_now),

    is_champion = 0,

    ModelTests = list(TestName = character(1),
                      TestDate = character(1),
                      TestScore = character(1),
                      TestDataSource = character(1)),
    ModelWeights = character(1),
    ModelLIME = character(1),
    ModelLogs = character(1),
    ModelScripts = character(1)
  )
  if(is_model_factory){
    meta$model_factory <- list()
    message('Multiple Model Factory mode initialized')
  } else {
    message('Single model mode (Set "is_model_factory" to TRUE for model factory mode)')
  }
  return(meta)

}
