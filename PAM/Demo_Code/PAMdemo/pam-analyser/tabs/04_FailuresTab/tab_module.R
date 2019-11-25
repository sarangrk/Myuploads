# UI
#' @export
failuresTabUI <- function(id) {
  ns <- NS(id)
  
  #### UI #####
  tabPanel(
    failure_profile_tab(),
    
    #### Bar plot of failures over time ####
    fluidPage(
      fluidRow(
        column(12,
               h2("Failure analysis"),
               p("This tab demonstrates the rate at which you expeience asset failures. The page is split into two parts: the top half demonstrates the total number of your asserts which fail, while the bottom half demonstrates how likely an asset is to survive without failure.")
        )
      ),
      hr(),
      fluidRow(
        column(8,
               h3("Number of failures"),
               p('The graph below demonstrates the number of asset failures you have over time and the cost of these is shown to the right. You can select a subset of your data using the controls on the right to investigate the cost and numbers of certain types of failures.')
        ),
        column(4,
               tags$div(class='bs-callout bs-callout-warning',
                        h4('Current failure costs'),
                        uiOutput(ns("costsText"))
               )
        )
      ),
      br(),
      fluidRow(
        sidebarPanel(
          uiOutput(ns("plotFilters"))
        ),
        mainPanel(
          plotOutput(ns("numFailureGraph"))
        )
      ),
      hr(),
      fluidRow(
        column(12,
               h3("Asset survival probability"),
               p('The below graph shows how likely an asset is to survive until a given point in time. You can split the graph by attributes in the dataset using the controls on the right; this allows you to see the effect of a certain attribute on the survival likelihood.')
        )
      ),
      br(),
      fluidRow(
        sidebarPanel(
          uiOutput(ns("kaplanFilters"))
        ),
        mainPanel(
          plotOutput(ns("KaplanPlot"))
        )
      )
    )
  )
}



# Server
#' @export
failuresTab <- function(input, output, session, navpage) {
  #### Render UIs ####
  ## KAPLAN UI ##
  # Update input choices
  output$kaplanFilters <- renderUI({
    InputChoices <- c('NONE')
    
    # Re-load if tab re-loaded and survival object ready
    page_bool <- navpage() == failure_profile_tab()
    if(survivalObjReady() && page_bool)
      InputChoices <- c(InputChoices, survival$partition_variables)
    
    # Output in a div
    tags$div(
      ## Groupings
      selectInput(
        "factor_var01",
        label = "Grouping:",
        choices = InputChoices,
        selected = "NONE"
      ),
      conditionalPanel(
        # condition = "input.factor_var01 != 'NONE'",
        condition = "false",
        selectInput(
          "factor_var02",
          label = "Partition by columns:",
          choices = InputChoices,
          selected = "NONE"
        ),
        selectInput(
          "factor_var03",
          label = "Partition by rows:",
          choices = InputChoices,
          selected = "NONE"
        ),
        conditionalPanel(
          condition = "input.factor_var02 != 'NONE' & input.factor_var03 != 'NONE'",
          selectInput(
            "factor_var04",
            label = "Additional grouping:",
            choices = InputChoices,
            selected = "NONE"
          )
        )
        
      )
    )
  })
  
  ## Set up Filters ##
  # Set up mini-page for filters
  output$plotFilters <- renderUI({
    # Re-load if tab re-loaded and survival object ready
    page_bool <- navpage() == failure_profile_tab()
    if(survivalObjReady() && page_bool){
      select_choices <- attributes_for_partitioning(survival$data)
      
      tags$div(
        selectInput("selectVar1", label = "First filter variable", choices = select_choices),
        conditionalPanel("input.selectVar1 != 'NONE'",
                         selectInput('filterVar1', label="Values to filter on", 
                                     choices=c(), selected="", multiple=TRUE)
        ),
        selectInput("selectVar2", label = "Second filter variable", choices = select_choices),
        conditionalPanel("input.selectVar2 != 'NONE'",
                         selectInput('filterVar2', label="Values to filter on2", 
                                     choices=c(), selected="", multiple=TRUE)
        ),
        selectInput("selectVar3", label = "Third filter variable", choices = select_choices),
        conditionalPanel("input.selectVar3 != 'NONE'",
                         selectInput('filterVar3', label="Values to filter on", 
                                     choices=c(), selected="", multiple=TRUE)
        ),
        numericInput("costOfFailure", label="Cost of a Failure:", value=5000)
      )
    }
  })
  
  # Update tags from drop down and other selections
  observeEvent(c(input$selectVar1, input$selectVar2, input$selectVar3),{
    all_tags <- get_all_possible_tags()
    updateSelectInput(session, "filterVar1", choices=all_tags$input1, label=paste("Values of", input$selectVar1))
    updateSelectInput(session, "filterVar2", choices=all_tags$input2, label=paste("Values of", input$selectVar2))
    updateSelectInput(session, "filterVar3", choices=all_tags$input3, label=paste("Values of", input$selectVar3))
  })
  
  # Update tags based on filters
  observeEvent(input$filterVar1, {
    updateSelectInput(session, "filterVar2", choices=get_reduced_filters_var_two())
  })
  observeEvent(c(input$filterVar1, input$filterVar2), {
    updateSelectInput(session, "filterVar3", choices=get_reduced_filters_var_three())
  })
  
  
  # Functions that filter the available assets and lines based on selections
  # Store all possible tags in a reactive values to check if updates required for each input
  get_all_possible_tags <- reactive({
    if(survivalObjReady()
       && (length(input$selectVar1) > 0)
       && (length(input$selectVar2) > 0)
       && (length(input$selectVar3) > 0))
    {
      tags <- list()
      data <- filterDataFromSelect() # filter data based on tags applied - if none applied gives all tags
      tmp1 <- data.frame()
      tmp2 <- data.frame()
      tmp3 <- data.frame()
      
      if(input$selectVar1 != "NONE")
        tmp1 <- data.frame(data %>% 
                             filter(!is.na(failure_year)) %>% 
                             group_by_(.dots = input$selectVar1) %>% 
                             count(failure_year))
      if(input$selectVar2 != "NONE")
        tmp2 <- data.frame(data %>% 
                             filter(!is.na(failure_year)) %>% 
                             group_by_(.dots = input$selectVar2) %>%
                             count(failure_year))
      if(input$selectVar3 != "NONE")
        tmp3 <- data.frame(data %>%
                             filter(!is.na(failure_year)) %>%
                             group_by_(.dots = input$selectVar3) %>%
                             count(failure_year))
      
      tags$input1 <- if(length(tmp1) != 0) sort(unique(tmp1[, input$selectVar1])) else c()
      tags$input2 <- if(length(tmp2)!= 0) sort(unique(tmp2[, input$selectVar2])) else c()
      tags$input3 <- if(length(tmp3)!= 0) sort(unique(tmp3[, input$selectVar3])) else c()
      return(tags)
    }
  })
  
  get_reduced_filters_var_two <- reactive({
    data <- filterDataFromSelect()
    tmp <- data.frame()
    if(input$selectVar2 != "NONE")
      tmp <- data.frame(data %>% 
                          filter(!is.na(failure_year)) %>%  
                          group_by_(.dots = input$selectVar2) %>% 
                          count(failure_year))
    
    tags <- if(length(tmp)!= 0) sort(unique(tmp[, input$selectVar2])) else c()
    return(tags)
  })
  
  get_reduced_filters_var_three <- reactive({
    data <- filterDataFromSelect()
    tmp <- data.frame()
    if(input$selectVar3 != "NONE")
      tmp <- data.frame(data %>% 
                          filter(!is.na(failure_year)) %>% 
                          group_by_(.dots = input$selectVar3) %>% 
                          count(failure_year))
    
    tags <- if(length(tmp)!= 0) sort(unique(tmp[, input$selectVar3])) else c()
    return(tags)
  })
  
  ## FAILURES PLOT ##
  ## Get correct survival data ##
  filterDataFromSelect <- reactive({
    filterVar1 <- input$filterVar1
    if (length(filterVar1) == 0) {
      survival <- survival
    } else {
      survival$data <- survival$data[survival$data[, input$selectVar1] %in% filterVar1,]
    }
    
    filterVar2 <- input$filterVar2
    if (length(filterVar2) == 0) {
      survival <- survival
    } else {
      survival$data <- survival$data[survival$data[, input$selectVar2] %in% filterVar2,]
    }
    
    filterVar3 <- input$filterVar3
    if (length(filterVar3) == 0) {
      survival <- survival
    } else {
      survival$data <- survival$data[survival$data[, input$selectVar3] %in% filterVar3,]
    }
    return(survival$data)
  })
  
  # Plot the bar chart and time plots of failures ##
  output$numFailureGraph <- renderPlot({
    # Re-load if tab re-loaded and survival object ready
    page_bool <- navpage() == failure_profile_tab()
    if(survivalObjReady() && page_bool){
      # Update data and costs
      data <- filterDataFromSelect()
      costs <- getCostOfFailure()
      
      # Per Year Bar CHart
      ggplot(data[!is.na(data$failure_year),], aes(x=failure_year)) +
        geom_bar(stat="count") +
        theme_bw() +
        ylab("count") +
        xlab("year") +
        ggtitle("Asset failures per year")
    }
  })
  
  ## Savings ##
  getCostOfFailure <- reactive({
    if(length(input$costOfFailure) == 0)
      return(default_cost_unplanned_failure()) # Set to default if page not fully loaded
    
    return(input$costOfFailure)
  })
  
  failure_costs <- reactive({
    # Re-load if tab re-loaded and survival object ready
    page_bool <- navpage() == failure_profile_tab()
    if(survivalObjReady() && page_bool) {
      # Update data and costs
      data <- filterDataFromSelect()
      costs <- getCostOfFailure()
      
      agg_data <- data[!is.na(data$failure_year),] %>%
        summarise(cnt = n()) %>%
        as.data.frame()
      
      total_cost<- sum(agg_data$cnt * costs)
      return(format(round(total_cost), big.mark = ",", decimal.mark= ".", scientific = FALSE))
    } else {
      global_data_load_message(navpage())
      return('')
    }
  })
  
  output$costsText <- renderUI({
    cost <- failure_costs()
    if (cost != '') {
      return(p(tags$strong(paste0("€", cost))))
    } else {
      return(p('Load data to determine costs.'))
    }
  })
  
}



