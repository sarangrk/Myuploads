#http://fontawesome.io/icons/

############################## CREATE THE SIDEBAR ##############################
sidebar <- dashboardSidebar(
  sidebarMenu(
    # menuItem("How to use this App", tabName = "Tab0", icon = icon("info-circle")),
    menuItem("Train/Test", tabName = "Tab0", icon = icon("columns")),
    menuItem("Filter Variables", tabName = "Tab1", icon = icon("filter")),
    menuItem("Coarse Classing",  icon = icon("object-group"),
             menuSubItem("Processing",  tabName = "Tab2", icon = icon("wrench")),
             menuSubItem("Coarse Classing Results",  tabName = "Tab3", icon = icon("th")),
             startExpanded = TRUE)
    ,menuItem("Modeling",  icon = icon("sitemap"),
             menuSubItem("WoE Conversion",  tabName = "Tab4", icon = icon("exchange"))
             ,menuSubItem("Model Creation",  tabName = "Tab5", icon = icon("list-alt"))
             ,menuSubItem("Model Diagnostics",  tabName = "Tab6", icon = icon("stethoscope"))
             ,menuSubItem("Scorecard",  tabName = "Tab7", icon = icon("id-card"))
             ,startExpanded = TRUE)
    # menuItem("Coarse Classing Results",  tabName = "Tab3", icon = icon("th"))
  ),
  
  # Logo in sidebar menu
  div(style = "position: fixed; bottom: 35px; left: 35px;",
      img(src = 'tb_images/new_logo.png', width = 197)
  )
)

error_hide <- NULL
if (Sys.getenv(c("DEBUG")) != "TRUE") {
  error_hide <- tags$style(type = "text/css",
    ".shiny-output-error { visibility: hidden; }",
    ".shiny-output-error:before { visibility: hidden; }"
  )
}
############################### CREATE THE BODY ################################
body <- dashboardBody(
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "AdminLTE.min.css"),
    tags$link(rel = "stylesheet", type = "text/css", href = "_all-skins.min.css"),
    tags$link(rel = "stylesheet", type = "text/css", href = "skin-yellow.min.css"),
    tags$head(tags$script(src = "message-handler.js")),
    error_hide
  ),
  
  # Write the UI reference of the modules
  tabItems(
     tabItem(tabName = "Tab0", tab0_traintest_ui("tab0"))
    ,tabItem(tabName = "Tab1", tab1_filter_ui("tab1"))
    ,tabItem(tabName = "Tab2", tab2_cc_ui("tab2"))
    ,tabItem(tabName = "Tab3", tab3_ccres_ui("tab3"))
    ,tabItem(tabName = "Tab4", tab4_woe_ui("tab4"))
    ,tabItem(tabName = "Tab5", tab5_model_ui("tab5"))
    ,tabItem(tabName = "Tab6", tab6_md_ui("tab6"))
    ,tabItem(tabName = "Tab7", tab7_sc_ui("tab7"))
  )
)

#################### PUT THEM TOGETHER INTO A DASHBOARDPAGE ####################
dashboardPage(skin = "yellow",
              dashboardHeader(title = "Scorecard Building"),
              sidebar,
              body
)