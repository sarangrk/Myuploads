# UI function
tab_training_ui <- function(id) {
  # Main UI
  fluidPage(
    useShinyjs(),
    titlePanel("Training"),
    fluidRow(column(
      width = 12,
      p(style = "font-size:110%",
        'This page allows you to train the deep learning model for object detection using your custom dataset. To prepare and upload custom dataset, use the data input tab.')
    )),
    br(),
    fluidRow(
      column(3,
             hr(),
             textInput('Batch_size', "Batch_size", value = "25", placeholder = "Number of training image need to take")
      ),
      column(3,
             hr(),
             textInput('Epoch', "Epoch", value = "60", placeholder = "To specify learning rate drop schedule. On our datasets, model achieve good accuracy with 10 * TrainingSetSize stepsize")),
      column(3,
             hr(),
             selectInput('net', "Model",   c("SVMModel_distance_for_Face.pkl" = "SVMModel_distance_for_Face.pkl",
                                             "SVM_Distance_forFace_v1.pkl" = "SVM_Distance_forFace_v1.pkl"))),
      column(3,
             hr(),
             textAreaInput("object_categories", "Categories", "Face_Recognition"))
    ),
    fluidRow(
      column(3,
             selectInput('previous_snapshot', "Train from previous snapshot",   c("True" = "TRUE",
                                                                                  "False" = "FALSE")))
    ),
    br(),
    fluidRow (
      tags$em("Note: Training deep models can take longer time depending on the data set.Usually it takes two hours for 6000 photo`s ", style = 'color: green;font-size:110%')
    ),
    br(),
    fluidRow (
      column (
        2,
        withBusyIndicatorUI(actionButton("training", "Start Training"))
      ),
      column (2, offset = 1,
              hidden(
                div (id = "download_control_ui",
                     downloadButton("download_model", "Download Trained Model")
                )
              )))
  )
}

# Server function
tab_training_server <- function(input, output, session) 
  {
  #current_directory <- getwd()
  
 # observeEvent(input$training, {
  #  withBusyIndicatorServer("training", {
      
   #   cfg <- paste ('experiments/cfgs/', input$net, ".yml", sep = "")
    #  weight <- paste ('data/imagenet_weights/', input$net, ".ckpt", sep = "")
      
     # options(useFancyQuotes = FALSE)
      #classes <<- paste ('[\'__background__\',',
       #                  sapply(strsplit(gsub(" ", "", input$object_categories), ','), function(x) toString(sQuote(x))),
        #                 ']', sep="")
      
      #step_size = paste ('[',input$step_size,']', sep = "")
      #print (step_size)
      #set_cfgs = c('TRAIN.STEPSIZE', step_size, 'CLASSES',classes)
      
    #})
  #})
  
  
  observeEvent(input$training, { withBusyIndicatorServer("training", {
    threshold <- as.numeric(input$threshold)
    
    current_directory <- getwd()
    
    print("program loaded ..")
    
    detect_python <<- import_from_path("Faces_Train")
    
    
    print("program loaded finished  ..") 
    
    InputFolder = paste(current_directory, "FacesDB", input$foldername , sep = "/")
    print(InputFolder)
    
    detect_python$TrainModel(InputFolder)
    
    print("training model..")
    
    show ("detection_output")
    
    
  })
  })
  
  
  
  # Return the UI for a modal dialog with data selection input. If 'failed' is
  # TRUE, then display a message that the previous value was invalid.
  dataModal <- function(failed = FALSE) {
    modalDialog(
      textInput("model_name", "Choose the model name",
                placeholder = 'e.g. "Custom_Model"'
      ),
      if (failed)
        div(tags$b("Invalid name or model with same name already exists", style = "color: red;")),
      
      footer = tagList(
        modalButton("Cancel"),
        actionButton("ok", "OK")
      )
    )
  }
  
  # When OK button is pressed, attempt to save the model. If successful,
  # remove the dialog. If not show another modal, but this time with a failure
  # message.
  observeEvent(input$ok, {
  })
  
  #output$download_model <- downloadHandler(
    #filename <- function() {
      #paste("model", "zip", sep=".")
    #},
    
  #)

}