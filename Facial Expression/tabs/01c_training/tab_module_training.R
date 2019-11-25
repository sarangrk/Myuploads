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
             textInput('iterations', "Iterations", value = "50000", placeholder = "Number of training iterations. On our datasets, model achieve good accuracy with 15 * TrainingSetSize iterations")
      ),
      column(3,
             hr(),
             textInput('step_size', "Step Size", value = "35000", placeholder = "To specify learning rate drop schedule. On our datasets, model achieve good accuracy with 10 * TrainingSetSize stepsize")),
      column(3,
             hr(),
             selectInput('net', "Model",   c("res101" = "res101",
                                             "res50" = "res50",
                                             "vgg16" = "vgg16"))),
      column(3,
             hr(),
             textAreaInput("object_categories", "Categories", "tiger,leopard,elephant,rhinoceros"))
    ),
    fluidRow(
      column(3,
             selectInput('previous_snapshot', "Train from previous snapshot",   c("False" = "FALSE",
                                             "True" = "TRUE")))
    ),
    br(),
    fluidRow (
      tags$em("Note: Training deep models can take longer time depending on the data set. Here with 50000 iterations, training res101 can take more than 12 hours.", style = 'color: green;font-size:110%')
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
tab_training_server <- function(input, output, session) {
  current_directory <- getwd()
  
  observeEvent(input$training, {
    withBusyIndicatorServer("training", {
      
      cfg <- paste ('experiments/cfgs/', input$net, ".yml", sep = "")
      weight <- paste ('data/imagenet_weights/', input$net, ".ckpt", sep = "")
      
      options(useFancyQuotes = FALSE)
      classes <<- paste ('[\'__background__\',',
                         sapply(strsplit(gsub(" ", "", input$object_categories), ','), function(x) toString(sQuote(x))),
                         ']', sep="")

      step_size = paste ('[',input$step_size,']', sep = "")
      print (step_size)
      set_cfgs = c('TRAIN.STEPSIZE', step_size, 'CLASSES',classes)
      
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
  
  output$download_model <- downloadHandler(
    filename <- function() {
      paste("model", "zip", sep=".")
    },
    
  )
}
