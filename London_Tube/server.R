#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(odbc)
library(RODBC)
library(tdplyr)
library(dplyr)
library(odbc)
library(dbplyr)
library(DBI)

# Define server logic required to draw a histogram
shinyServer(function(input, output) {
  
  data2 <- reactiveValues(
    x = NULL, #<- df[df$code==input$select_source,]
    y = NULL #<- df[df$code==input$select_dest,]
    
  )
    
  
    # output$mymap <- renderLeaflet({
    #     m <- leaflet() %>%     # this %>% is a pipe operator, its connecting things
    #         addTiles() %>%
    #         setView(lng=-0.1278, lat=51.509865 , zoom=12) %>%
    #         addMarkers(lng=-0.1200, lat=51.509800, popup = "source")
    #     
    #     
    #     m
    # })
    
    shiny::observeEvent(input$select_source, {
      data2$x <-  input$select_source  
      # output$in_source <- renderText(input$select_source) # select_source is id from where we want our input
      #   print("inside observeEvent of select_source")
      #   output$mymap <- renderLeaflet({
      #       m <- leaflet() %>%     # this %>% is a pipe operator, its connecting things
      #           addTiles() %>%
      #           setView(lng=-0.1278, lat=51.509865 , zoom=12) %>%
      #           addMarkers(lng=-0.1200, lat=51.509800, popup = "source")
            #m
        })
        # my_loc<-data.frame(lat=double(), long=double())
        # a<-c(1000,-2000)
        # my_loc[nrow(my_loc) + 1,] = a
        # 
        # observe(leafletProxy("m", my_loc) %>%
        #             clearMarkers() %>%
        #             addMarkers()
        #)
        # output$mymap <- renderLeaflet({
        #     m <- addMarkers(mymap,lng=-0.1200, lat=51.509800, popup = "source")
        #     m
        # })
        
        #mymap=addMarkers(mymap,lng=-0.1200, lat=51.509800, popup = "source")
    #})
    
    shiny::observeEvent(input$select_dest, {
      data2$y <- input$select_dest
        # 
        # output$in_des <- renderText(input$select_dest)
        # print("inside observeEvent of select_dest")
        # output$mymap <- renderLeaflet({
            # m <- leaflet() %>%     # this %>% is a pipe operator, its connecting things
            #     addTiles() %>%
            #     setView(lng=-0.1278, lat=51.509865 , zoom=12) %>%
            #     addMarkers(lng=-3.1200, lat=59.509800, popup = "Destination")
            # 
            # 
            #m
       # })
    })
    
    shiny::observeEvent(input$path_btn, {
        
        start_point <- as.numeric(input$select_source)
        end_point <- as.numeric(input$select_dest)
        
        con <- td_create_context(dsn="Vantage", uid="GDCDS", pwd="GDCDS")
        
        SP_stmt <- paste0("CALL GDCDS.VJ_usp_Dijkstra(",start_point,",",end_point,",1,1);")
        #SP_call <- "SEL TOP 1 * FROM GDCDS.STATIONS_SHORT;"
        path_vj_2 <- odbc::dbGetQuery(con,SP_stmt)
        
        df <- data.frame(path_vj_2)
        output$path <- renderText(df$NamePath)
        
        print("stations visited are")
        x <- unlist(strsplit(df$Path, "->"))
        for(i in x)
        {
            print(i)
        }
        
        #print(path_vj)
        #print(path_vj_2)
        print("inside path_btn observeEvent")
        #print(output$path_vj)
    })
    
    observeEvent(input$map_btn, {
      
      output$mymap <- renderLeaflet({
        
        source = df[df$code==data2$x,]
        destination = df[df$code==data2$y,]
        
        
        my_loc[nrow(my_loc) + 1,]=source
        my_loc[nrow(my_loc) + 1,]=destination
        print('My_loc final')
        print(my_loc)
        
        #print(d_stn)
        m <- leaflet(my_loc) %>%     # this %>% is a pipe operator, its connecting things
          addTiles() %>%
          setView(lng=0.1278, lat=51.5074 , zoom=10) %>%
          addMarkers(lng=~longitude,
                     lat=~lattitude,
                     popup = my_loc$place)
        m
      })
      
    })
    
    
    
    #odbc::dbGetQuery(con," SEL TOP 10 * FROM GDCDS.STATIONS_SHORT;")
})
