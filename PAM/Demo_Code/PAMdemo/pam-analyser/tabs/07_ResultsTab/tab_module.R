# UI for failure models
#' @export
resultsTabUI <- function(id) {
  
  ns <- NS(id)
  
  # Tab consists of Panel with controls and output
  tabPanel(
    results_tab(),
    # tags$head(
    #   includeCSS("stylesleaflet.css"),
    #   includeScript("gomap.js")
    # ),
    h2('Maintenance plan'),
    p("Use the controls below to find which of your assets will need maintenance; these values are automatically updated after you have run the optimisation. Green assets on the map do not need maintenance, but those in red have a failure probability larger than your alarm threshold. To make the map larger you can close the menu using the icon on the top right of the page."),
    fluidRow(
      box(width = 12,
          div(class = 'outer',
              leafletOutput(ns("maintenance_map"), height = '750px'),
              absolutePanel(id = "controls", class = "controls panel panel-default", fixed = FALSE, draggable = TRUE,
                            top = 30, left = 70, right = "auto", bottom = "auto", width = "auto", height = "auto",
                            h3('Model settings', style = 'margin-top:10px'),
                            selectInput(ns("modelSelectTwo"), label="Machine learning model", choices = initial_models),
                            sliderInput(ns("ForecastHorizon"), label="Failure time frame (days)", value = 45, max = 365, min = 0),
                            sliderInput(ns("AlarmThresholdTwo"), label = "Alarm threshold (failure probability)", value = 0.25, max = 1, min = 0),
                            actionButton(ns('create_plan'), 'Create maintenance plan')
              ),
                               absolutePanel(id = "repair_list", class = "controls panel panel-default scroll",
                                             fixed = FALSE, draggable = TRUE,
                                             top = 30, left = "auto", right = 20, bottom = "auto", width = '400', height = "500",
                                             h3('Prioritisation', style = 'margin-top:10px'),
                                             p('Truck with a failure probability greater than the alarm threshold are listed below, ordered by those trucks which are most likely to fail.'),
                                             DT::dataTableOutput(ns("asset_maintenance_plan"))
                               )
              
          )
      )
    )
  )
}


# Server
#' @export
resultsTab <- function(input, output, session, navpage) {

  
  output$asset_maintenance_plan <- DT::renderDataTable({
     df <- data.frame( df_custom[,c("Identifier", "FailureProbability")])
     df
  })
  
  
  
  
  
  
  data <- reactive({
    x <- df_custom
  })
  
  print("load map")
  
  output$maintenance_map <- renderLeaflet({
    df_custom <- data()
    
    
    greenLeafIcon <- makeIcon(
      iconUrl = "C:\\Backup\\R_directory\\Truck-512.png",
      iconWidth = 30, iconHeight = 30,
      iconAnchorX = 20, iconAnchorY = 20
    )
    
    leaflet(data = df_custom) %>%
      addTiles() %>%
      addCircleMarkers(lng = ~Longitude,
                       lat = ~Latitude,
                       color = ~Color,
                       fillOpacity = 1,
                       radius = 5) %>%
      addMarkers(lng = ~Longitude,
                 lat = ~Latitude,
                 layerId = ~Identifier,
                 popup = ~paste("<b>", "TruckID: H21", "<br>"
                                , "Driver: John Smith", "<br>"
                                , "License: ABC 123", "<br>"
                                , "</b></br> 
                                <button onclick='Shiny.onInputChange(\"button_click\",  Math.random())' id='showroute' type='button' class='btn btn-default action-button'>Show Route</button>"),
                                  icon = greenLeafIcon)
    
    
  })
  
  
  observeEvent(input$button_click, {
    
    print("show route")
    
    proxy <- leafletProxy("maintenance_map", data=df_custom)
    
    proxy  %>% clearMarkers() %>%
      addPolylines( lng = ~Longitude,
                    lat = ~Latitude,
                    group = ~Group)
    
  })
  
  
  
  observeEvent(input$maintenance_map_click, {
    
    print(input$button_click)
    
    print("new map")
    
    greenLeafIcon <- makeIcon(
      iconUrl = "C:\\Backup\\R_directory\\Truck-512.png",
      iconWidth = 30, iconHeight = 30,
      iconAnchorX = 20, iconAnchorY = 20
    )
    
    proxy <- leafletProxy("maintenance_map", data=df_custom)
    
    
    proxy  %>% clearShapes() %>%
      addCircleMarkers(lng = ~Longitude,
                       lat = ~Latitude,
                       color = ~Color,
                       fillOpacity = 1,
                       radius = 5) %>%
      addMarkers(lng = ~Longitude,
                 lat = ~Latitude,
                 layerId = ~Identifier,
                 popup = ~paste("<b>", "TruckID: H21", "<br>"
                                , "Driver: John Smith", "<br>"
                                , "License: ABC 123", "<br>"
                                , "</b></br> 
                                <button onclick='Shiny.onInputChange(\"button_click\",  Math.random())' id='showroute' type='button' class='btn btn-default action-button'>Show Route</button>"),
                 icon = greenLeafIcon)
    
    
  })
  
  
  
}

