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
#library(png)


# UI function
tab_demo_ui_ocr <- function(id) {
  
  # Build UI
  
  print("point 1")
  
  
  # Load data
  fluidPage(
    
    # App title ----
    titlePanel("Text Extraction Demo"),
    # print("point 2"),
    br(),
    fluidRow(
      column(width=8,
             box(title='Note', width = NULL,
              p("You can either select multiple images or use the default image."),
              p("This will work only on jpg and jpeg form image as given below:")
             ),
             img(src="13.jpg", style="max-width: 420px; display:block;")
            )
          ),
    br(),
    
    fluidRow(
     
          column(8,
                 actionButton("start", "Start Demo", icon("cogs"), 
                              style="color: #fff; background-color: darkorange; width: 100%; max-width: 250px; margin-left: auto; margin-right: auto; display: block;")
          ),
          uiOutput("show_buttons")
      
    ),
    
    conditionalPanel(sprintf("input['%s']!=0", "start"),
                     
                     #               print("point 3"),
                     fluidRow(
                       column(8,
                              
                              actionButton("sel_form", "Select the Form", icon("cog"), 
                                           style="color: #fff; background-color: green; width: 100%; max-width: 250px; margin-left: auto; margin-right: auto; display: block;")
                              ,
                              
                              actionButton("default", "Use default form", icon("cog"), 
                                           style="color: #fff; background-color: green; width: 100%; max-width: 250px; margin-left: auto; margin-right: auto; display: block;")
                       )
                     ),
                     
                     conditionalPanel(sprintf("input['%s']!=0", "sel_form"),
                                      
                                      
                                      #  fileInput("file1", "Choose Form image", accept = c("image/jpeg", ".jpg; .jpeg")),
                                      wellPanel(
                                        tags$div(class="form-group shiny-input-container", 
                                                 tags$div(style="color: green; ", h3("Load Form")),
                                                 tags$div(style="display: inline-block;vertical-align:top;", shinyDirButton('directory', 'Folder select', 'Please select a folder')),
                                                 tags$div(style="color: green; ",textOutput("dirP"))
                                                 
                                                 
                                        )
                                      ),
                                      actionButton("find_image", "Scan the Form", icon("cog"), 
                                                   style="color: #fff; background-color: green; width: 100%; max-width: 250px; margin-left: auto; margin-right: auto; display: block;")
                                      
                                      
                                      
                     )
                     
    ),
    
    
    
    conditionalPanel(sprintf("input['%s']!=0", "find_image"),
                     br(),
                     br(),
                     #                  print("point 4"),
                     #  h3("Input Image"),
                     #   fluidRow(column(4,offset=2,imageOutput("ip_img"))),
                     h3("Extracted Text"),
                     wellPanel(fluidRow(column(4,DT::dataTableOutput("plot2"))))
    )
    
    ,
    conditionalPanel(sprintf("input['%s']!=0", "default"),
                     #                  print("conditional panel default"),
                     #                  br(),
                     #                  br(),
                     #                  print("point 5"),
                     h3("Input Image"),
                     fluidRow(column(4,offset=2,imageOutput("ip_img"))),
                     h3("Extracted Text"),
                     wellPanel(fluidRow(column(3,DT::dataTableOutput("plot1")))))
    #wellPanel(fluidRow(column(4,offset=2,textOutput("res")))))
    #wellPanel(fluidRow(column(4,DT::dataTableOutput('plot1')))
    #         )
  )
  
}







# Server function
tab_demo_server_ocr <- function(input, output, session) {
  
  
  print("tab_demo_server of ocr")
  volumes <- getVolumes()
  
  shinyDirChoose(input, 'directory', roots=volumes, session=session)
  
  def_path <<- "/home/kaptan/OCR/default_form/"
  
  path1 <<- reactive({
    inDir <- input$directory
    
    if (is.null(inDir))
      return(print("No folder selected yet..."))
    else
      return(print(parseDirPath(volumes, input$directory)))
  })
  
  path2 <<- reactive({
    
    return(def_path)
    
  })
  
  output$dirP <- renderText(path1())
  
  
  # observeEvent(input$start_b {
  # 
  #   output$show_buttons <- renderUI({
  #                           actionButton("sel_form", 
  #                                      "Select the Form", 
  #                                      icon("cog"), 
  #                                      style="color: #fff; background-color: green; width: 100%; max-width: 250px; margin-left: auto; margin-right: auto; display: block;")  
  #                         })
  # })
  # 
  
  observeEvent(input$default, {
    
    print("inside observeEvent of default")
    
    detect_python <<- import_from_path("getText")
    
    
    dirpath <<- def_path                                   #"/home/kaptan/OCR/default_form/"
    print(dirpath)
    
    res <- detect_python$process(dirpath)
    #  res_csv <-read.csv("/home/kaptan/OCR/Output/Output.csv")
    # output$plot1 <- DT::renderDataTable({DT::datatable(res_csv)}) 
    output$plot1<-DT::renderDataTable({DT::datatable(read.csv("/home/kaptan/OCR/Output/Output.csv"))}) 
    #   output$plot2<-DT::renderDataTable({DT::datatable(read.csv("/home/kaptan/OCR/Output/Output.csv"))}) 
    
    
  }
  )
  
  observeEvent(input$find_image, {
    
    print("inside observeEvent of find_image")
    
    detect_python <<- import_from_path("getText")
    
    #    print("getText detected")
    
    dirpath1 <<- path1()                              #   "/home/kaptan/OCR/default_form"
    
    #    print("got the dir path")
    
    dirpath <<- paste(dirpath1,'/',sep="")            #   "/home/kaptan/OCR/default_form/"
    
    #dirpath <<- def_path                                   #"/home/kaptan/OCR/default_form/"
    print(dirpath)
    
    res <- detect_python$process(dirpath)
    
    print("returned from process function")
    
    #  res_csv <-read.csv("/home/kaptan/OCR/Output/Output.csv")
    # output$plot1 <- DT::renderDataTable({DT::datatable(res_csv)}) 
    output$plot2<-DT::renderDataTable({DT::datatable(read.csv("/home/kaptan/OCR/Output/Output.csv"))}) 
    
    print("generated plot2")
    
    
  }
  )  
  
  
  
  
  #  qfile <- reactive({
  #    inFile <- input$file1
  #    
  #    return(inFile$datapath)
  #  })
  
  #  getwd()
  
  #  output_txt<-read.csv("/home/kaptan/OCR/Output/Output.csv")
  #  print(output_txt)
  
  
  
  #  ab <- sprintf("select * from file")
  
  
  
  
  #output$plot1 <-read.csv("/home/kaptan/OCR/Output/Output.csv") 
  
  
  output$ip_img <- renderImage({
    filelist <- list.files(path = path2(), pattern = "*.jpg|*.jpeg", full.names = TRUE)
    file <- filelist[1]
    filename = file
    img <- readJPEG(filename)
    #      img<- shiny::img(filename)
    
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
