if (!require(shiny)) {
  install.packages("shiny", repos = "https://cran.ism.ac.jp/")
  require(shiny)
}
if (!require(plotly)) {
  install.packages("plotly", repos = "https://cran.ism.ac.jp/")
  require(plotly)
}
if (!require(dplyr)) {
  install.packages("dplyr", repos = "https://cran.ism.ac.jp/");
  require(dplyr)
}
if (!require(ggplot2)) {
  install.packages("ggplot2", repos = "https://cran.ism.ac.jp/");
  require(ggplot2)
}
if (!require(viridisLite)) {
  install.packages("viridisLite", repos = "https://cran.ism.ac.jp/");
  require(viridisLite)
}
if (!require(shinydashboard)) {
  install.packages("shinydashboard", repos = "https://cran.ism.ac.jp/");
  require(shinydashboard)
}
if (!require(reshape2)) {
  install.packages("reshape2", repos = "https://cran.ism.ac.jp/");
  require(reshape2)
}
if (!require(e1071)) {
  install.packages("e1071", repos = "https://cran.ism.ac.jp/")
  require(e1071)
}
if (!require(rhandsontable)) {
  install.packages("rhandsontable", repos = "https://cran.ism.ac.jp/")
  require(rhandsontable)
}
if (!require(pROC)) {
  install.packages("pROC", repos = "https://cran.ism.ac.jp/")
  require(pROC)
}
if (!require(ROCR)) {
  install.packages("ROCR", repos = "https://cran.ism.ac.jp/")
  require(ROCR)
}
if (!require(caret)) {
  install.packages("caret", repos = "https://cran.ism.ac.jp/")
  require(caret)
}
if (!require(DBI)) {
  install.packages("DBI", repos = "https://cran.ism.ac.jp/")
  require(DBI)
}
if (!require(odbc)) {
  install.packages("odbc", repos = "https://cran.ism.ac.jp/")
  require(odbc)
}
if (!require(plotly)) {
  install.packages("plotly", repos = "https://cran.ism.ac.jp/")
  require(plotly)
}
if (!require(splitstackshape)) {
  install.packages("splitstackshape", repos = "https://cran.ism.ac.jp/")
  require(splitstackshape)
}
if (!require(DT)) {
  install.packages("DT", repos = "https://cran.ism.ac.jp/")
}
if (!require(data.table)) {
  install.packages("data.table", repos = "https://cran.ism.ac.jp/")
}

library(RODBC)
library(tdplyr)
library(dplyr)
library(odbc)
library(dbplyr)
library(DBI)
library(loggit)
setLogFile("/Users/sk186089/Desktop/log.json")
loggit("INFO", "app has started", app = "start")


# JAPAN_DAP default
td_tables <- c(
  bin_sample_tbl = "tbl_account_srs_binned",
  iv_table_tbl = "tbl_sample_iv_rank",
  fine_class_labels_tbl = "tbl_var_fine_bins",
  coarse_class_tbl = "tbl_coarse_classes_seg",
  coarse_class_woe_tbl = "tbl_coarse_classes_woe_seg",
  hierarchy_tbl = "tbl_variable",
  scorecard_tbl = "tbl_seg_scorecard",
  segment_tbl = "tbl_segment",
  segment_group_tbl = "tbl_segment_groups",
  acct_segment_tbl = "tbl_acct_segment",
  sampling_weight_view = "vw_sampling_weight"
)

td_schema <- Sys.getenv(c("TD_SCHEMA"))

if (td_schema == "") {
  td_schema <- "JAPAN_DAP"
}

print(paste0("Using schema: ", td_schema))

td_ids <- lapply(td_tables, function(x) DBI::Id(
  schema  = td_schema,
  table   = x
))

charts_savedir <- "output_charts"
charts_woe_savedir <- "output_charts"

################################# LOAD MODULES #################################

my_modules <- list.files(
  "newtabs",
  pattern = "tab_module*.\\.R",
  full.names = TRUE,
  recursive = TRUE
)
print(my_modules)

driver_location <- Sys.getenv("TD_DRIVER")

# default to osx path
if (driver_location == "") {
  driver_location <-
    "/Library/Application Support/teradata/client/16.20/lib/tdataodbc_sbu.dylib"
}

con <- DBI::dbConnect(odbc::odbc(),
  dsn='Teradata_Vantage',
  DBCName='tdap790t1.labs.teradata.com',
  #Driver = driver_location,
  #DBCName = "153.65.122.42",
  UID = "GDCDS",
  PWD = "GDCDS",
  database="JAPAN_DAP",
  mode='ANSI',
  encoding='UTF-8')

td_set_context(con)
#con <- td_create_context(dsn="Teradata_Vantage", uid="GDCDS", pwd="GDCDS",database="JAPAN_DAP")

for (my_module in my_modules) source(my_module)

if (Sys.getenv(c("DEBUG")) != "TRUE") {
  options(shiny.sanitize.errors = TRUE)
}
