shinyServer(function(input, output, session) {

########################### CALL EACH OF THE MODULES ###########################

  callModule(hello_tab_server, "hello_tab")
  #train_model_running <- callModule(trainmodel_tab_server, "trainmodel_tab")   ### to disable button 
  #callModule(product_tab_server, "product_tab", train_model_running)           ### to disable button 
  callModule(product_tab_server, "product_tab")
  callModule(PE_tab_server, "PE_tab")
  callModule(trainmodel_tab_server, "trainmodel_tab")
  callModule(forecast_tab_server, "forecast_tab")
  callModule(liquidation_tab_server, "liquidation_tab")
  callModule(liquidation_tab_cluster_server, "liquidation_tab_cluster")
  
  session$onSessionEnded(function() {
    stopApp()
  })

})
