############################## CREATE THE SIDEBAR ##############################
sidebar <- dashboardSidebar(
  sidebarMenu(
    id = 'navpage',
    menuItem("Introduction", tabName = "intro", icon = icon("home")),
    #menuItem("Data Input", tabName = "datainput", icon = icon("database")),
    #menuItem("Model Training", tabName = "training", icon = icon("flask")),
    menuItem("Demo", tabName = "demo", icon = icon("search"))
    #menuItem("Optimization", tabName = "optimization", icon = icon("rocket"))
  ),
  
  div(style = "position: fixed; bottom: 0px; padding: 15px; margin:auto;",
      img(src = 'tb_images/tb_logo.png', width = 200, style='padding-left: 26px;')
  )
)

############################### CREATE THE BODY ################################
body <- dashboardBody(
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "AdminLTE.min.css"),
    tags$link(rel = "stylesheet", type = "text/css", href = "_all-skins.min.css"),
    tags$link(rel = "stylesheet", type = "text/css", href = "skin-yellow.min.css"),
    tags$link(rel = "stylesheet", type = "text/css", href = "style.css"),
    tags$link(rel = "shortcut icon", href = "https://upload.wikimedia.org/wikipedia/commons/0/0c/Teradata_logo_2018.png")
  ),
  
  # Write the UI reference of the modules
  tabItems(
    tabItem(tabName = "intro", tab_intro_ui("intro")),
    #tabItem(tabName = "datainput", tab_datainput_ui("datainput")),
    #tabItem(tabName = "training", tab_training_ui("training")),
    tabItem(tabName = "demo", tab_demo_ui("demo"))
    #tabItem(tabName = "optimization", tab_optimization_ui("optimization"))
  )
)

#################### PUT THEM TOGETHER INTO A DASHBOARDPAGE ####################
dashboardPage(
  skin = "yellow",
  dashboardHeader(title = "Driver's Sentiment Analytics",
                  titleWidth = 300),
  sidebar,
  body
)