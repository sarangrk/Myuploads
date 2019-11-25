# set black and white plot theme
theme_set(theme_bw())

sidebar <- shinydashboard::dashboardSidebar(
  sidebarMenu(
    id = 'navpage',
    menuItem("Welcome", tabName = "welcome_page", icon = icon("info-circle")),
    menuItem("Data Input", tabName = "data_page", icon = icon("database")),
    menuItem("Model Training", tabName = "training_page", icon = icon("flask")),
    menuItem("Failures Analysis", tabName = "failures_page", icon = icon("exclamation-triangle")),
    menuItem("Causes Analysis", tabName = "causes_page", icon = icon("cogs")),
    menuItem("Optimisation", tabName = "optimisation_page", icon = icon("rocket")),
    menuItem("Maintenance plan", tabName = "results_page", icon = icon("globe")),
    menuItem("Failure Chart", tabName = "pareto_page", icon = icon("exclamation-triangle"))
  ),
  
  # Logo in sidebar menu
  div(style = "position: fixed; bottom: 35px; left: 35px;",
      img(src = 'Teradata-logo-200x116', width = 197)
  )
)

body <- shinydashboard::dashboardBody(
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "AdminLTE.min.css"),
    tags$link(rel = "stylesheet", type = "text/css", href = "_all-skins.min.css"),
    tags$link(rel = "stylesheet", type = "text/css", href = "skin-yellow.min.css"),
    tags$link(rel = "stylesheet", type = "text/css", href = "style.css"),
    tags$link(rel = "shortcut icon", href = "ThinkBig-logoF-150x147.png"),
    # tags$link(rel = "stylesheet", type = "text/css", href = "stylesleaflet.css"),
    # tags$link(rel = "stylesheet", type = "text/css", href = "gomap.js")
    includeCSS("stylesleaflet.css"),
    includeScript("gomap.js")
  ),
  
  # Write the UI reference of the modules
  tabItems(
    tabItem(tabName = "welcome_page", introTabUI("welcome")),
    tabItem(tabName = "data_page", dataLoadTabUI("tab_data")),
    tabItem(tabName = "training_page", trainingTabUI("tab_training")),
    tabItem(tabName = "failures_page", failuresTabUI("tab_failures")),
    tabItem(tabName = "causes_page", causesTabUI("tab_causes")),
    tabItem(tabName = "optimisation_page", optimiseTabUI("tab_optimisation")),
    tabItem(tabName = "results_page", resultsTabUI("tab_results")),
    tabItem(tabName = "pareto_page", paretoTabUI("tab_pareto"))
  )
)

shinydashboard::dashboardPage(
  skin = "yellow",
  dashboardHeader(title = "PAMalyser"),
  sidebar,
  body
)
