# Front page module

# UI function
tab_intro_ui <- function(id) {

  # Basically not needed. Just kept here to preserve commonality across files.
  ns <- NS(id)

  # Main UI
  fluidPage(
    titlePanel("Image Creation via GAN"),
    fluidRow(
      column(width=7,
             box(title='Business Case', width = NULL,
                 p(style="font-size:110%","Generative adversarial networks (GANs) are deep neural net architectures comprised of two nets, pitting one against the other (thus the “adversarial”).GANs’ potential is huge, because they can learn to mimic any distribution of data. That is, GANs can be taught to create worlds eerily similar to our own in any domain: images, music, speech, prose. They are robot artists in a sense, and their output is impressive – poignant even. 
                   "),
                 p (style = "font-size:110%","One neural network, called the generator, generates new data instances, while the other, the discriminator, evaluates them for authenticity; i.e. the discriminator decides whether each instance of data it reviews belongs to the actual training dataset or not.We’re going to generate hand-written numerals like those found in the MNIST dataset, which is taken from the real world. The goal of the discriminator, when shown an instance from the true MNIST dataset, is to recognize them as authentic."),
                 p (style = "font-size:110%","Meanwhile, the generator is creating new images that it passes to the discriminator. It does so in the hopes that they, too, will be deemed authentic, even though they are fake. The goal of the generator is to generate passable hand-written digits, to lie without being caught. The goal of the discriminator is to identify images coming from the generator as fake."),
                 p (style = "font-size:110%","You can think of a GAN as the combination of a counterfeiter and a cop in a game of cat and mouse, where the counterfeiter is learning to pass false notes, and the cop is learning to detect them. Both are dynamic; i.e. the cop is in training, too (maybe the central bank is flagging bills that slipped through), and each side comes to learn the other’s methods in a constant escalation.")
                 
             )
             
      ),
      column(width=5,
             box(title='Key Benefits', width = NULL,
                 tags$ul (type="square", style="font-size:110%",
                          tags$li ("Making the model intelligent enough to create there own images by learning from training data set."),
                          tags$li ("Can be used in areas of Style Transfer, New images/logos creation."),
                          tags$li ("Creating your own styles for e.g create your own designs for fashion industries.")
                          #tags$li ("Applications in variety of fields like game testing, hiring processes in company, market research, safety of car driver etc.")
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
                                 tags$li ("MNIST"),
                                 tags$li ("Alphabet"),
                                 tags$li ("Logos")
                                 #tags$li ("Happy"),
                                 #tags$li ("Sad"),
                                 #tags$li ("Surprise"),
                                 #tags$li ("Neutral")
                        )
               ),
               tabPanel(title = h4('Using Demo', style="margin-top: 0;margin-bottom: 5px;"),
                        HTML('<iframe width="90%" height="315" style="max-width: 560px; margin:auto; display:block;" src="https://www.youtube.com/embed/i--APp8OwHg" frameborder="0" allowfullscreen></iframe>')
               )
             )
      )
    ),
    br(),
     fluidRow(
        column(width=10, offset = 1,
                box (title = "Image Creation", width = "100%",
                    tags$video(src="MNIST_creation.m4v", type = "video/mp4", controls = NA, style = 'width:100%;height:500px;object-fit: fill;' )
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
