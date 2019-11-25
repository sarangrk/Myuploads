# Front page module

# UI function
tab_intro_ui <- function(id) {

  # Basically not needed. Just kept here to preserve commonality across files.
  ns <- NS(id)

  # Main UI
  fluidPage(
    titlePanel("Object Counting"),
    fluidRow(
      column(width=7,
             box(title='Business Case', width = NULL,
                 p(style="font-size:110%","The objective of the program given is to count object of interest in video frames.

Background subtraction is an efficient way to localize and obtain the centroid of the connected pixels moving on the foreground despite the prior information of the scene.

                   It detects movement or significant differences inside the video frame, when compared to a reference, and remove all the non-significant components (background).

                   Existing model for network will be used to count objects with video examples. "),
                 p (style = "font-size:110%",
"Object Count has the power to deliver an app that will count road traffic based on computer vision and background subtraction methodology. 

It ultimately gives an idea of what the real-time status on street situation is across the road network.

This can be used to count no. of pallets/object of interest in a warehouse to prevent thievery of products in a warehouse.

Object will be detected, and count will be entered in to parking database to track the status of parking slot. 
                    
                    This can be used to inform the real-time parking status and the alternative available space within the Parking slot to the user.")
             )
             
      ),
      column(width=5,
             box(title='Key Benefits', width = NULL,
                 tags$ul (type="square", style="font-size:110%",
			                    tags$li ("Automated and Smart Car Counting/Parking Status"),
			                    tags$li ("Application in variety of field like airports, museum , traffic monitoring, car parking etc"),
                          tags$li ("Improve customer service"),
                          tags$li ("Optimise your building layout and staffing levels"),
                          tags$li ("Compare store performance across a worldwide network"),
                          tags$li ("Calculate your store's conversion ratio")
                 )
             )
      )
    ),
    fluidRow(
      column(width=12,
             tabsetPanel(
               tabPanel(title = h4('About this Demo', style="margin-top: 0;margin-bottom: 5px;"),
                        p(style="font-size:110%;","In this demo, we have developed a system that counts the number of objects in a video.
Here, we have used Background Subtraction which detects a background model and object extraction module are proposed to enhance the object segmentation process that also provide a reliable input to the tracking mechanism (background).
This has been tested on video, image & live stream (web cam) this is achieved using OpenCV & python."),
                        tags$ul (type="square", style="font-size:110%"
                                 #tags$li ("Tiger"),
                                 #tags$li ("Leopard"),
                                 #tags$li ("Elephants"),
                                 #tags$li ("Rhinoceros"),
                                 #tags$li ("Person"),
                                 #tags$li ("Vehicle")
                        )
               ),
               tabPanel(title = h4('Using Demo', style="margin-top: 0;margin-bottom: 5px;"),
                        HTML('<iframe width="90%" height="315" style="max-width: 560px; margin:auto; display:block;" src="https://www.youtube.com/embed/KK7daWOnTKM" frameborder="0" allowfullscreen></iframe>')
               )
             )
      )
    ),
    br(),
     fluidRow(
        column(width=10, offset = 1,
                box (title = "Object Count", width = "100%",
                    tags$video(src="kp_DemoRecording.m4v", type = "video/mp4", controls = NA, style = 'width:100%;height:500px;object-fit: fill;' )
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
