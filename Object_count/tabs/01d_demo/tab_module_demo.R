# Front page module

# UI function
tab_demo_ui <- function(id) {
  # Main UI
  fluidPage(
    useShinyjs(),
    titlePanel("Object Counting"),
    fluidRow(column(width = 12,
                    box (
                      width = NULL,
                      p(
                        style = "font-size:110%",
                        'In order to try this demo, Please use default Video option and click on the object count tab to see the output Video.'
                      )
                      ))),
    fluidRow (
      tags$em("Note: At this time, only video format supported is m4v.", style = 'color: green;font-size:110%'),
      br(),
      tags$em("Count of object is done between x movement between 40 and 55, y movement between 50 and 65.", style = 'color: green;font-size:110%')
    ),
    br(),
    fluidRow(
      column(4,
             # Input: Select a file ----
             fileInput("uploaded_file", "Choose Video File")
             ),
      #column (4, align = "center", style = "margin-top: 30px;",
              #tags$b("Note: At this time, Please use the default video .", style = 'color: green;font-size:110%')),
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
    fluidRow (column (10, offset = 1,
                      hidden (
                        div (
                          id = "detect_info_ui",
                          tags$em(
                            "Keep it default ",
                            style = 'color: green;font-size:110%'
                          )
                        )
                      ))),
    
    fluidRow(column (10, offset = 1,
                     hidden(
                       div (id = "detect_control_ui",
                            withBusyIndicatorUI(
                              actionButton("detect", "Count Object")
                            ))
                     ))),
    br(),
    fluidRow(column (10, offset = 1,
                     hidden(
                       div (id = "detection_output",
                            box(
                              title = 'Object Count Output',
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
    if (file.exists("www/0.m4v"))
      file.remove("www/0.m4v")
    file.copy(input$uploaded_file$datapath, "www")
    video_url <- paste("0.m4v?", Sys.time(), "")
    
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
      tags$video(src = "Default.m4v",
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
      if (uploaded) {
        input_path = paste(current_directory, "www/0.m4v", sep = "/")
      } else {
        input_path = paste(current_directory, "www/Default.m4v", sep = "/")
      }
      output_path = paste(current_directory, "www/output_video.mp4", sep =
                            "/")
      
      detect_python <<- import_from_path("object_count_with_lane_Aws")
      detect_python_new <<- import_from_path("ConvertVideo")

      
      detect_python$objectCount(input_path,
                                   output_path)
      print(input_path)
      input_path_new = paste(current_directory, "www/output_video.mp4", sep = "/")
      
      output_path_new = paste(current_directory, "www/output_video_final_1.m4v", sep ="/")
      
      detect_python_new$convert(input_path_new,output_path_new)
      
      
      
      show ("detection_output")
      output$converted_video <- renderUI({
       # output_video_url <- paste("output_video.mp4?", Sys.time(), "")
        tags$video(src = "output_video_final_1.m4v",
                   type = "video/mp4",
                   controls = NA)
      })
    })
  })
  
}
