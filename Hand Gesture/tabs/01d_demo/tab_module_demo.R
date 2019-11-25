# Front page module

# UI function
tab_demo_ui <- function(id) {
  # Main UI
  fluidPage(
    useShinyjs(),
    titlePanel("Gesture Detection"),
    fluidRow(column(width = 12,
                    box (
                      width = NULL,
                      p(
                        style = "font-size:110%",
                        'In order to try this demo, use the default one from the button "Use Default Video File". Once the video will be displayed,
                        other controls will appear below the displayed video. From there, you can run the model and see the output.'
                      )
                      ))),
    fluidRow (
      tags$em("Note: Please use default video to proceed.
              It is best practice to use webcam for gesture detection.
              Since , Webcam cannot be configured due to some limitation.
              Kindly proceed with the default video", style = 'color: green;font-size:110%')
      ),
    br(),
    fluidRow(
      # column(4,
      #        # Input: Select a file ----
      #        fileInput("uploaded_file", "Choose Video File")),
      # column (1, align = "center", style = "margin-top: 30px;",
      #         tags$b("OR")),
      column (
        4,
        style = "margin-top: 25px;",
        actionButton("default_video", "Use Default Video File")
      )
    ),
    br(),
    fluidRow (column (10, offset = 1,
                      hidden(
                        div (id = "detection_input",
                             box(
                               title = 'Input Video',
                               width = NULL,
                               uiOutput("input_video")
                             ))
                      ))),
    fluidRow (hidden (div (
      id = "hr_element_ui",
      tags$hr(style = 'border-color: #EF6C00;width:90%')
    ))),

    fluidRow(column (10, offset = 1,
                     hidden(
                       div (id = "detect_control_ui",
                            withBusyIndicatorUI(
                              actionButton("detect", "Perform Detection")
                            ))
                     ))),
    br(),
    fluidRow(column (10, offset = 1,
                     hidden(
                       div (id = "detection_output",
                            box(
                              title = 'Detection Output',
                              width = NULL,
                              # Output: Video files ----
                              uiOutput("converted_video")
                            ))
                     )))
      )
}

# Server function
tab_demo_server <- function(input, output, session) {
  
  observeEvent (input$uploaded_file, {
    if (file.exists("www/0.mp4"))
      file.remove("www/0.mp4")
    file.copy(input$uploaded_file$datapath, "www")
    video_url <- paste("0.mp4?", Sys.time(), "")
    
    output$input_video <- renderUI({
      print(input$uploaded_file$datapath)
      tags$video(src = video_url,
                 type = "video/mp4",
                 controls = NA)
    })
    uploaded <<- TRUE
    show ("detection_input")
    show ("hr_element_ui")
    show ("detect_info_ui")
    show ("select_model_ui")
    show ("select_net_ui")
    show ("select_threshold_ui")
    show ("detect_control_ui")
  })
  
  observeEvent (input$default_video, {
    output$input_video <- renderUI({
      tags$video(src = "Hand_gesture_2.mp4",
                 type = "video/mp4",
                 controls = NA)
    })
    uploaded <<- FALSE
    show ("detection_input")
    show ("hr_element_ui")
    show ("detect_info_ui")
    show ("select_model_ui")
    show ("select_net_ui")
    show ("select_threshold_ui")
    show ("detect_control_ui")
  })
  
  # observeEvent(input$model, {
  #   print ('observed')
  #   selected_model_name<-input$model
  #
  #   model_choices<-c('default', list.dirs('tf-faster-rcnn/output/custom', full.names = FALSE, recursive=FALSE))
  #
  #   updateSelectInput(session,"model",choices=model_choices,selected=selected_model_name)
  #
  # })
  
  observeEvent(input$detect, {
    withBusyIndicatorServer("detect", {
      threshold <- as.numeric(input$threshold)
      
      current_directory <- getwd()
      # if (uploaded) {
      #   input_path = paste(current_directory, "www/0.mp4", sep = "/")
      # } else {
      #   input_path = paste(current_directory, "www/default_video.mp4", sep = "/")
      # }
      
      input_path = paste("/home/kaptan/hand_gesture/www/Hand_gesture_2.mp4", sep = "/")
      output_path = paste("/home/kaptan/hand_gesture/www/output_video.mp4", sep =  "/")
      print("loading program")
      detect_python <<- import_from_path("gesture_video_v2")
      detect_python_new <<- import_from_path("ConvertVideo")
      
      print("loading program done ..")
      detect_python$Hand_Gesture(input_path,
                                 output_path)
      print("loading function done..")
      
      input_path_new = paste("/home/kaptan/hand_gesture/www/output_video.mp4", sep = "/")
      
      output_path_new = paste("/home/kaptan/hand_gesture/www/output_video_final.m4v", sep ="/")
      
      detect_python_new$convert(input_path_new,output_path_new)
      
      
      show ("detection_output")
      output$converted_video <- renderUI({
        #output_video_url <- paste("output_video.mp4?", Sys.time(), "")
        tags$video(src = "output_video_final.m4v",
                   type = "video/mp4",
                   controls = NA)
      })
    })
  })
  
}
