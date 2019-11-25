# Front page module

# UI function
tab_intro_ui <- function(id) {

  # Basically not needed. Just kept here to preserve commonality across files.
  ns <- NS(id)

  # Main UI
  fluidPage(
    titlePanel("Sentiment Analytics"),
    fluidRow(
      column(width=7,
             box(title='Business Case', width = NULL,
                 p(style="font-size:110%","Sentiment Analysis is already being widely used by different companies to gauge consumer mood towards their product or brand in the digital world. However, in offline world users are also interacting with the brands and products in retail stores, showrooms, etc. and solutions to measure user’s reaction automatically under such settings has remained a challenging task. Emotion Detection from facial expressions using AI can be a viable alternative to automatically measure consumer’s engagement with their content and brands. 
                   "),
                 p (style = "font-size:110%","Detecting emotions with technology is a challenging task, yet one where machine learning algorithms have shown great promise. Facial Emotion detection is only a subset of what visual intelligence could do to analyze videos and images automatically.")
             )
             
      ),
      column(width=5,
             box(title='Key Benefits', width = NULL,
                 tags$ul (type="square", style="font-size:110%",
                          tags$li ("Understanding the customer’s need/reaction for the product easily through his expressions."),
                          tags$li ("IIdentifying the true customer feedback."),
                          tags$li ("This method is more objective than the verbal methods."),
                          tags$li ("Applications in variety of fields like game testing, hiring processes in company, market research, safety of car driver etc.")
                 )
             )
      )
    ),
    fluidRow(
      column(width=12,
             tabsetPanel(
               tabPanel(title = h4('About this Demo', style="margin-top: 0;margin-bottom: 5px;"),
                        p(style="font-size:110%;", "In this demo, we developed an expression detection system where few of the Human Emotions are defined in order to identify them through video, this has been tested on video, image & live stream (web cam) this is achieved using OpenCV & python which detects the Human emotions as follows:"),
                        tags$ul (type="square", style="font-size:110%",
                                 tags$li ("Angry"),
                                 tags$li ("Disgust"),
                                 tags$li ("Fear"),
                                 tags$li ("Happy"),
                                 tags$li ("Sad"),
                                 tags$li ("Surprise"),
                                 tags$li ("Neutral")
                        )
               ),
               tabPanel(title = h4('Using Demo', style="margin-top: 0;margin-bottom: 5px;"),
                        HTML('<iframe width="90%" height="315" style="max-width: 560px; margin:auto; display:block;" src="https://www.youtube.com/embed/WFAuyReg3nw" frameborder="0" allowfullscreen></iframe>')
               )
             )
      )
    ),
    br(),
     fluidRow(
        column(width=10, offset = 1,
                box (title = "Sentiment Analytics", width = "100%",
                    tags$video(src="Expression_Demo.m4v", type = "video/mp4", controls = NA, style = 'width:100%;height:500px;object-fit: fill;' )
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
