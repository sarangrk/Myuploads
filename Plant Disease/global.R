################################ LOAD LIBRARIES ################################
if(!require(shiny))           {install.packages('shiny', dependencies = TRUE);require(shiny)}
if(!require(shinyjs))         {install.packages('shinyjs', dependencies = TRUE);require(shinyjs)}
if(!require(shinyBS))         {install.packages('shinyBS', dependencies = TRUE);require(shinyBS)}
if(!require(shinydashboard))  {install.packages('shinydashboard', dependencies = TRUE);require(shinydashboard)}
if(!require(grid))  {install.packages('grid', dependencies = TRUE);require(grid)}
if(!require(gridExtra))  {install.packages('gridExtra', dependencies = TRUE);require(gridExtra)}
if(!require(jpeg))  {install.packages('jpeg', dependencies = TRUE);require(jpeg)}
if (!require (shinyFiles)) {install.packages('shinyFiles', dependencies = TRUE);require(shinyFiles)}

if(!require(reticulate))      {install.packages('reticulate', dependencies = TRUE);require(reticulate)}

################################# LOAD MODULES #################################
my_modules <- list.files("tabs", pattern = "tab_module.*\\.R", full.names = T,
                         recursive = T)

for(my_module in my_modules) source(my_module)

source("helpers.R")
