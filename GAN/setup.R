Sys.setenv(PATH = "usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/home/muddassir/anaconda2/bin")
install.packages('gridExtra', dependencies = TRUE)
install.packages('shinyFiles', dependencies = TRUE)
install.packages('rsconnect', dependencies = TRUE)

Sys.setenv(RETICULATE_PYTHON="/home/muddassir/anaconda2/bin/python2.7")
if(!require(reticulate))      {install.packages('reticulate', dependencies = TRUE);require(reticulate)}
library('reticulate')
print (py_config())