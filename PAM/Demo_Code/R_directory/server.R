server <- function(input,output, session){
  
  data <- reactive({
    x <- df_custom
  })
  
  
  output$pareto_chart <- renderPlot({
    
    # Fitting Labels 
    par(las=2) # make label text perpendicular to axis
    par(mar=c(5,8,4,2)) # increase y-axis margin.
    
    barplot(height = defects$freq, horiz = TRUE, names.arg  = defects$type, xlab = "Frequency")
    
    
  })
  
  
  output$mymap <- renderLeaflet({
    df_custom <- data()
    

  
      
      
      greenLeafIcon <- makeIcon(
        iconUrl = "Truck-512.png",
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

    click <- input$mymap_marker_click
    proxy <- leafletProxy("mymap", data=df_custom)

     proxy  %>% clearMarkers() %>%
        addPolylines( lng = ~Longitude,
                     lat = ~Latitude,
                     group = ~Group)
     
   })

  

  observeEvent(input$mymap_click, {


    greenLeafIcon <- makeIcon(
      iconUrl = "Truck-512.png",
      iconWidth = 30, iconHeight = 30,
      iconAnchorX = 20, iconAnchorY = 20
    )

    proxy <- leafletProxy("mymap", data=df_custom)


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


