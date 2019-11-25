# Front page module

# UI function
tab_intro_ui <- function(id) {
  
  # Basically not needed. Just kept here to preserve commonality across files.
  ns <- NS(id)
  
  # Main UI
  fluidPage(
    titlePanel("Plant Disease Detection"),
    fluidRow(
      column(width=7,
             box(title='Overview', width = NULL,
                 p(style="font-size:110%","We have tried to apply deep learning models to determine the health of a plant. We take a leaf and predict if it is healthy or have a specific disease, and the name of that disease. Our model is trained on 38 different categories, some of which are different diseases on same plant type.")
             )
             
      ),
      column(width=5,
             box(title='Key Benefits', width = NULL,
                 tags$ul (type="square", style="font-size:110%",
                          tags$li ("Early Disease Detection"),
                          tags$li ("Always Available"),
                          tags$li ("Limited Awareness & Resources"),
                          tags$li ("Automatic Updates for New Disease Outbreaks")
                 )
             )
      )
    ),
    fluidRow(
      column(width=12,
             tabsetPanel(
               tabPanel(title = h4('Business Case', style="margin-top: 0;margin-bottom: 5px;"),
                        p(style="font-size:110%;", "Our goal is to help farm owners predict the health of their plants accurately and in a timely fashion. Early and accurate discovery can help stop the spread of the disease and suggest possible preventive measures or urgent treatment.
                          Following are some arbitrary plants, with and without disease, that are easily detectable by our app:")
                        )
      )#,
      #tabBox(title='The business case and using this demo', class="box-title", width = NULL, side = "right", selected = 'Business Case',
      
      #)
      )
    ),
    #fluidRow(
    # tags$em("Note: At present, this demo is tested on Google Chrome. Playing videos on other browsers, might show some problems.", style = 'color: green;font-size:110%')
    #),

    
    
    
    
    br(),
    fluidRow(
      column(width=12,
             box (title = "Healthy Plant Leaves", width = "100%",
                  fluidRow(
                    column (width = 12,
                            style = "margin-top: 20px;",
                            wellPanel(div(
                              uiOutput("imageGrid_healthy")
                            )))
                  )
             ),
             box (title = "Unhealthy Plant Leaves", width = "100%",
                  fluidRow(
                    column (width = 12,
                            style = "margin-top: 20px;",
                            wellPanel(div(
                              uiOutput("imageGrid_unhealthy")
                            )))
                  )
             )
      )
    ),
    br(),
    br(),
    br(),
    fluidRow(
      tags$p(tags$b ("Acknowledgment: ", style="color:orange"), "This demo is based on publicly available data")
    )
    )
}

# Server function
tab_intro_server <- function(input, output, session) {
  # Empty, since there is no interactivity on front page
  
  filelist_unhealthy <<-
    list.files(path =  'www/intro_images/unhealthy',
               pattern = "*.jpg|*.jpeg*.JPG",
               full.names = TRUE)
  
  filelist_healthy <<-
    list.files(path =  'www/intro_images/healthy',
               pattern = "*.jpg|*.jpeg*.JPG",
               full.names = TRUE)
  
  
  output$imageGrid_unhealthy <- renderUI({
    fluidRow(lapply(filelist_unhealthy, function(img) {
      column(
        3,
        tags$div(
          style = "display: inline-block; width: 100%; height: 200px; margin:0px 0px 20px 0px",
          tags$img(
            src = paste0("intro_images/unhealthy/", basename(img)),
            class = "clickimg",
            'data-value' = basename(img),
            width = '100%',
            height = '100%'
          )
        )
      )
    }))
  })
  
####

    output$imageGrid_healthy <- renderUI({
      fluidRow(lapply(filelist_healthy, function(img) {
        column(
          3,
          tags$div(
            style = "display: inline-block; width: 100%; height: 200px; margin:0px 0px 0px 0px",
            tags$img(
              src = paste0("intro_images/healthy/", basename(img)),
              class = "clickimg",
              'data-value' = basename(img),
              width = '100%',
              height = '100%'
            )
          )
        )
      }))
    })
  
    
    
  
}