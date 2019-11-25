############################## CREATE THE SIDEBAR ##############################
sidebar <- dashboardSidebar(
  sidebarMenu(
    id = 'navpage',
    menuItem("Intro", tabName = "intro", icon = icon("home")),
    menuItem("Demo_OCR", tabName = "demo1", icon = icon("search")),
    menuItem("Demo_bevmo", tabName = "demo2", icon = icon("search"))
    
  ),
  
  div(style = "position: fixed; bottom: 0px; padding: 15px; margin:auto;",
   # img(src = 'tb_images/tb_logo.png', width = 200, style='padding-left: 26px;')
    img(src = '', width = 200, style='padding-left: 26px;')
    
  )
)

############################### CREATE THE BODY ################################
#body <- dashboardBody(
 # tags$head(
  #  tags$link(rel = "stylesheet", type = "text/css", href = "AdminLTE.min.css"),
   # tags$link(rel = "stylesheet", type = "text/css", href = "_all-skins.min.css"),
    #tags$link(rel = "stylesheet", type = "text/css", href = "skin-yellow.min.css"),
    #tags$link(rel = "stylesheet", type = "text/css", href = "skin-yellow.min.css"),
    #tags$link(rel = "stylesheet", type = "text/css", href = "skin-black.min.css"),
    #tags$link(rel = "shortcut icon", href = "favicon.ico"),
    #tags$link(rel = "shortcut icon", href = "https://www.thinkbiganalytics.com/wp-content/uploads/2016/09/14TDPRD223_Think_Big_Logo_F-150x147.png")
  #),
body <- dashboardBody(
    tags$head(
      tags$link(rel = "stylesheet", type = "text/css", href = "AdminLTE.min.css"),
      tags$link(rel = "stylesheet", type = "text/css", href = "_all-skins.min.css"),
      #tags$link(rel = "stylesheet", type = "text/css", href = "skin-yellow.min.css"),
      tags$link(rel = "stylesheet", type = "text/css", href = "skin-black.min.css"),
      tags$link(rel = "stylesheet", type = "text/css", href = "gallery.css"),
      tags$link(rel = "shortcut icon", href = "favicon.ico")
    ),  
  

  # Write the UI reference of the modules
  tabItems(
   tabItem(tabName = "intro", tab_intro_ui("intro")),
    tabItem(tabName = "demo1", tab_demo_ui_ocr("demo1"))
  # tabItem(tabName = "bev", bevmo_demo_ui_bevmo("bev"))
    ,tabItem(tabName = "demo2", tab_demo_ui_bevmo("demo2"))
    
  )
)

#################### PUT THEM TOGETHER INTO A DASHBOARDPAGE ####################
#dashboardPage(
 # skin = "yellow",
  #dashboardHeader(title = "Text Extraction Demo",
   #               titleWidth = 300),
  #sidebar,
  #body
#)


dbHeader <- dashboardHeader()
dbHeader$children[[2]]$children <-  tags$a(href='https://www.teradata.com',
                                           tags$img(src='tb_images/Teradata_logo-two_color_reversed.png',height='60',width='200'))

dashboardPage(skin = "black",
              dbHeader,            
              sidebar,
              body,
              title = "OCR "
)




