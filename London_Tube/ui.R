#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(shinydashboard)
library(leaflet)
############################## CREATE THE SIDEBAR ##############################
header <- dashboardHeader(
    title="LONDON TUBES",
    disable = FALSE # if true dont display header bar
)

############################## CREATE THE SIDEBAR ##############################
sidebar <- dashboardSidebar(
    # Logo in sidebar menu
    div(
        style = "position: fixed; bottom: 35px; left: 35px;",
        img(src = 'new_logo.png', width = 197)
    ),
    
    sidebarMenu(
        menuItem(
            text = "Introduction (inactive)", #text to show in menu item
            tabName = "intro_tab",
            icon = NULL  #icon to be displayed
            
        ),
        menuItem(
            text = "Demo (inactive)", #text to show in menu item
            tabName = "demo_tab",
            icon = NULL  #icon to be displayed
            
        )
        
    )
)

############################## CREATE THE BODY ##############################
body <- dashboardBody(
    sidebarLayout(
        sidebarPanel(
            selectInput(
                "select_source",        #input_id
                "Select source station",      #label
                choices = c("101 Bowes Park"=101, "15 Alexandra Palace"=15, "601 Peckham Rye"=601),
                selected = NULL
            ),
            
            selectInput(
                "select_dest",
                "Select destination station",
                choices = c("101 Bowes Park"=101, "15 Alexandra Palace"=15, "601 Peckham Rye"=601),
                selected = NULL # initially selected value ,otherwise we can put 605
            ),
            
            actionButton("path_btn", "Find shortest path"),
            actionButton("map_btn", "Plot The Map")
        ),
        
        # Show a plot of the generated distribution
        mainPanel(
            
            leafletOutput("mymap",height = 300),
            textOutput("path")
        )
    )
)

#################### PUT THEM TOGETHER INTO A DASHBOARDPAGE ####################
dashboardPage(
    header,
    sidebar,
    body,
    title = NULL,  # it'll fetch title from dashboardHeader
    skin = c("blue")
)


