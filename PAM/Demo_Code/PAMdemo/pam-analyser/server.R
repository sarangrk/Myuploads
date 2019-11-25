shinyServer(function(input, output, session) {

########################### CALL EACH OF THE MODULES ###########################

  
  callModule(dataLoadTab, "tab_data")
  callModule(trainingTab, "tab_training", reactive(input$navpage))
  callModule(kaplanTab, "tab_kaplan", reactive(input$navpage))
  callModule(failuresTab, "tab_failures", reactive(input$navpage))
  callModule(causesTab, "tab_causes")
  callModule(optimiseTab, "tab_optimisation", reactive(input$navpage))
  callModule(resultsTab, "tab_results", reactive(input$navpage))
  callModule(paretoTab, "tab_pareto", reactive(input$navpage))
  
  session$onSessionEnded(function() {
    stopApp()
  })
})

