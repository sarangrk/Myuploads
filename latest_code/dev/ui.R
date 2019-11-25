############################## CREATE THE SIDEBAR ##############################
sidebar <- dashboardSidebar(
  sidebarMenu(id='sidebarmenu',
              menuItem("Demo Information", tabName = "hello_tab", icon = icon("info-circle")),
              menuItem("Product Information", tabName = "product_tab", icon = icon("info-circle")),
              menuItem("Train Forecasting Model", tabName = "trainmodel_tab", icon = icon("gears")),
              menuItem("Price Elasticity", tabName = "PE_tab", icon = icon("gears")),
              menuItem("Forecasting Model Performance", tabName = "forecast_tab", icon = icon("line-chart")),
              menuItem("Shop Promo Optimisation", tabName = "liquidation_tab", icon = icon("shopping-cart")),
              menuItem("Cluster Promo Optimisation", tabName = "liquidation_tab_cluster", icon = icon("shopping-cart"))
  )
  
  # Logo in sidebar menu
  #div(style = "position: fixed; bottom: 50px; left: 20px;",
      #img(src = 'tb_images/take_5_logo.png', width = 220)
  #)
)

############################### CREATE THE BODY ################################
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
    tabItem(tabName = "hello_tab", hello_tab_ui("hello_tab")),
    tabItem(tabName = "product_tab", product_tab_ui("product_tab")),
    tabItem(tabName = "trainmodel_tab", trainmodel_tab_ui("trainmodel_tab")),
    tabItem(tabName = "PE_tab", PE_tab_ui("PE_tab")),
    tabItem(tabName = "forecast_tab", forecast_tab_ui("forecast_tab")),
    tabItem(tabName = "liquidation_tab", liquidation_tab_ui("liquidation_tab")),
    tabItem(tabName = "liquidation_tab_cluster", liquidation_tab_cluster_ui("liquidation_tab_cluster"))
  )
)


#################### PUT THEM TOGETHER INTO A DASHBOARDPAGE ####################

dbHeader <- dashboardHeader()
dbHeader$children[[2]]$children <-  tags$a(href='https://www.teradata.com',
                                           tags$img(src='tb_images/Teradata_logo-two_color_reversed.png',height='60',width='200'))

dashboardPage(skin = "black",
              dbHeader,            
              sidebar,
              body,
              title = "Price Optimization"
)


