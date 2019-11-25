shinyServer(function(input, output, session) {
  
  options(shiny.maxRequestSize = 30*1024^2)

########################### CALL EACH OF THE MODULES ###########################
  tab_intro_server(input, output, session)
  tab_demo_server(input, output, session)
})