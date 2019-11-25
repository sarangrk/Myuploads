############################## CREATE THE SIDEBAR ##############################
sidebar <- dashboardSidebar(
  sidebarMenu(
    id = 'navpage',
    menuItem("Intro", tabName = "intro", icon = icon("search")),
    menuItem("Demo", tabName = "demo", icon = icon("search"))
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
    tags$link(rel = "shortcut icon", href = "https://www.thinkbiganalytics.com/wp-content/uploads/2016/09/14TDPRD223_Think_Big_Logo_F-150x147.png")
  ),
  
  # Write the UI reference of the modules
  tabItems(
    tabItem(tabName = "intro", tab_intro_ui("tab_intro_ui")),
    tabItem(tabName = "demo", tab_demo_ui("demo"))
  )
)

#################### PUT THEM TOGETHER INTO A DASHBOARDPAGE ####################
dashboardPage(
  skin = "yellow",
  dashboardHeader(title = "Plant Disease Detection",
                  titleWidth = 300),
  sidebar,
  body
)