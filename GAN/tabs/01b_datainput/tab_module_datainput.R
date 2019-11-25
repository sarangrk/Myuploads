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
             fileInput("uploaded_jpegs", "Images")),
      column(3,
             hr(),
             fileInput("uploaded_xmls", "Annotations")),
      column(3,
             hr(),
             fileInput("uploaded_trainval", "Training set file")),
      column(3,
             hr(),
             fileInput("uploaded_test", "Test set file"))
    ),
    br(),
    fluidRow (
      tags$em("Note: You can download the sample data to see the data format. Once your custom data is uploaded, process it using the 'Process Custom Data' button below. ", style = 'color: green;font-size:110%')
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
      p (style = "font-size:110%", 'Training requires dataset in PASCAL VOC format. To train the model on your data, it must follow the below description.'),
      wellPanel(
        tags$ul (type="square", style="font-size:110%",
                 tags$li (tags$b("Images"),
                          tags$ul (type="circle", style="font-size:110%",tags$li ("Images in JPG format")),
                          tags$ul (type="circle", style="font-size:110%",tags$li ("Upload a zip file with training and test set images"))),
                 tags$li (tags$b("Annotations"),
                          tags$ul (type="circle", style="font-size:110%",tags$li ("XML files for annotations having ground truths corresponding to images")),
                          tags$ul (type="circle", style="font-size:110%",tags$li ("Files with same names as original images")),
                          tags$ul (type="circle", style="font-size:110%",tags$li ("Upload a zip file with all XML files for training and test set"))),
                 tags$li (tags$b("Training set file"), 
                          tags$ul (type="circle", style="font-size:110%",tags$li ("Text file containing names of image files in the training set"))),
                 tags$li (tags$b("Test set file"), 
                          tags$ul (type="circle", style="font-size:110%",tags$li ("Text file containing names of image files in the test set")))
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
  annotation_path = paste(custom_data_dir, 'Annotations', sep = "/")
  set_trainval = paste(custom_data_dir, "ImageSets/Main/trainval.txt", sep = "/")
  set_test = paste(custom_data_dir, "ImageSets/Main/test.txt", sep = "/")
  
  observeEvent(input$process, {

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
