# Front page module

# UI function
tab_intro_ui <- function(id) {

  # Basically not needed. Just kept here to preserve commonality across files.
  ns <- NS(id)

  # Main UI
  fluidPage(
    titlePanel("Driver's Sentiment Analytics"),
    fluidRow(
      column(width=7,
             box(title='Business Case', width = NULL,
                 p(style="font-size:110%","Driver's sentiment analysis for tracking driver facial features aims to enhance the predictive accuracy of driver-assistance systems.
An important application of machine vision and image processing could be driver drowsiness detection system due to its high importance. 
However, in offline world, this will ensure the driver's that insurance assessment properly reflect the way they drive.
Solutions to measure Driver’s reaction automatically under such settings has remained a challenging task.
Sentiment Detection from facial expressions using AI can be a viable alternative to automatically measure Driver's behaviour and can directly impact Insurance companies. 
                   "),
                 p (style = "font-size:110%","Detecting emotions with technology is a challenging task, yet one where machine learning algorithms have shown great promise. Facial Emotion detection is only a subset of what visual intelligence could do to analyze videos and images automatically.")
             )
             
      ),
      column(width=5,
             box(title='Key Benefits', width = NULL,
                 tags$ul (type="square", style="font-size:110%",
                          tags$li ("Understanding the Driver’s need/reaction while driving easily through his expressions."),
                          tags$li ("This method is more objective than the verbal methods."),
                          tags$li ("Applications in variety of fields like Insurance companies, Rental Companies, safety of car driver etc.")
                 )
             )
      )
    ),
    fluidRow(
      column(width=12,
             tabsetPanel(
               tabPanel(title = h4('About this Demo', style="margin-top: 0;margin-bottom: 5px;"),
                        p(style="font-size:110%;", "In this demo, we have developed a Driver's expression detection system where few of the Driver's behaviours are defined in order to identify them through video, this has been tested on video, image & live stream (web cam) this is achieved using OpenCV, Dlib & python which detects the Human emotions as follows:"),
                        tags$ul (type="square", style="font-size:110%",
                                 tags$li ("Angry"),
                                 tags$li ("Yawning"),
                                 tags$li ("Drowsy"),
                                 tags$li ("Happy"),
                                 tags$li ("Eye_act")
                        )
               )
             )
      )
    ),
    br(),
     fluidRow(
        column(width=10, offset = 1,
                box (title = "Driver's Behaviour Analytics", width = "100%",
                    tags$video(src="Demo_vid.m4v", type = "video/mp4", controls = NA, style = 'width:100%;height:500px;object-fit: fill;' )
                )
        )
     ),
    br(),
    br(),
    br()#,
    #fluidRow(
    # tags$p(tags$b ("Acknowledgment: ", style="color:orange"), "This demo is based on publicly available version of ", tags$a(href="https://github.com/endernewton/tf-faster-rcnn", "Faster R-CNN", style="color:blue"))
    #)
)
}

# Server function
tab_intro_server <- function(input, output, session) {

  # Empty, since there is no interactivity on front page

}
