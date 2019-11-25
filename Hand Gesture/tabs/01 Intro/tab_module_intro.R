# Front page module

# UI function
tab_intro_ui <- function(id) {

  # Basically not needed. Just kept here to preserve commonality across files.
  ns <- NS(id)

  # Main UI
  fluidPage(
    titlePanel("Gesture Detection"),
    fluidRow(
      column(width=7,
             box(title='Introduction', width = NULL,
                 p(style="font-size:110%","Gesture recognition is a type of perceptual computing user interface that allows computers to capture and interpret human gestures as commands. The general definition of gesture recognition is the ability of a computer to understand gestures and execute commands based on those gestures. 
                   "),
                 p (style = "font-size:110%","Gesture Control: Gesture control enables higher levels of activity and engagement by allowing users another mode of interaction with your digital products. Quantify the gesture levels and other engagements in order to provide meaningful insights.")
             )
             
      ),
      column(width=5,
             box(title='Business case', width = NULL,
                 tags$ul (type="square", style="font-size:110%",
                          tags$li ("Capture the emotional state of your customer by analyzing micro gestures."),
                          tags$li ("Gesture recognition in Gaming."),
                          tags$li ("Big car company’s working on a system that allows drivers to control features such as air conditioning, windows and windshield wipers with gesture controls")
                          
                 )
             )
      )
    ),
    fluidRow(
      column(width=12,
             tabsetPanel(
               tabPanel(title = h4('About this Demo', style="margin-top: 0;margin-bottom: 5px;"),
                        p(style="font-size:110%;", "In this demo, we developed gesture detection of counting the number of fingers within the video. We are using convex hull technique to identify gesture, and label them according to our use. For demo, we are identifying following patterns."),
                        tags$ul (type="square", style="font-size:110%",
                                 tags$li ("1"),
                                 tags$li ("2"),
                                 tags$li ("3"),
                                 tags$li ("4"),
                                 tags$li ("5")
                                 #tags$li ("Best of Luck")
                                )
                      ),
                tabPanel(title = h4('Using Demo', style="margin-top: 0;margin-bottom: 5px;"),
                         HTML('<iframe width="90%" height="315" style="max-width: 560px; margin:auto; display:block;" src="https://www.youtube.com/embed/c5_NiXB1XOQ" frameborder="0" allowfullscreen></iframe>'),
                         p(style="color: red; font-size:110%;", "Limitations"),
                         tags$ul (type="square" , style = 'color: red;font-size:110%',
                                  tags$li ("Gesture Detection works best with live feed videos, like web-cam."),
                                  tags$li ("For demo perpose we have used pre-recorded video for gesture, hence you will not be able to upload your own videos."),
                                  tags$li ("Also, due to cluttered background you may see some incorrect gesture detections on some parts.")
                                  )
                          )
      )
    ),
    br(),
     fluidRow(
        column(width=10, offset = 1,
                box (title = "Gesture Analytics", width = "100%",
                    tags$video(src="output_video_final.m4v", type = "video/mp4", controls = NA, style = 'width:100%;height:500px;object-fit: fill;' )
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
)
}

# Server function
tab_intro_server <- function(input, output, session) {

  # Empty, since there is no interactivity on front page

}
