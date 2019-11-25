################################ LOAD LIBRARIES ################################

if(!require(shiny))           {install.packages('shiny', dependencies = TRUE);require(shiny)}
if(!require(shinyjs))         {install.packages('shinyjs', dependencies = TRUE);require(shinyjs)}
if(!require(shinyBS))         {install.packages('shinyBS', dependencies = TRUE);require(shinyBS)}
if(!require(shinydashboard))  {install.packages('shinydashboard', dependencies = TRUE);require(shinydashboard)}
Sys.setenv(RETICULATE_PYTHON="/home/muddassir/anaconda2/bin/python2.7")
#Sys.setenv(PYTHONHOME = "/opt/anaconda2")
#Sys.setenv(PYTHONPATH="/opt/anaconda2/lib/python2.7")
if(!require(reticulate))      {install.packages('reticulate', dependencies = TRUE);require(reticulate)}

print (py_config())
#print (py_discover_config())
#cv <- import("numpy")
#print(cv$version$version)

################################# LOAD MODULES #################################

my_modules <- list.files("tabs", pattern = "tab_module.*\\.R", full.names = T,
                         recursive = T)

for(my_module in my_modules) source(my_module)

source("helpers.R")
