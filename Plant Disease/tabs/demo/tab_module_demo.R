# Front page module

# UI function
tab_demo_ui <- function(id) {
  # Main UI
  fluidPage(
    useShinyjs(),
    titlePanel("Classify Plant Disease"),
    fluidRow(column(width = 12,
                    box (
                      width = "100%",
                      p(
                        style = "font-size:110%",
                        'Using our Plant Disease app, you can perform disease classification from the image of a leaf with disease symptoms.
                        '
                      ),
                      p(
                        style = "font-size:110%",
                        'In order to try this demo, upload your image or choose the sample image from the provided list below and press Classify at the bottom!
                        '
                      )
                    ))),
    br(),
    fluidRow(
      column(width = 3,
             # Input: Select a file ----
             fileInput("uploaded_file", "Upload Image")),
      column (1, align = "center", style = "margin-top: 30px;",
              tags$b("OR")),
      column (width = 8,
              style = "margin-top: 25px;",
              wellPanel(div(
                uiOutput("imageGrid"),
                tags$script(
                  HTML(
                    "$(document).on('click', '.clickimg', function() {",
                    "  Shiny.onInputChange('clickimg', $(this).data('value'));",
                    "});"
                  )
                )
              )))
    ),
    br(),
    fluidRow(column(
      4, hidden(wellPanel(
        id = "display_selected_image",
        div(style = "display: inline-block; width: 100%; height: 400px",
            imageOutput("displayImage"))
      ))),
      column(4, hidden(
        wellPanel(
          id = "text_output_control",
          div (style = "display: inline-block; width: 100%; height: 400px",
               uiOutput('textOutput'))
        )
      ))
    ),
    fluidRow(column(2, hidden(
      div (id = "select_model_ui",
           selectInput(
             'model',
             "Select Model",
             c('Inception V3')
           ))
    )),
    column(3, style = "margin-top: 25px;", align = "left", hidden(
      div (id = "extract_control_ui",
           withBusyIndicatorUI(
             actionButton("classify", "Classify")
           ))
    ))
    )
  )
}

load_image <- function(image_path) {
  img <- readJPEG(image_path)
  # Return a list containing the filename
  # Return a list containing the filename
  list(
    src = paste0(image_path),
    width = "100%",
    height = "100%",
    alt = "This is alternate text"
  )
}

display_image_processing_controls <- function(output, image_path, load_dir_path) {
  output$displayImage <- renderImage({
    image = load_image(image_path)
  }, deleteFile = FALSE)
  todelete <- dir(load_dir_path, full.names = TRUE)
  unlink(todelete)
  file.copy(image_path, load_dir_path)
  show ("display_selected_image")
  show ("select_model_ui")
  show ("extract_control_ui")
  
  image_path
}

# Server function
tab_demo_server <- function(input, output, session) {

  current_directory <- getwd()
  load_dir_path <-
    paste0(current_directory, "/www/loaded_images")
  output_text_path <- paste0(current_directory, "/www/output_files")
  options(shiny.maxRequestSize = 60 * 1024 ^ 2)
  
  shinyDirChoose(input, 'dir', roots = getVolumes())
  
  filelist <<-
    list.files(path =  'www/images',
               pattern = "*.jpg|*.jpeg*.JPG",
               full.names = TRUE)
  
  output$imageGrid <- renderUI({
    fluidRow(lapply(filelist, function(img) {
      column(
        3,
        tags$div(
          style = "display: inline-block; width: 100%; height: 200px; margin:0px 0px 20px 0px",
          tags$img(
            src = paste0("images/", basename(img)),
            class = "clickimg",
            'data-value' = basename(img),
            width = '100%',
            height = '100%'
          )
        )
      )
    }))
  })
  
  observeEvent(input$clickimg, {
    image_path = paste0("www/images/", input$clickimg)
    display_image_processing_controls(output,image_path, load_dir_path)
    image_comp_path <<- image_path
  })
  
  observeEvent (input$uploaded_file, {
    image_comp_path <<- display_image_processing_controls(output,input$uploaded_file$datapath, load_dir_path)
  })
  
  observeEvent(input$classify, {
    withBusyIndicatorServer("classify", {
      todelete <- dir(output_text_path, full.names = TRUE)
      unlink(todelete)
      
      text_recognize_python <- import_from_path('classify_images_r2')
      show ("text_output_control")
      output$textOutput <- renderUI({
        print(paste0("path:", image_comp_path))
        
        return(text_recognize_python$classify_image(image_comp_path))
      })
      
      
    })
    
  })
  
}
