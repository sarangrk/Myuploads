
# This is the server logic for a Shiny web application.
# You can find out more about building applications with Shiny here:
#
# http://shiny.rstudio.com
#

#library(shiny)
#library(rPython)

shinyServer(function(input, output, session) {
  tab_intro_server(input, output, session)
  #tab_datainput_server(input, output, session)
  #tab_training_server (input, output, session)
  tab_demo_server(input, output, session)
  #tab_optimization_server(input, output, session)
})