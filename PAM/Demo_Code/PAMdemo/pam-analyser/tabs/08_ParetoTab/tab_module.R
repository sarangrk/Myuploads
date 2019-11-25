# UI for failure models
#' @export
paretoTabUI <- function(id) {
  
  ns <- NS(id)
  
  # Tab consists of Panel with controls and output
  tabPanel(
    fluidPage(
                            plotOutput("pareto_chart")
           
    )
  )
}


# Server
#' @export
paretoTab <- function(input, output, session, navpage) {
  
  
  output$pareto_chart <- renderPlot({
    
    # Fitting Labels 
    par(las=2) # make label text perpendicular to axis
    par(mar=c(5,8,4,2)) # increase y-axis margin.
    
    barplot(height = defects$freq, horiz = TRUE, names.arg  = defects$type, xlab = "Frequency")
    
    
  })
  
  
  
  
  
}

