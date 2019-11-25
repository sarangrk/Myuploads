# Insights Tab UI
#' @export
causesTabUI <- function(id) {
  
  ns <- NS(id)
  
  tabPanel('Causes',
           fluidPage(
             fluidRow(
               column(12,
                      h2('Failure causes'),
                      p('This page aims to help you understand the factors that contribute to your asset failures and so understand the root cause.')
               )
             ),
             hr(),
             fluidRow(
               column(12,
                      h3('Variable importance'),
                      p('Here we show which varaibles are best in our machine learning models to predict failures of your assets. The various models will show different variables are more or less important, as each of the models will use the variables in different ways.')
               )
             ),
             br(),
             fluidRow(
               # column(4,
               #        h4('Linear/Cox'),
               #        plotOutput('variable_importance_linear')
               # ),
               # column(4,
               #        h4('Decision Tree'),
               #        plotOutput('variable_importance_dt')
               # ),
               # column(4,
               #        h4('Random forest'),
               #        plotOutput('variable_importance_rf')
               # )
               column(12,
                      plotOutput(ns('importance_plots'))
               )
             )
           )
  )
}



# Server
#' @export
causesTab <- function(input, output, session) {
  #### Observe Inputs and Process Raw Data ####
  
  variable_importance_linear <- reactive({
    if (!survival_models$linear_complete) return()
    
    var_importance_vec <- abs(exp(coef(survival_models$linear)))
    vars <- names(var_importance_vec)
    var_importance_df <- data.frame(Variable=vars, Importance=var_importance_vec, stringsAsFactors=FALSE)
    
    plot <- ggplot(aes(x=Variable, y=Importance), data=var_importance_df) + geom_bar(stat='identity') +
      theme(axis.text.x=element_text(angle=90, hjust=1, vjust=0.5)) +
      ggtitle("Cox model variable importance") +
      theme(axis.text = element_text(size = 15)) +
      theme(axis.title = element_text(size = 15)) +
      # theme(text = element_text(size = 20)) +
      theme(plot.title = element_text(lineheight=.8, face="bold"))
    return(set_panel_size(plot, height = unit(12, "cm")))
  })
  
  variable_importance_dt <- reactive({
    if (!survival_models$dt_complete) return()
    
    var_importance_df <- as.data.frame(abs(varImp(survival_models$dt$rpart)))
    vars <- row.names(var_importance_df)
    row.names(var_importance_df) <- NULL
    var_importance_df <- cbind(vars, var_importance_df)
    colnames(var_importance_df) <- c("Variable", "Importance")
    
    plot <- ggplot(aes(x=Variable, y=Importance), data=var_importance_df) + geom_bar(stat='identity') +
      theme(axis.text.x = element_text(angle=90, hjust=1, vjust=0.5)) +
      ggtitle("Decision tree variable importance") +
      theme(axis.text = element_text(size = 15)) +
      theme(axis.title = element_text(size = 15)) +
      # theme(text = element_text(size = 20)) +
      theme(plot.title = element_text(lineheight=.8, face="bold"))
    return(set_panel_size(plot, height = unit(12, "cm")))
  })
  
  variable_importance_rf <- reactive({
    if (!survival_models$rf_complete) return()
    
    vars <- names(survival_models$rf$importance)
    var_importance_df <- data.frame(Variable=vars, Importance=abs(survival_models$rf$importance), stringsAsFactors=FALSE)
    print(var_importance_df)
    
    plot <- ggplot(aes(x=Variable, y=Importance), data=var_importance_df) + geom_bar(stat='identity') +
      theme(axis.text.x = element_text(angle=90, hjust=1, vjust=0.5)) +
      ggtitle("Random forest variable importance") +
      theme(axis.text = element_text(size = 15)) +
      theme(axis.title = element_text(size = 15)) +
      # theme(text = element_text(size = 20)) +
      theme(plot.title = element_text(lineheight=.8, face="bold"))
    return(set_panel_size(plot, height = unit(12, "cm")))
  })
  
  output$importance_plots <- renderPlot({
    columns = as.numeric(survival_models$linear_complete) + as.numeric(survival_models$dt_complete) + as.numeric(survival_models$rf_complete)
    
    if (columns == 0) return()
    
    plots <- vector(mode="list")
    if (survival_models$linear_complete) plots[[length(plots)+1]] <- variable_importance_linear()
    if (survival_models$dt_complete) plots[[length(plots)+1]] <- variable_importance_dt()
    if (survival_models$rf_complete) plots[[length(plots)+1]] <- variable_importance_rf()
    
    plots[['nrow']] <- 1
    plots[['align']] <- 'h'
    
    do.call('plot_grid', plots)
    
  }, height = 600)
  
}



