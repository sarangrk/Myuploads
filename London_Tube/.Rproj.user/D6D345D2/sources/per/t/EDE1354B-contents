shiny::shinyServer(function(input, output, session) {

  ########################### CALL EACH OF THE MODULES #####################
  td_schema <- shiny::reactiveVal(td_schema)
  td_ids <- shiny::reactiveVal(td_ids)

  shiny::callModule(tab0_traintest_server, "tab0", td_schema, td_ids)
  vars_selected <<- shiny::callModule(tab1_filter_server, "tab1", td_ids)
  cc_results <- shiny::callModule(tab2_cc_server, "tab2", td_ids)
  shiny::callModule(tab3_ccres_server, "tab3", cc_results, td_ids)
  woe_data <- shiny::callModule(tab4_woe_server, "tab4", td_ids)
  res <- shiny::callModule(tab5_model_server, "tab5", woe_data, td_ids)
  shiny::callModule(tab6_md_server, "tab6", res, td_ids)
  shiny::callModule(tab7_sc_server, "tab7", res, woe_data, td_schema, td_ids)

})
