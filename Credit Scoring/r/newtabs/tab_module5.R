# UI function

tab5_model_ui <- function(id) {
  ns <- shiny::NS(id)
  
  shiny::fluidPage(
    shiny::fluidRow(
      shiny::column(
        width = 6,
        shiny::wellPanel(
          shiny::uiOutput(ns("selectgroup")),
          shiny::uiOutput(ns("startmodel"))
        )
      ),
      shiny::column(
        width = 6,
        shiny::br(),
        shiny::uiOutput(ns("selectmodel")),
        shiny::uiOutput(ns("savemodel"))
      )
    ),
    shiny::br(),
    shiny::fluidRow(
      box(
        title = "Model Choice + Statistics",
        width = NULL,
        status = "warning",
        solidHeader = TRUE,
        box(
          title = "Training Statistics",
          width = NULL,
          DT::dataTableOutput(ns("modstats"))
        ),
        box(
          title = "Test Statistics",
          width = NULL,
          DT::dataTableOutput(ns("modstats_test"))
        )
      ),
      box(
        title = "Model Summary",
        width = NULL,
        shiny::verbatimTextOutput(ns("modsum"))
      )
    )
  )
} # end of tab5_model_ui()


# Server function 
tab5_model_server <- function(input, output, session, woe_data, td_ids) {
  
  res_vals <- shiny::reactiveValues()
  temp_vals <- shiny::reactiveValues(excl_vars = NULL)
  sampling <- shiny::reactive({DBI::dbReadTable(con, td_ids()[["sampling_weight_view"]])})
  
  
  hierarchical_forward <- function(
    dat, 
    target, 
    list_hierarchy,
    type="glm", 
    family = "binomial", 
    link = "logit")
    
  {
    prev_form <- formula(eval(paste0(target, "~1")))
    print("prev_form")
    print(prev_form)
    prev_form_txt <- paste0(target, "~1")
    print("prev_form_txt")
    print(prev_form_txt)
    #prev_mod <- eval(parse(text = paste0(type, "(", prev_form_txt, ", data = ","dat", ", family = ", family, "(link = ", link,")",",offset =","offset)")))
    prev_mod <- eval(parse(text = paste0(type, "(", prev_form_txt, ", data = ","dat", ", family = ", family, "(link = ", link,"))")))
    print("prev_mod")
    print(prev_mod)
    
    for (i in list_hierarchy)
    {
      next_form <- update(prev_form,eval(paste0("~ . +", paste(i, collapse = "+"))))
      print("next_form")
      print(next_form)
      upper_mod <- eval(parse(text = paste0(type, "(", "next_form", ",data=dat, family = ",family, "(link = ", link, "))")))
      #upper_mod <- eval(parse(text = paste0(type, "(", "next_form", ",data=dat, offset=offset, family = ",family, "(link = ", link, "))")))
      print("upper_mod")
      print(upper_mod)
      next_mod  <- step(prev_mod, scope = list(lower = prev_mod, upper = upper_mod),direction = "forward")
      prev_form <- next_mod$formula
      prev_mod  <- next_mod
      print("next_mod:")
      print(next_mod)
      print("prev_form")
      print(prev_form)
    }
    
    return(next_mod)
  }
  
  
  sg <- reactive({
    
    coarse_class_dt <- DBI::dbReadTable(con, td_ids()[["coarse_class_tbl"]])
    segment_groups_dt <- DBI::dbReadTable(con, td_ids()[["segment_group_tbl"]])
    sg_labels <- segment_groups_dt %>% 
      select(segment_group, group_label) %>%
      filter(segment_group %in% (coarse_class_dt %>% 
                                   select(segment_group) %>%
                                   unique %>% 
                                   pull)) %>%
      unique %>% 
      arrange(segment_group)
    sg <- as.character(sg_labels$segment_group)
    names(sg) <- sg_labels$group_label
    sg
    
  })
  
  output$selectgroup <- shiny::renderUI({
    
    tbd_vars <- sg()[!(sg() %in% temp_vals$excl_vars)]
    list_sg <- list()
    list_sg[["Processing"]] <- tbd_vars
    list_sg[["Processed"]] <- temp_vals$excl_vars
    
    shiny::selectInput(session$ns("selectgroup"), "Choose Segment Group",choices = list_sg, selectize = TRUE)
    
  })
  
  output$tdata <- shiny::renderTable({woe_data[[input$selectgroup]]$train_dt})
  
  output$startmodel <- shiny::renderUI({
    shiny::req(input$selectgroup)
    shiny::req(woe_data[[input$selectgroup]])
    shiny::actionButton(session$ns("startmodel"), "Start Modeling")
  })
  
  shiny::observeEvent(input$startmodel, {
    res <- list()
    
    target <- "target"
    train  <- woe_data[[input$selectgroup]]$train_dt
    test   <- woe_data[[input$selectgroup]]$test_dt
    
    woe_tbl <- DBI::dbReadTable(con, td_ids()[["coarse_class_woe_tbl"]]) %>%
      filter(segment_group == input$selectgroup) %>% 
      select(variable) %>% unique
    
    list_h <- DBI::dbReadTable(con, td_ids()[["hierarchy_tbl"]]) %>%
      semi_join(woe_tbl, by = c("varname" = "variable")) %>%
      mutate(variable = paste0(varname, "_woe"))
    list_hierarchy <- split(list_h$variable, list_h$priority)
    
    pred_vars_all <- woe_data[[input$selectgroup]]$train_dt %>%
      select(ends_with("_woe")) %>% 
      colnames
    
    dat <- train %>% dplyr::select(target, pred_vars_all)
    
     
    ρ_1 <- sampling() %>% select(rho_1) %>% pull
    print("ρ_1")
    print(ρ_1)
    ρ_0 <- sampling() %>% select(rho_0) %>% pull
    π_1 <- sampling() %>% select(pi_1) %>% pull
    π_0 <- sampling() %>% select(pi_1) %>% pull
    offset <- log((ρ_1 * π_0) / (ρ_0 * π_1))
    print("Calculated offset")
    print(offset)
    
    train <- na.omit(train)
    res$glm     <- eval(parse(text = paste0("glm(", target, " ~ ., data = dat, family = binomial(link = logit))")))
   #res$glm     <- eval(parse(text = paste0("glm(", target, " ~ ., data = dat, family = binomial(link = logit))")))
    res$glm_s   <- hierarchical_forward(dat = train, target, list_hierarchy)
    #res$glm_s   <- hierarchical_forward(dat = train, target, list_hierarchy, offset = calculated_offset)
    res$score   <- fitted(res$glm, type = "response")
    res$score_s <- fitted(res$glm_s, type = "response")
    
    res$score_test   <- predict(res$glm, newdata = test, type = "response")
    res$score_s_test <- predict(res$glm_s, newdata = test, type = "response")
    
    res$roc     <- pROC::roc(train[[target]], res$score)
    res$roc_s   <- pROC::roc(train[[target]], res$score_s)
    
    res$roc_test     <- pROC::roc(test[[target]], res$score_test)
    res$roc_s_test   <- pROC::roc(test[[target]], res$score_s_test)
    
    stat_vals <- c(coords(res$roc, 
                          x = "best",
                          ret = c("threshold", "sensitivity", "specificity", "ppv", "npv"),
                          best.method = "closest.topleft"
    )
    )
    
    stat_vals_s <- c(pROC::coords(res$roc_s, x = "best",
                                  ret = c("threshold", "sensitivity", "specificity", "ppv", "npv"),
                                  best.method = "closest.topleft"
    )
    )
    
    if (stat_vals_s[[1]] == -Inf) 
    {
      print("Forcing threshold to be 0.5")
      stat_vals_s <- c(pROC::coords(res$roc_s, 
                                    x = 0.5, 
                                    input = "threshold",
                                    ret = c("threshold", "sensitivity", "specificity", "ppv", "npv")))
    }
    
    stat_vals_test <- c(coords(res$roc_test, 
                               x = stat_vals[[1]], 
                               input = "threshold",
                               ret = c("threshold", "sensitivity", "specificity", "ppv", "npv")))
    
    stat_vals_s_test <- c(coords(res$roc_s_test, 
                                 x = stat_vals_s[[1]], 
                                 input = "threshold",
                                 ret = c("threshold", "sensitivity", "specificity", "ppv", "npv")))
    
    pred   <- ROCR::prediction(res$score, train[[target]])
    pred_s <- ROCR::prediction(res$score_s, train[[target]])
    perf   <- ROCR::performance(pred, "tpr", "fpr")
    perf_s <- ROCR::performance(pred_s, "tpr", "fpr")
    auc_value   <- abs(res$roc$auc)
    auc_value_s <- abs(res$roc_s$auc)
    ks_value    <- max(attr(perf, "y.values")[[1]] - attr(perf, "x.values")[[1]])
    ks_value_s  <- max(attr(perf_s, "y.values")[[1]] - attr(perf_s, "x.values")[[1]])
    F_value <- 2 * stat_vals[2] * stat_vals[4] / (stat_vals[2] + stat_vals[4])
    F_value_s <- 2 * stat_vals_s[2] * stat_vals_s[4] /
      (stat_vals_s[2] + stat_vals_s[4])
    
    res$class   <- dplyr::if_else(res$score > stat_vals[1], 1, 0)
    res$class_s <- dplyr::if_else(res$score_s > stat_vals_s[1], 1, 0)
    
    res$stat_vals   <- c(stat_vals, auc_value, ks_value, F_value, res$glm$aic)
    res$stat_vals_s <- c(stat_vals_s, auc_value_s, ks_value_s, F_value_s, res$glm_s$aic)
    names(res$stat_vals)[6:9]   <- c("AUC", "KS_value", "F_value", "AIC")
    names(res$stat_vals_s)[6:9] <- c("AUC", "KS_value", "F_value", "AIC")
    res$confusion_matrix   <- caret::confusionMatrix(factor(res$class), factor(train[[target]]))
    res$confusion_matrix_s <- caret::confusionMatrix(factor(res$class_s), factor(train[[target]]))
    
    res$pred <- pred
    res$pred_s <- pred_s
    
    pred_test   <- ROCR::prediction(res$score_test, test[[target]])
    pred_s_test <- ROCR::prediction(res$score_s_test, test[[target]])
    perf_test   <- ROCR::performance(pred_test, "tpr", "fpr")
    perf_s_test <- ROCR::performance(pred_s_test, "tpr", "fpr")
    auc_value_test   <- abs(res$roc_test$auc)
    auc_value_s_test <- abs(res$roc_s_test$auc)
    ks_value_test    <- max(
      attr(perf_test, "y.values")[[1]] - attr(perf_test, "x.values")[[1]]
    )
    ks_value_s_test  <- max(
      attr(perf_s_test, "y.values")[[1]] - attr(perf_s_test, "x.values")[[1]]
    )
    F_value_test     <- 2 * stat_vals_test[2] * stat_vals_test[4] /
      (stat_vals_test[2] + stat_vals_test[4])
    F_value_s_test   <- 2 * stat_vals_s_test[2] * stat_vals_s_test[4] /
      (stat_vals_s_test[2] + stat_vals_s_test[4])
    
    res$class_test   <- dplyr::if_else(res$score_test > stat_vals_test[1], 1, 0)
    res$class_s_test <- dplyr::if_else(
      res$score_s_test > stat_vals_s_test[1], 1, 0
    )
    
    res$stat_vals_test   <- c(
      stat_vals_test, auc_value_test, ks_value_test, F_value_test, res$glm$aic
    )
    res$stat_vals_s_test <- c(
      stat_vals_s_test, auc_value_s_test, ks_value_s_test,
      F_value_s_test, res$glm_s$aic
    )
    names(res$stat_vals_test)[6:9]   <- c("AUC", "KS_value", "F_value", "AIC")
    names(res$stat_vals_s_test)[6:9] <- c("AUC", "KS_value", "F_value", "AIC")
    res$confusion_matrix_test <- caret::confusionMatrix(
      factor(res$class_test), factor(test[[target]])
    )
    res$confusion_matrix_s_test <- caret::confusionMatrix(
      factor(res$class_s_test), factor(test[[target]])
    )
    
    res$pred_test <- pred_test
    res$pred_s_test <- pred_s_test
    
    res_vals[[input$selectgroup]] <- res
    
    output$modstats <- DT::renderDataTable({
      
      shiny::req(input$selectmodel)
      shiny::req(res_vals[[input$selectgroup]]$stat_vals)
      stat_vals <- rbind(
        res_vals[[input$selectgroup]]$stat_vals,
        res_vals[[input$selectgroup]]$stat_vals_s
      )
      output <- data.frame(model_type = c("full", "forward"), stat_vals)
      
      datatable(
        output,
        selection = "none",
        options = list(dom = "t")
      ) %>% DT::formatRound(2:10, 2) %>% DT::formatStyle(
        "model_type",
        target = "row",
        backgroundColor = DT::styleEqual(c(input$selectmodel), c("orange"))
      )
    })
    
    output$selectmodel <- shiny::renderUI({
      shiny::req(res_vals[[input$selectgroup]])
      
      if (is.null(res_vals[[input$selectgroup]]$model_select)) {
        shiny::selectInput(
          session$ns("selectmodel"),
          "Select Model",
          choices = c("full", "forward"),
          selected = "forward"
        )
      } else{
        shiny::selectInput(
          session$ns("selectmodel"),
          "Select Model",
          choices = c("full", "forward"),
          selected = res_vals[[input$selectgroup]]$model_select
        )
      }
    })
    
    output$savemodel <- shiny::renderUI({
      shiny::req(res_vals[[input$selectgroup]])
      shiny::actionButton(session$ns("savemodel"), "Save Model")
    })
    
    shiny::observeEvent(input$savemodel, {
      res_vals[[input$selectgroup]]$model_select <- input$selectmodel
      
      excl <- temp_vals$excl_vars
      temp_vals$excl_vars <- sg()[sg() %in% c(excl, input$selectgroup)]
    })
    
    output$modsum <- shiny::renderPrint({
      shiny::req(input$selectmodel)
      shiny::req(res_vals[[input$selectgroup]])
      
      if (input$selectmodel == "full") {
        summary(res_vals[[input$selectgroup]]$glm)
      } else{
        summary(res_vals[[input$selectgroup]]$glm_s)
      }
    })
    
    output$modstats_test <- DT::renderDataTable({
      shiny::req(input$selectmodel)
      shiny::req(res_vals[[input$selectgroup]]$stat_vals_test)
      
      stat_vals_test <- rbind(
        res_vals[[input$selectgroup]]$stat_vals_test,
        res_vals[[input$selectgroup]]$stat_vals_s_test
      )
      output <- data.frame(model_type = c("full", "forward"), stat_vals_test)
      
      datatable(
        output, selection = "none", options = list(dom = "t")
      ) %>% DT::formatRound(2:10, 2) %>% DT::formatStyle(
        "model_type",
        target = "row",
        backgroundColor = DT::styleEqual(c(input$selectmodel), c("orange"))
      )
    })
  })
  
  return(res_vals)
} # end of tab5_model_server()
