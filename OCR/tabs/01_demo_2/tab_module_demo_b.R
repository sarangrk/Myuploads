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
#bevmo_demo_ui_bevmo <- function(id) {
tab_demo_ui_bevmo <- function(id) {
  
  
  print("bevmo ui")
  
  # Build UI
  # Load data
  fluidPage(
    # App title ----
    titlePanel("Text Extraction Demo"),
    
    br(),
    
    fluidRow(
      column(width=8,
             box(title='Note', width = NULL,
                 p("This will work only on jpg and jpeg form image as given below:")
                ),
             img(src="bevmoC.jpeg", style="max-width: 400px; display:block;")
             )
             ),
    br(),
    fluidRow(
      column(8,
             actionButton("start_b", "Start Demo bevmo test", icon("cogs"), 
                          style="color: #fff; background-color: darkorange; width: 100%; max-width: 250px; margin-left: auto; margin-right: auto; display: block;")
      )
    ),
    br(),
    fluidRow(
      column(8,
             uiOutput("button_pre"),       
             uiOutput("button_1")
             
      )
    ),
    fluidRow(
      h3("Input Image"),
      imageOutput("plot3"),
      h3("Extracted Text"),
      textOutput("res3")
      # #                  fluidRow(column(4,offset=2,imageOutput("plot1"))),
      # #                  h3("Extracted Text"),
      # #                  wellPanel(fluidRow(column(4,offset=2,textOutput("res")))))
    )
    
    
    # conditionalPanel(sprintf("input['",ns("start_b"),"']!=0"),# "start_b"),
    # ##conditionalPanel("input.start_b!=0",# "start_b"),
    #                  fluidRow(
    #                    column(8,
    #                           ##fileInput("file1", "Choose Form image", accept = c("image/jpeg", ".jpg; .jpeg")),
    #                           wellPanel(
    #                             tags$div(class="form-group shiny-input-container", 
    #                                      tags$div(style="color: green; ", h3("Load Form")),
    #                                      tags$div(style="display: inline-block;vertical-align:top;", shinyDirButton('directory', 'Folder select', 'Please select a folder')),
    #                                      tags$div(style="color: green; ",textOutput("dirP"))
    #                             )),
    #                           actionButton("find_image_b", "Scan the Form", icon("cog"), 
    #                                        style="color: #fff; background-color: green; width: 100%; max-width: 250px; margin-left: auto; margin-right: auto; display: block;")
    #                    )
    #                  )
    # ),
    
    # ,conditionalPanel(sprintf("input['%s']!=0", "find_image_b"),
    #                  br(),
    #                  br(),
    #                  h3("Input Image"),
    #                  fluidRow(column(4,offset=2,imageOutput("plot1"))),
    #                  h3("Extracted Text"),
    #                  wellPanel(fluidRow(column(4,offset=2,textOutput("res")))))
  )
}

# Server function
tab_demo_server_bevmo <- function(input, output, session) {
  
  print("server function of bevmo")
  volumes <- getVolumes()
  shinyDirChoose(input, 'directory', roots=volumes, session=session)
  
  path1 <<- reactive({
    inDir <- input$directory
    if (is.null(inDir))
      return(print("No folder selected yet..."))
    return(print(parseDirPath(volumes, input$directory)))
  })
  
  output$dirP <- renderText(path1())
  
  observeEvent(input$start_b, {
    
    output$button_pre <- renderUI({
      #selectInput('directory', 'Folder select', 'Please select a folder')
      fileInput("directory", "Choose File")
    })
    
    #shinyDirChoose(input, 'directory', roots=volumes, session=session)
    
    output$button_1 <- renderUI({
      actionButton("find_image_b", "Scan the Form", icon("cog"), 
                   style="color: #fff; background-color: green; width: 100%; max-width: 250px; margin-left: auto; margin-right: auto; display: block;")
    })
  })
  
  observeEvent(input$directory, {
    if (file.exists("upload_images/0.jpg"))
      file.remove("upload_images/0.jpg")
    file.copy(input$directory$datapath, "upload_images")
  })
  
  observeEvent(input$find_image_b, {
    detect_python <<- import_from_path("MainScript")
    #dirpath1 <<- '/home/kaptan/OCR/upload_images/'
    #dirpath <<- paste(dirpath1,'/',sep="")
    dirpath <<- '/home/kaptan/OCR/upload_images/'
    
    output$res3 <- renderText({
      res3 <<- detect_python$process(dirpath)
      paste(res3)
    })
    
    filelist <- list.files(path =  dirpath, pattern = "*.jpg|*.jpeg", full.names = TRUE)
    file <- paste(dirpath, filelist[1],sep="")
    
    output$plot3 <- renderImage({
      filelist <- list.files(path = '/home/kaptan/OCR/upload_images/', pattern = "*.jpg|*.jpeg", full.names = TRUE)
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
  })
  
  qfile <- reactive({
    inFile <- input$file1
    return(inFile$datapath)
  })
  
  
}
