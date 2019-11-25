# Front page module

# UI function
tab_intro_ui <- function(id) {

  # Basically not needed. Just kept here to preserve commonality across files.
  ns <- NS(id)

  # Main UI
  fluidPage(
    titlePanel("People Counting"),
    fluidRow(
      column(width=7,
             box(title='Business Case', width = NULL,
                 p(style="font-size:110%","People counting technology forms the basis for a range of high-tech solutions, including retail analytics, queue management, building management and security applications. Often with a very fast payback time and a high ROI. The information our people counters can be used at all levels of businesses, from planning front-line activities to setting overall strategy.
                                           People counting helping stores to identify customer trends, conversion rates, predict staffing requirements, and more. These combine to deliver significant savings for our end-users. 
                   "),
                 p (style = "font-size:110%","Counting people at airports delivers valuable data, helping airport operators to identify where there are new retail opportunities and to take this data to prospective partners. We can also create an analysis patterns across the building, identifying areas of congestion so this can be resolved. In a competitive market where all business is valuable, chances like this to create a pleasant environment for customers cannot be wasted

                                              Keeping track of the number of visitors to railway stations is hugely valuable for operators, as it works hand in hand with attracting more retailers to the area, making the station a destination in itself, not just somewhere to travel through. People counters enables us to count numbers, as well as analyse  patterns and movement throughout the building, while also giving us the ability to improve the use of the space available, creating a pleasant environment and attracting more visitors.")
             )
             
      ),
      column(width=5,
             box(title='Key Benefits', width = NULL,
                 tags$ul (type="square", style="font-size:110%",
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
                        p(style="font-size:110%;", "In this demo, we developed a deep learning system based on moments to count people for mall, Airport, railway station,etc"),
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
                        HTML('<iframe width="90%" height="315" style="max-width: 560px; margin:auto; display:block;" src="https://www.youtube.com/embed/ZfSAO_b-HyM" frameborder="0" allowfullscreen></iframe>')
               )
             )
      )
    ),
    br(),
     fluidRow(
        column(width=10, offset = 1,
                box (title = "People Count", width = "100%",
                    tags$video(src="kp_DemoRecordingPeople.m4v", type = "video/mp4", controls = NA, style = 'width:100%;height:500px;object-fit: fill;' )
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
