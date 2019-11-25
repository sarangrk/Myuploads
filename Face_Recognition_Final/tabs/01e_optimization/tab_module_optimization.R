# Front page module

# UI function
tab_optimization_ui <- function(id) {
  # Main UI
  fluidPage(
    useShinyjs(),
    titlePanel("Optimization"),
    fluidRow(column(width = 12,
                    box (
                      width = NULL,
                      p(
                        style = "font-size:110%",
                        'Object detection can assist in video based surveillance by generating alerts for different situations e.g. poachers identification, animal detection etc. This capability allows to significantly reduce the cost of resources to manually monitor the natural environments.'
                      ),
                      p(
                        style = "font-size:110%",
                        'This page allows you to examine the advantage of using object detection system to replace the existing monitoring methods.'
                      ),
                      p(
                        style = "font-size:110%",
                        'Here we are simulating a very simple situation to estimate monitoring cost reduction.
                        Specify the number of cameras, number of human resources and per day cost for a resource to manually monitor the environment.
                        From the slider you can also change the time period for simulation.'
                      )
                      ))),
    fluidRow (
      sidebarPanel(
        numericInput("camera_systems", label = "Number of camera systems for surveillance", value =
                       500),
        numericInput(
          "secuirty_experts_count",
          label = "Number of resources for monitoring",
          value =
            1500
        ),
        numericInput (
          "average_cost_per_resource",
          label = "Average daily cost per resource",
          value =
            96
        ),
        sliderInput(
          "time_frame",
          label = "Monitoring time frame (days)",
          value = 45,
          max = 365,
          min = 0
        ),
        actionButton('optimize', 'Run optimisation')
      ),
      mainPanel(fluidRow(column(6,
                                conditionalPanel(
                                  'input.optimize != 0',
                                  tags$div(
                                    class = 'bs-callout bs-callout-warning',
                                    h4('Traditional Monitoring vs Deep Learning Approach'),
                                    uiOutput("stats")
                                  )
                                )
      )))
    )
                      )
}

# Server function
tab_optimization_server <- function(input, output, session) {
  output$stats <- renderUI({
    manaul_cost <-
      input$secuirty_experts_count * input$average_cost_per_resource * input$time_frame
    deepllearning_resources <- input$camera_systems %/% 100
    deeplearning_monitoring_cost <-
      (deepllearning_resources + 1) * 3 * input$average_cost_per_resource * input$time_frame
    save_amount <- manaul_cost - deeplearning_monitoring_cost
      
      return(tags$div(class = 'bs-callout bs-callout-warning',
                      tags$ul(
                        tags$li(paste0(
                          "Cost for Manaul Monitoring: ",
                          format(manaul_cost, big.mark = ",")
                        )),
                        tags$li(paste0(
                          "Cost using Deep Learning: ",
                          format(deeplearning_monitoring_cost, big.mark = ",")
                        )),
                        tags$li(tags$b(
                          paste0(
                            "Total Amount Saved: ",
                            format(save_amount, big.mark = ",")
                          )
                        ))
                      )))
  })
  
  
}
