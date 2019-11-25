# Front page module

# UI function
tab_datainput_ui <- function(id) {
  # Main UI
  fluidPage(
    useShinyjs(),
    titlePanel("Choosing your data"),
    fluidRow(column(
      width = 12,
      p(style = "font-size:110%",
        'Here upload your data to train the model on custom dataset. The dataset must be in the proper format. For the details, see the Data Description section below. ')
    )),
    
    br(),
    fluidRow(
      column(3,
            hr(),
            textInput('foldername', "Enter Name", value = "Enter Name of Person", width = NULL, placeholder = NULL)),
            
      
      column(3,
             hr(),
             fileInput("uploaded_jpegs", " Upload Images ", multiple = TRUE)),
      
      column(3,
             #actionButton('B2',"Train Model"))
             hr(),
             #fileInput("uploaded_trainval", "Training Model"))
             #textInput('Model Training', "Model Trainig", value = "Keras and Dnn", width = NULL, placeholder = NULL))
             textInput('Model Training', "Model Training", value = "SVMModel_distance_for_Face.pkl", placeholder = "SVMModel_distance_for_Face_latest.pkl"))
      
      ),
      #column(3,
            # hr(),
             #fileInput("uploaded_test", "Upload Test Video"))),
    fluidRow(actionButton('B1',"Name Enter")),
    
    
    
    br(),
   
 
    fluidRow (
      tags$em("Note: You can download the sample data to see the data format.]", style = 'color: green;font-size:110%')
    ),
    br(),
    fluidRow (column (
      2,
      downloadButton("downloadData", "Download Sample Data")
    ),
    column (
      2,
      offset=1,
      withBusyIndicatorUI(actionButton("process", "Process Custom Data"))
    )
    ),
    br(),
    fluidRow (column (
      12,
      p(style = "font-size:110%", textOutput("data_load_results")),
      hr(),
      h3 ('Data Description'),
      p (style = "font-size:110%", 'Training requires dataset in jpeg format. To train the model on your data, it must follow the below description.'),
      wellPanel(
        tags$ul (type="square", style="font-size:110%",
                 tags$li (tags$b("Images"),
                          tags$ul (type="circle", style="font-size:110%",tags$li ("Images in JPG format")),
                          tags$ul (type="circle", style="font-size:110%",tags$li ("Upload a zip file with training and test set images"))),
                 #tags$li (tags$b("Annotations"),
                 #  tags$ul (type="circle", style="font-size:110%",tags$li ("XML files for annotations having ground truths corresponding to images")),
                 # tags$ul (type="circle", style="font-size:110%",tags$li ("Files with same names as original images")),
                 # tags$ul (type="circle", style="font-size:110%",tags$li ("Upload a zip file with all XML files for training and test set"))),
                 tags$li (tags$b("Training Model"), 
                          tags$ul (type="circle", style="font-size:110%",tags$li ("Trainig Model will take the input dataset files in the training set and train model. it might take time , usally it take 2 hours")))
                 #tags$li (tags$b("Upload Test Video"), 
                          #tags$ul (type="circle", style="font-size:110%",tags$li ("Test video file containing face of person files in the test set")))
        )
      )      
    ))
  )
}

# Server function
tab_datainput_server <- function(input, output, session) {
  options(shiny.maxRequestSize = 1000 * 1024 ^ 2)
  current_directory <- getwd()
  custom_data_dir = paste(current_directory, "tf-faster-rcnn/data/custom", sep = "/")
  jpeg_path = paste(custom_data_dir, 'JPEGImages', sep = "/")
  # annotation_path = paste(custom_data_dir, 'Annotations', sep = "/")
  set_trainval = paste(custom_data_dir, "ImageSets/Main/trainval.txt", sep = "/")
  set_test = paste(custom_data_dir, "ImageSets/Main/test.txt", sep = "/")
  
  
  observeEvent (input$uploaded_jpegs, {
    
    
    uploadfolder <- paste(current_directory,"FacesDB", input$foldername, sep = "/")
    
    file.copy(input$uploaded_jpegs$datapath, uploadfolder)
    
    # video_url <- paste("0.mp4?", Sys.time(), "")
    # 
    # output$input_video <- renderUI({
    #   print(input$uploaded_jpegs$datapath)
    #   tags$video(src = video_url,
    #              type = "video/mp4",
    #              controls = NA)
    # })
    
    uploaded <<- TRUE
    show ("detection_input")
    show ("hr_element_ui")
    show ("detect_info_ui")
    show ("select_model_ui")
    show ("select_net_ui")
    show ("select_threshold_ui")
    show ("detect_control_ui")
  })
  
  
  
  
  ########
  #observeEvent(input$B1, { userName<-input$foldername 
  #detect_python <<- import_from_path("userInput") 
  #detect_python$userNamecreation(userName)
  
  observeEvent(input$B1, { withBusyIndicatorServer("B1", {
    threshold <- as.numeric(input$threshold)
    
    current_directory <- getwd()
    
    
    folder_path = paste(current_directory, "FacesDB", input$foldername , sep = "/")
    
    print("program loaded ..")
    detect_python <<- import_from_path("userInput")
    print("program loaded finished  ..") 
    
    detect_python$create_folder(folder_path)
    show ("detection_output")
    
  })
    })
  
  
  
  output$downloadData <- downloadHandler(
    filename <- function() {
      paste("sample_data", "zip", sep=".")
    },
    
    content <- function(file) {
      file.copy("www/sample_data.zip", file)
    },
    contentType = "application/zip"
  )
  
}
