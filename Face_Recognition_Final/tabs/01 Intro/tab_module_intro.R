# Front page module

# UI function
tab_intro_ui <- function(id) {

  # Basically not needed. Just kept here to preserve commonality across files.
  ns <- NS(id)

  # Main UI
  fluidPage(
    titlePanel("Face Recognition"),
    fluidRow(
      column(width=7,
             box(title='Business Case', width = NULL,
                 p(style="font-size:110%","The main objective of this is to recognize face and identify people.
We have used hog descriptor and unique face landmarks to identify unique features in a particular face.
Image-based investigations help in quicker identification of facts relating to a crime, in faster disposal of cases, as well as in taking precautionary measures.The use of face recognition has much to contribute in other areas such as payroll administration, advertising, automotive, media, digital out of home, tourism, and even in the medical field. 
                   "),
                 p (style = "font-size:110%","This system will recognize a person by face, check within the database if the person is valid or not. The model will be pretrained for the person face images and can hence identify them correctly.")
             )
             
      ),
      column(width=5,
             box(title='Key Benefits', width = NULL,
                 tags$ul (type="square", style="font-size:110%",
                          tags$li ("Facial identification even if the person’s facial features have changed over time from the earlier instance when his/her image was captured and stored in the database."),
                          #tags$li ("Spotting suspicious behavior based on a set of facial emotions (neutral, anger, fear, contempt, etc.)."),
                          tags$li ("Facial verification in cases such as schools where it is required that only verified personnel have access to students."),
                          tags$li ("Authorized entry into a stadium, building, or office premises.")
                 )
             )
      )
    ),
    fluidRow(
      column(width=12,
             tabsetPanel(
               tabPanel(title = h4('About this Demo', style="margin-top: 0;margin-bottom: 5px;"),
                        p(style="font-size:110%;", "In this demo, we developed a Facial identification system where we are recognizing a person through video, this has been tested on video, image & live stream (web cam). This is achieved using OpenCV/hogDescripter & python which detects the Human face:"),
                        tags$ul (type="square", style="font-size:110%",
                                 tags$li ("Face Recognition")
                                 #tags$li ("Disgust"),
                                 #tags$li ("Fear"),
                                 #tags$li ("Happy"),
                                 #tags$li ("Sad"),
                                 #tags$li ("Surprise"),
                                 #tags$li ("Neutral")
                        )
               ),
               tabPanel(title = h4('Using Demo', style="margin-top: 0;margin-bottom: 5px;"),
                        HTML('<iframe width="90%" height="315" style="max-width: 560px; margin:auto; display:block;" src="https://www.youtube.com/embed/Zku5Pg5jSo0" frameborder="0" allowfullscreen></iframe>')
               )
             )
      )
    ),
    br(),
     fluidRow(
        column(width=10, offset = 1,
                box (title = "Face Recognition", width = "100%",
                    tags$video(src="DemoRecording.m4v", type = "video/mp4", controls = NA, style = 'width:100%;height:500px;object-fit: fill;' )
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
