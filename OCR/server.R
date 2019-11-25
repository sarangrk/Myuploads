Sys.setenv(RETICULATE_PYTHON="/home/muddassir/anaconda2/envs/acu/bin")
shinyServer(function(input, output, session) {
  
  options(shiny.maxRequestSize = 30*1024^2)

########################### CALL EACH OF THE MODULES ###########################
  tab_intro_server(input, output, session)
  tab_demo_server_ocr(input, output, session)
  tab_demo_server_bevmo(input, output, session)
})