# Front page module

# UI function
tab_intro_ui <- function(id) {
  
  # Basically not needed. Just kept here to preserve commonality across files.
  ns <- NS(id)
  
  # Main UI
  fluidPage(
    titlePanel("Character-based Text Extraction"),
    fluidRow(
      column(width=8,
             box(title='The business problem', width = NULL,
                 p("Customer gets thousands of hand written forms on a periodic basis, from which they want to extract valuable customer information, to do this manually would be a tideous task,"),
                 p("Think Big Analytics came up with a solution that would use Computer Vision and Deep Neural network to parse and classify the hand written text on character-by-character basis"),
                 p("OCR (optical character recognition) is the recognition of printed or written text characters by a computer. This involves photoscanning of the text character-by-character, analysis of the scanned-in image, and then translation of the character image into character codes, such as ASCII, commonly used in data processing."),
                 p("For further details please check this link:  https://en.wikipedia.org/wiki/Optical_character_recognition")
             ),
             tabBox(title='The business case and using this demo', width = NULL, side = "right", selected = 'Image',
                    tabPanel('Architecture flow diagram',
                             img(src="modelStructure_CNN+LSTM.png", style="max-width: 400px; display:block;")
                            # tags$ol(
                            #   tags$li('You can use the application in the demo tab to see the business solution implemented'),
                            #   tags$li('Select Model Demo tab and click on Start Demo Button to start the demo'),
                            #   tags$li('After that you\'ll select a Smaple Image to be processed using browse'),
                            #   tags$li('Click the Scan button to extract the text from image')
                               
                             
                    ),
                    tabPanel('Image',
                             img(src="text.jpeg", style="max-width: 560px; display:block;")
                    )
             )
      ),
      column(width=4,
             box(title="Case study", width=NULL,
                 p('Text Extraction'),
                 h4("Business challenge"),
                 tags$ul(
                   tags$li('Reading and extracting information from hand written forms was a cumbersome task')),
                 h4("Implementation challenges"),
                 tags$ul(
                   tags$li('Dataset availaility'),
                   tags$li('Identifying handwritten characters'),
                   tags$li('Handling misclassification'),
                   tags$li('Dealing with special characters')
                   
                   ),
                 
                 h4("Approach"),
                 tags$ul(
                   tags$li('New data creation'),
                   tags$li('Image processing and feature identification'),
                   tags$li('Model training using CNN + DNN'),
                   tags$li('Model tuning and evaluation'),
                   tags$li('Validating on actual data')
                  ),
                  
                 h4("Benefits"),
                 tags$ul(
                   #tags$li('Reduction of warehouse search window from weeks to minutes.'),
                   tags$li('Improvement in employee efficiency due to quick text extraction')
                 ),
                 img(src="external_logos/cuda.png", width="85%", style="display: inline-block;vertical-align:top; block; margin: 0 auto; max-width: 50px;"),
                 img(src="external_logos/tensorflow.png", width="85%", style="display: inline-block;vertical-align:top; block; margin: 0 auto; max-width: 50px;"),
                 img(src="external_logos/keras.png", width="85%", style="display: inline-block;vertical-align:top; block; margin: 0 auto; max-width: 50px;"),
                 img(src="external_logos/python.png", width="85%", style="display: inline-block;vertical-align:top; block; margin: 0 auto; max-width: 50px;"),
                 img(src="external_logos/r.jpg", width="85%", style="display: inline-block;vertical-align:top; block; margin: 0 auto; max-width: 50px;")
             )
      )
    )
  )
  
}

# Server function
tab_intro_server <- function(input, output, session) {
  
  # Empty, since there is no interactivity on front page
  
}
