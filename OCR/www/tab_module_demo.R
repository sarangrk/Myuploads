# Shiny data module
library(grid)
library(shiny)
library(gridExtra)
library(lattice)
library(jpeg)
library(shiny)
library(DT)
library(shinyFiles)
library(reticulate)


# UI function
tab_demo_ui <- function(id) {
  
  # Build UI
  
  # Load data
  fluidPage(
  
    # App title ----
    titlePanel("Text Extraction Demo"),
    
    br(),
    br(),
    
    fluidRow(
      column(8,
             actionButton("start", "Start Demo", icon("cogs"), 
                          style="color: #fff; background-color: darkorange; width: 100%; max-width: 250px; margin-left: auto; margin-right: auto; display: block;")
      )
    ),
    
    conditionalPanel(sprintf("input['%s']!=0", "start"),

         
        fluidRow(
          column(8,
                 #fileInput("file1", "Choose Form image", accept = c("image/jpeg", ".jpg; .jpeg")),
                   wellPanel(
                  tags$div(class="form-group shiny-input-container", 
                           tags$div(style="color: green; ", h3("Load Form")),
                           tags$div(style="display: inline-block;vertical-align:top;", shinyDirButton('directory', 'Folder select', 'Please select a folder')),
                           tags$div(style="color: green; ",textOutput("dirP"))
                          
                           
                  )),
                 
                 actionButton("find_image", "Scan the Form", icon("cog"), 
                              style="color: #fff; background-color: green; width: 100%; max-width: 250px; margin-left: auto; margin-right: auto; display: block;")
          )
      )
    ),
    
    
    
    conditionalPanel(sprintf("input['%s']!=0", "find_image"),
    br(),
    br(),
     h3("Input Image"),
     fluidRow(column(4,offset=2,imageOutput("plot1"))),
      h3("Extracted Text"),
    wellPanel(fluidRow(column(4,offset=2,textOutput("res")))))
  )
}







# Server function
tab_demo_server <- function(input, output, session) {
  
volumes <- getVolumes()

shinyDirChoose(input, 'directory', roots=volumes, session=session)


path1 <<- reactive({
      inDir <- input$directory

      if (is.null(inDir))
       return(print("No folder selected yet..."))
      
      return(print(parseDirPath(volumes, input$directory)))
   })

  output$dirP <- renderText(path1())
   



  observeEvent(input$find_image, {
    
      detect_python <<- import_from_path("MainScript")
      dirpath1 <<- path1()
      dirpath <<- paste(dirpath1,'/',sep="")
   
      output$res <- renderText({
      res <<- detect_python$process(dirpath)
      paste(res)
    
    
      
  })
  
   filelist <- list.files(path =  dirpath, pattern = "*.jpg|*.jpeg", full.names = TRUE)
   
   file <- paste(dirpath, filelist[1],sep="")
  
  })
  
  
   qfile <- reactive({
     inFile <- input$file1
     
     return(inFile$datapath)
   })
  
  
    output$plot1 <- renderImage({
       
       filelist <- list.files(path =  path1(), pattern = "*.jpg|*.jpeg", full.names = TRUE)
   
   file <- filelist[1]
   
       
      filename = file
      
      img <- readJPEG(filename)
      x <- dim(img)
      height <- x[[1]]
      width <- x[[2]]
      
      pixelratio <- height/width
      
      if (pixelratio > 0.5) {
      nheight <- 250
      nwidth <- nheight/pixelratio
      } else {
      nwidth <- 500
      nheight <- nwidth * pixelratio
      }
      
      # Return a list containing the filename
      list(src = filename,
         width = nwidth,
         height = nheight,
         alt = "This is alternate text")
      }, deleteFile = FALSE)
}
