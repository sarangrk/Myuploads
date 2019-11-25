
# This is the server logic for a Shiny web application.
# You can find out more about building applications with Shiny here:
#
# http://shiny.rstudio.com
#

shinyServer(function(input, output, session) {
  tab_intro_server(input, output, session)
  tab_demo_server(input, output, session)
})