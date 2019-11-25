# Front page module

introTabUI <- function(id) {
  
  ns <- NS(id)
  
  tabPanel(
    'Introduction',
    fluidPage(
      titlePanel("Predictive Asset Maintenance"),
      fluidRow(
        column(width=8,
               box(title='The business problem', width = NULL,
                   p("Businesses have assets that they depend on for normal operation of their business, but these can fail and prevent the business from operating normally. This problem is essentially balancing the risk of a possibly expensive unplanned failure with the cost of regular maintenance; with traditional methods money can be saved on regular maintenance often at the expense of a higher risk of failure. However, not all assets are the same and predicting which ones are the most likely to fail allows effort to be focused in the right place; this project aims to predict asset failures so that you can minimise costs and increase availability of your assets."),
                   p('Assets can be many different objects that your business relies on: trucks, refrigeration units, robotic arms, heavy machinery, internet routers, or many many other items.'),
                   p('Once failures can be predicted there are many use-cases that can be studied to make use of these predictions. Optimising your repair teams to reduce downtime, avoiding unneeded maintenance, finding common causes of failures, studying which alerts most often lead to failures, etc.'),
                   p("We have performed many similar use-cases in the transport, energy, telecommunication and other industries. ")
               ),
               tabBox(title='How to use this demo', width = NULL, side = "right", selected = 'Video',
                      tabPanel('Data format',
                               p("There are a few types of data that this demo needs and these are described below."),
                               data_description()
                      ),
                      tabPanel('Instructions',
                               tags$ol(
                                 tags$li('Select some data to use in the "Load Data" tab. This can be our data or your own.'),
                                 tags$li('Wait a moment or two for the data to upload and the machine learning to run.'),
                                 tags$li('Optinally, choose the variables and machine learning algorithms to run in the "Training" tab.'),
                                 tags$li('Find out how many and how your assets fail over time in the "Failures" tab.'),
                                 tags$li('Discover the factors which are most likey to influence asset failures in the "Causes" tab.'),
                                 tags$li('Find the right point at which to repair assets for your business and calculate the amount of money you could save with predicitive asset maintenance in the "Optimise" tab.'),
                                 tags$li('Finally, use the "Results" tab to work out which of your assets need to be repaired and send teams to repair them.')
                               )
                      ),
                      tabPanel('Video',
                               tags$video(
                                 src = "https://videosdstb.s3.amazonaws.com/generic_pam.mp4",
                                 type = "video/mp4",
                                 width = "90%",
                                 style = 'max-width:600px; margin:auto; display:block; box-shadow: 7px 7px 7px #888888; margin-bottom:15px; margin-top:10px;',
                                 controls = NA
                               )
                      )
               )
        ),
        column(width=4,
               box(title="Case study", width=NULL,
                   p('A railway company wanted to understand if it was possible to predict railway switch failures, leveraging IoT and other maintenance and faults data.'),
                   p('The ability to forecast maintenance failures would: reduce train disruptions, improve operation teams ability to react, increase customer satisfaction and save the business from the costs of inefficient responses and the unexpected.'),
                   h4("Key benefits"),
                   tags$ul(
                     tags$li('Found key failures patterns and key failures signals'),
                     tags$li('Predict with more than 80% accuracy failures within 30/90/180/360 days'),
                     tags$li('Potential savings of €2-5m per year'),
                     tags$li('Produced simple website for business analysts to use')
                   ),
                   img(src="workflow.png", width="85%", style="display: block; margin: 0 auto; max-width: 350px;")
               )
        )
      )
    )
  )
}

data_description <- function() {
  tags$ul(
    tags$li(tags$strong('Asset dataset'), ' - This is data that describes the asset',
            tags$ul(
              tags$li(tags$strong('asset_id'), ' - A unique asset identfier'),
              tags$li(tags$strong('start_date'), ' - Date when data on the asset begins'),
              tags$li(tags$strong('end_date'), ' - Date when data on the asset ends'),
              tags$li(tags$strong('longitude'), ' - Needed for mapping data (optional)'),
              tags$li(tags$strong('latitude'), ' - Needed for mapping data (optional)'),
              tags$li('Other variables are treated as asset attributes (see below, optional)')
            )),
    tags$li(tags$strong('Asset repairs'), ' - This details the repairs of assets',
            tags$ul(
              tags$li(tags$strong('asset_id'), ' - A unique asset identfier'),
              tags$li(tags$strong('event_id'), ' - A unique event identfier'),
              tags$li(tags$strong('event_date'), ' - Date when the asset was replaced (failed)'),
              tags$li(tags$strong('installed_date'), ' - Date when the asset was installed')
              # tags$li('Other variables are treated as event attributes (see below, optional)')
            )),
    tags$li(tags$strong('Asset replacements'), ' - This is a list of times when assets have been replaced (failed)',
            tags$ul(
              tags$li('Follows the same format as the asset repairs data')
            )),
    tags$li(tags$strong('Planned maintenance'), ' - This describes if the reapir or replacement was planned or not',
            tags$ul(
              tags$li(tags$strong('event_id'), ' - A unique event identfier'),
              tags$li(tags$strong('planned'), ' - Boolean indicating if the mainainance was planned or not')
            )),
    tags$li(tags$strong('Additional asset attributes'), ' - This gives additional infomation about assets',
            tags$ul(
              tags$li(tags$strong('asset_id'), ' - A unique asset identfier'),
              tags$li('Other variables are treated as asset attributes; these are things that could influence its survival time, such as: its material, its normal use (heavy, light), the weather it is exposed to, etc.')
            ))
  )
}




# Server function
# tab_0_server <- function(input, output, session) {
# 
#   # Empty, since there is no interactivity on the front page
# 
# } # end: tab_0_server()
