# Front page module

# UI function
hello_tab_ui <- function(id) {

  # Basically not needed. Just kept here to preserve commonality across files.
  ns <- NS(id)

  # Main UI

  fluidPage(

    fluidRow(
      box(width = 6, h3("User Story   test   "), p(),
          "We wanted to explore the following user story:", p(),
          "'As a retailer, I would like to reduce stock of a given level based on a certain number of days into the future while optimizing for margin.'", p(),
          "We used a combination of data simulation, Bayesian Time Series Modelling and Optimisation to determine the optimum markdowns to liquidate stock over a given time period."
      ),
      box(width = 6, h3("Demand Forecasting"), p(),
          "We used Bayesian dynamic regression modelling to estimate the price elasticities from the data.", p(),
          "This allowed us to learn annual, monthly and weekly serasonal components as well as long-term trends from the same model we use to estimate price elasticities.", p(),
          "This means fewer, more robust models with better overall predictions, as well as less pre-processing of data"
      )
    ), # end: fluidRow

    fluidRow(
      box(width = 6, h3("The Data"), p(),
          "The pricing models run for 8 products (Conventional, SynBlend, Synthetic, High Mileage, Wiper Blades, Air Filters, Cabin Filters and Radiators.) 
            Currently the analysis looks at 287 shops (no franchise shops) and new shops that come online will automatically be included unless added to exclusions list. 
            The Start date is set at January 1st , 2018 and new daily data will be added as it arrives.  ",
          p(),
          ""),

      box(width = 6, h3("Price Optimisation"), p(),
          "We used the model to suggest optimal prices to sell a specific number of stock. Training the model gave us the price elasticities for each product and these could be used for the optimisation process.",
          p(),
          "")

    ) # end: fluidRow

  ) # end: fluidPage

} # end

# Server function
hello_tab_server <- function(input, output, session) {

  # Empty, since there is no interactivity on the front page

} # end
