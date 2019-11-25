# Front page module

# UI function
tab_demo_ui <- function(id) {
  # Main UI
  fluidPage(
    useShinyjs(),
    titlePanel("Image Creation Via GAN"),
    fluidRow(column(width = 12,
                    box (
                      width = NULL,
                      p(
                        style = "font-size:110%",
                        'In order to try this demo, upload your set of images or use the default one from the button "Use Default Images". Once the video will be displayed, 
                        other controls will appear below the displayed video. From there, you can change the default settings before performing detection 
                        e.g. choose your custom model or change confidence threshold.'
                      )
                      ))),
    # fluidRow (
    #   tags$em("Note: At this time, only black and white images are supported.", style = 'color: green;font-size:110%')
    # ),
    
    
    
    
    # br(),
    # fluidRow(
    #   column(4,
    #          hr(),
    #          selectInput('epochs', "Epochs",   c("5000" = "5000",
    #                                              "7500" = "7500",
    #                                              "10000" = "10000"))
    #                                              
    #   )
    #),
    
    
    # fluidRow (
    #   tags$em("Note: Higher the epochs, better will be the resolution of created images.", style = 'color: green;font-size:110%')
    # ),
    
    
    # br(),
    # fluidRow(
    #   column(4,
    #          hr(),
    #          textInput('foldername', "Folder Name", value = "Enter your Name", width = NULL, placeholder = NULL))
    # ),
    # br(),
    #Name <- input$foldername
    
    # fluidRow(column (10, offset = 1,
    #                  hidden(
    #                    div (id = "create_folder_ui",
    #                         withBusyIndicatorUI(
    #                           actionButton("detect_1", "Create Folder")
    #                         ))
    #                  ))),
    
    br(),
    
    fluidRow(
      column (
        2,
        style = "margin-top: 25px;",
        actionButton("default_video_1", "Use MNIST Dataset")
      ),
      column (1, align = "center", style = "margin-top: 30px;",
              tags$b("OR")),
      column (
        2,
        style = "margin-top: 25px;",
        actionButton("default_video_2", "Use CFAR10 Dataset")
      ),
      
      column (1, align = "center", style = "margin-top: 30px;",
              tags$b("OR")),
      column (
        2,
        style = "margin-top: 25px;",
        actionButton("default_video_3", "Use your own dataset")
      )
    ),
    
    br(),
    
    fluidRow(
      
      column(5, 
             #style = "margin-top: 25px;",
             #offset = 1,
                hidden(
                  div(id = "user_input",
                      fileInput("uploaded_file", "Choose Image Files", multiple = TRUE)
                      )
                  )
                )

      ),

    br(),
    
    fluidRow(
    column (
      10, 
      style = "margin-top: 25px;",
      #offset = 1,
                      hidden(
                        div (id = "detection_input",
                             box(
                               title = 'Input Image',
                               width = NULL,
                               imageOutput("input_image")
                             ))
                      ))),
    br(),
    
    fluidRow (hidden (div (
      id = "hr_element_ui",
      tags$hr(style = 'border-color: #EF6C00;width:90%')
    ))),

    br(),  
    
    fluidRow(column (10, #offset = 1,
                     hidden(
                       div (id = "detect_control_ui_1",
                            withBusyIndicatorUI(
                              actionButton("create_1", "Perform MNIST Image Creation")
                            ),
                            tags$p("Note: Model will take 30-40 minutes to run.", style = 'color: red;font-size:120%')
                            )
                     ))),
    
    br(),    
    
    fluidRow(column (10, #offset = 1,
                     hidden(
                       div (id = "detect_control_ui_2",
                            withBusyIndicatorUI(
                              actionButton("create_2", "Perform CFAR10 Image Creation")
                            ),
                            tags$p("Note: Model will take 2-3 hours to run.", style = 'color: red;font-size:120%')
                            )
                     )
                     )
             ),
    br(),
    
    fluidRow(column (10, #offset = 1,
                     hidden(
                       div (id = "detect_control_ui_3",
                            withBusyIndicatorUI(
                              actionButton("create_3", "Perform Custom Image Creation")
                                                ),
                            tags$p("Note: Training of model will take approx. 30 minutes.", style = 'color: red;font-size:120%')
                            )
                           )
                      )
             
             ),
    br(),
    
    fluidRow(
      column (10, #offset = 1,
              hidden(
                div (id = "detection_output_1",
                     box(
                       title = 'Generated Image',
                       width = NULL,
                       # Output: Video files ----
                       imageOutput("converted_video_1")
                     ))
              )))
  )                  
}

# Server function
tab_demo_server <- function(input, output, session) {
  
  observeEvent (input$default_video_1, {
    output$input_image <- renderImage({
      url <- paste(getwd(),"samples",sep = "/")
      filelist <- list.files(path = url, pattern = "real_images.png", full.names = TRUE)
      file <- filelist[1]
      filename = file
      img <- readPNG(filename)
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
    uploaded <<- FALSE
    #show ("user_input")
    show("detection_input")
    show ("detect_control_ui_1")
    hide ("detect_control_ui_2")
    hide ("detect_control_ui_3")
    hide ("detection_output_1")
  })
  
  observeEvent (input$default_video_2, {
    output$input_image <- renderImage({
      url <- paste(getwd(),"results",sep = "/")
      filelist <- list.files(path = url, pattern = "real_samples.png", full.names = TRUE)
      file <- filelist[1]
      filename = file
      img <- readPNG(filename)
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
    uploaded <<- FALSE
    show ("detection_input")
    show ("detect_control_ui_2")
    hide ("detect_control_ui_1")
    hide ("user_input")
    hide ("detection_output_1")
    hide ("detect_control_ui_3")
  })
  
  
  observeEvent (input$default_video_3, {
    
    uploaded <<- FALSE
    show ("user_input")
    hide ("detect_control_ui_1")
    hide ("detect_control_ui_2")
    hide ("detection_output_1")
    hide ("detection_input")
    #show ("detection_input")
  })
  
  

  observeEvent (input$uploaded_file, {
    
    url <- paste(getwd(),"Alphabet_Real",sep = "/")
    filelist <- list.files(path = url, pattern = "*.png", full.names = TRUE)
    
    file.remove(filelist)
    file.copy(input$uploaded_file$datapath, "Alphabet_Real",overwrite = TRUE)
    
    output$input_image <- renderImage({
      url <- paste(getwd(),"Alphabet_Real",sep = "/")
      filelist <- list.files(path = url, pattern = "*.png", full.names = TRUE)
      file <- filelist[1]
      filename = file
      img <- readPNG(filename)
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
    
    uploaded <<- TRUE
    show ("detection_input")
    show ("detect_control_ui_3")
  })
  
  observeEvent(input$create_1, {
    withBusyIndicatorServer("create_1", {
      
      detect_python <<- import_from_path("GAN_MNIST")
      detect_python$createmnist()
      
      show ("detection_output_1")
        output$converted_video_1 <- renderImage({
          url <- paste(getwd(),"samples", sep = "/")
          filelist <- list.files(path = url, pattern = "*.png", full.names = TRUE)
          file <- filelist[1]
          filename = file
          img <- readPNG(filename)
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
  })
  
  observeEvent(input$create_2, {
    withBusyIndicatorServer("create_2", {
      
      detect_python <<- import_from_path("GAN_AWS")
      detect_python$GanCreation()
      
      show ("detection_output_1")
      output$converted_video_1 <- renderImage({
        url <- paste(getwd(),"samples", sep = "/")
        filelist <- list.files(path = url, pattern = "*.png", full.names = TRUE)
        file <- filelist[1]
        filename = file
        img <- readPNG(filename)
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
    })
  
  observeEvent(input$create_3, {
    withBusyIndicatorServer("create_3", {
      
      epochs <- 10000
      epochs_final <- as.integer(epochs)
      
      BS <- 10 
      BATCH_SIZE <- as.integer(BS)
      
      
      detect_python <<- import_from_path("gan_logo_genration")
      detect_python$train(epochs_final, BATCH_SIZE)
      
      show ("detection_output_1")
      output$converted_video_1 <- renderImage({
        url <- paste(getwd(),"Alphabet_Fake", sep = "/")
        filelist <- list.files(path = url, pattern = "9990_0.png", full.names = TRUE)
        file <- filelist[1]
        filename = file
        img <- readPNG(filename)
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
  })
  
}
