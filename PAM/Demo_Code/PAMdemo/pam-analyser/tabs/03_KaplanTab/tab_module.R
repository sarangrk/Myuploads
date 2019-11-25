# Kaplan Server Functions
# Server - Return Kaplan plot
#' @export
kaplanTab <- function(input, output, session, navpage) {
  
  # Set up Kaplan features and determine formula
  kaplanFormula <- reactive({
    KMFeatures <- as.character(c(input$factor_var01, input$factor_var02, input$factor_var03, input$factor_var04))
    KMFeatures <- featureCheck(KMFeatures)
    KMFeatures <- paste(KMFeatures[KMFeatures != "NONE"], collapse = " + ")
    
    if(KMFeatures == ""){
      KMFormula <- as.formula("Surv(survival_time, event_occurred) ~ 1")
    } else {
      KMFormula <- as.formula(paste("Surv(survival_time, event_occurred) ~", KMFeatures))
    }
  })
  
  # Reset Features if higher level groupings are NONE
  featureCheck <- function(features) {
    if(length(features) == 0)
      return()
    
    # If top feature is NONE set others to NON
    if(features[1] == "NONE")
      return(c("NONE", "NONE", "NONE", "NONE"))
    
    # If factors 2 or 3 set to NONE - reset factor 4
    if(features[2] == "NONE" || features[3] == "NONE") {
      features[4] <- "NONE"
    }
    return(features)
  }
  
  
  # KM plots
  output$KaplanPlot <- renderPlot({
    # Re-load if tab re-loaded and survival object ready
    page_bool <- navpage() == failure_profile_tab()
    
    # Return if survival does not exist
    if(length(survival$completed)==0 || !page_bool)
      return()
    
    # Get formula, fit and plot
    KMFormula <<- kaplanFormula()
    surv.mult <- survfit(KMFormula, data=survival$data)
    
    # create SurvivalFrame
    data.km <- createSurvivalFrame(surv.mult)
    
    if(KMFormula == "Surv(survival_time, event_occurred) ~ 1"){
      
      ggKM <- ggplot(data = data.km) +
        geom_step(aes(x = time, y = surv), direction = "hv") +
        geom_text(hjust = 0, label = nrow(survival$data), x = 0, y = 0) +
        coord_cartesian(ylim = c(0,1)) +
        theme_bw() +
        ylab("Probability of Survival") +
        xlab("Days") +
        theme(legend.position = "bottom")
      
      ggKM
      
    } else {
      
      # Identify number of strata
      N <- str_count(as.character(KMFormula[3]), "\\+") + 1
      
      # split strata variable
      data.km$split01 <- factor(paste(str_trim(str_split_fixed(str_split_fixed(data.km$strata, ",", 4)[,1],"=",2)[,2]),str_trim(str_split_fixed(str_split_fixed(data.km$strata, ",", 4)[,4],"=",2)[,2]),sep=" - "))
      data.km$split02 <- factor(str_trim(str_split_fixed(str_split_fixed(data.km$strata, ",", 4)[,2],"=",2)[,2]))
      data.km$split03 <- factor(str_trim(str_split_fixed(str_split_fixed(data.km$strata, ",", 4)[,3],"=",2)[,2]))
      
      # calculate number of observations per strata
      data.km.observations <- data.km %>%
        group_by(strata, split01, split02, split03) %>%
        summarise(obs = max(n.risk)) %>%
        as.data.frame()
      
      if(N == 1){
        
        combinations <- expand.grid(levels(data.km$split01))
        colnames(combinations) <- c("split01")
        ttt <- merge(combinations, data.km.observations, by = c("split01"), all.x = TRUE)
        ttt[is.na(ttt$obs),"obs"] <- 0
        
        ggKM <- ggplot(data = data.km, aes(colour = split01, group = split01)) +
          ylab("Probability of Survival") +
          xlab("Days") +
          geom_step(aes(x = time, y = surv), direction = "hv") +
          geom_text(data = ttt, hjust = 0, aes(label = obs,colour = split01, y = c(0), x = rep(seq(0,62.5*(nlevels(data.km$split01)-1), by = 62.5),1)) ) +
          theme_bw() +
          theme(legend.position = "top",
                legend.title = element_blank())
        
      } else if (N == 2) {
        
        combinations <- expand.grid(levels(data.km$split01),levels(data.km$split02))
        colnames(combinations) <- c("split01","split02")
        ttt <- merge(combinations, data.km.observations, by = c("split01","split02"), all.x = TRUE)
        ttt[is.na(ttt$obs),"obs"] <- 0
        
        ggKM <- ggplot(data = data.km, aes(colour = split01, group = split01))
        
        if(input$factor_var02 != "NONE"){
          ggKM <- ggKM + facet_grid(. ~ split02)
        }
        if(input$factor_var03 != "NONE"){
          ggKM <- ggKM + facet_grid(split02 ~ .)
        }
        
        ggKM <- ggKM +
          ylab("Survival") +
          xlab("Tage") +
          geom_step(aes(x = time, y = surv), direction = "hv") +
          geom_text(data = ttt, hjust = 0, aes(label = obs,colour = split01, y = c(0), x = rep(seq(0,62.5*(nlevels(data.km$split01)-1), by = 62.5),nlevels(data.km$split02))) ) +
          theme_bw() +
          theme(legend.position = "top",
                legend.title = element_blank())
        
      } else if (N == 3)  {
        
        combinations <- expand.grid(levels(data.km$split01),levels(data.km$split02),levels(data.km$split03))
        colnames(combinations) <- c("split01","split02","split03")
        ttt <- merge(combinations, data.km.observations, by = c("split01","split02","split03"), all.x = TRUE)
        ttt[is.na(ttt$obs),"obs"] <- 0
        
        ggKM <- ggplot(data = data.km, aes(colour = split01, group = split01)) +
          #  facet_wrap( ~ split02) +
          facet_grid(split03 ~ split02) +
          ylab("Survival") +
          xlab("Tage") +
          geom_step(aes(x = time, y = surv), direction = "hv") +
          geom_text(data = ttt, hjust = 0, aes(label = obs,colour = split01, y = c(0), x = rep(seq(0,62.5*(nlevels(data.km$split01)-1), by = 62.5),nlevels(data.km$split02)*nlevels(data.km$split03))) ) +
          theme_bw() +
          theme(legend.position = "top",
                legend.title = element_blank())
        
      } else {
        
        combinations <- expand.grid(levels(data.km$split01),levels(data.km$split02),levels(data.km$split03))
        colnames(combinations) <- c("split01","split02","split03")
        ttt <- merge(combinations, data.km.observations, by = c("split01","split02","split03"), all.x = TRUE)
        ttt[is.na(ttt$obs),"obs"] <- 0
        
        ggKM <- ggplot(data = data.km, aes(colour = split01, group = split01)) +
          facet_grid(split02 ~ split03) +
          ylab("Survival") +
          xlab("Tage") +
          geom_step(aes(x = time, y = surv), direction = "hv") +
          geom_text(data = ttt, hjust = 0, aes(label = obs,colour = split01, y = c(0), x = rep(seq(0,62.5*(nlevels(data.km$split01)-1), by = 62.5),nlevels(data.km$split02)*nlevels(data.km$split03))) ) +
          coord_cartesian(ylim = c(0,1)) +
          theme_bw() +
          theme(legend.position = "top",
                legend.title = element_blank())
        
      }
      
      ggKM
      
    }
    
  })
  
}
