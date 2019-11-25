# UI function

tab6_md_ui <- function(id) {
  ns <- shiny::NS(id)

  shiny::fluidPage(
    shiny::fluidRow(
      shiny::wellPanel(
        shiny::fluidRow(
          shiny::column(
            width = 6,
            shiny::uiOutput(ns("sg_viewer"))
          ),
          shiny::column(
            width = 6,
            shiny::uiOutput(ns("save_diagnostics")),
            shiny::uiOutput(ns("save_roc_lift"))
          )
        )
      )
    ),
    shiny::fluidRow(
      box(
        title = "Model Diagnostics",
        width = NULL,
        solidHeader = TRUE,
        status = "warning",
        collapsible = TRUE,
        collapsed = TRUE,
        shiny::column(
          width = 6,
          shiny::plotOutput(ns("md1")),
          shiny::plotOutput(ns("md2"))
        ),
        shiny::column(
          width = 6,
          shiny::plotOutput(ns("md3")),
          shiny::plotOutput(ns("md4"))
        )
      ),
      shiny::br()
    ),
    shiny::fluidRow(
      box(
        title = "Other Results",
        width = NULL,
        solidHeader = TRUE,
        status = "warning",
        collapsible = TRUE,
        collapsed = FALSE,
        shiny::column(
          width = 6,
          shiny::wellPanel(
            shiny::h4("Train"),
              shiny::plotOutput(ns("roc")),
              shiny::plotOutput(ns("lift")),
              shiny::verbatimTextOutput(ns("conf_mat"))
          )
        ),
        shiny::column(
          width = 6,
          shiny::wellPanel(
          shiny::h4("Test"),
          shiny::plotOutput(ns("roc_test")),
          shiny::plotOutput(ns("lift_test")),
          shiny::verbatimTextOutput(ns("conf_mat_test")))
        )
      )
    )
  )
} # end of tab6_md_ui()


# Server function 
tab6_md_server <- function(input, output, session, res, td_ids) {
  sg_modeled <- shiny::reactive({
    sg_with_modselect <- sapply(res, function(x) "model_select" %in% names(x))

    sg_mods <- names(sg_with_modselect)[sg_with_modselect]
    segment_groups_dt <- DBI::dbReadTable(con, td_ids()[["segment_group_tbl"]])

    sg_labels <- segment_groups_dt %>% select(segment_group, group_label) %>%
      unique %>% arrange(segment_group) %>% filter(segment_group %in% sg_mods)
    sg <- as.character(sg_labels$segment_group)
    names(sg) <- sg_labels$group_label

    print(sg)

    sg
  })

  output$sg_viewer <- shiny::renderUI({
    shiny::selectInput(
      session$ns("sg_viewer"),
      "Select Segment Group",
      choices = sg_modeled()
    )
  })

  output$save_diagnostics <- shiny::renderUI({
    shiny::req(res)
    print(paste0("selected model type: ", res[[input$sg_viewer]]$model_select))

    shiny::actionButton(
      session$ns("save_diagnostics"), "Save Model Diagnostics"
    )
  })

  glm_suffix <- shiny::reactive({
    if (res[[input$sg_viewer]]$model_select == "forward"){
      "_s"
    } else {
      ""
    }
  })

  output$md1 <- shiny::renderPlot({
    shiny::req(input$sg_viewer)
    plot(res[[input$sg_viewer]][[paste0("glm", glm_suffix())]], 1)
  })

  output$md2 <- shiny::renderPlot({
    shiny::req(input$sg_viewer)
    plot(res[[input$sg_viewer]][[paste0("glm", glm_suffix())]], 2)
  })

  output$md3 <- shiny::renderPlot({
    shiny::req(input$sg_viewer)
    plot(res[[input$sg_viewer]][[paste0("glm", glm_suffix())]], 3)
  })

  output$md4 <- shiny::renderPlot({
    shiny::req(input$sg_viewer)
    plot(res[[input$sg_viewer]][[paste0("glm", glm_suffix())]], 4)
  })

  output$save_roc_lift <- shiny::renderUI({
    shiny::req(res)
    shiny::actionButton(session$ns("save_roc_lift"), "Save Other Plots")
  })

  output$conf_mat <- shiny::renderPrint({
    shiny::req(res[[input$sg_viewer]]$pred)
    shiny::req(input$sg_viewer)
    print(res[[input$sg_viewer]][[paste0("confusion_matrix", glm_suffix())]])
  })

  roc_chart <- shiny::reactive({
    shiny::req(input$sg_viewer)
    perf <- ROCR::performance(
      res[[input$sg_viewer]][[paste0("pred", glm_suffix())]],
      "tpr",
      "fpr"
    )
  })

  output$roc <- shiny::renderPlot({
    shiny::req(res[[input$sg_viewer]]$pred)
    plot(roc_chart(), main = "ROC Curve")
  })

  lift_chart <- shiny::reactive({
    shiny::req(input$sg_viewer)
    ROCR::performance(
      res[[input$sg_viewer]][[paste0("pred", glm_suffix())]],
      "lift",
      "rpp"
    )
  })

  output$lift <- shiny::renderPlot({
    shiny::req(input$sg_viewer)
    shiny::req(res[[input$sg_viewer]]$pred)
    plot(lift_chart(), main = "Lift Curve")
  })

  output$conf_mat_test <- shiny::renderPrint({
    shiny::req(input$sg_viewer)
    shiny::req(res[[input$sg_viewer]]$pred)
    print(
      res[[input$sg_viewer]][[paste0(
        "confusion_matrix", glm_suffix(), "_test")
      ]])
  })

  roc_chart_test <- shiny::reactive({
    shiny::req(input$sg_viewer)
    ROCR::performance(
      res[[input$sg_viewer]][[paste0(
        "pred", glm_suffix(), "_test"
      )]],
      "tpr",
      "fpr"
    )
  })

  output$roc_test <- shiny::renderPlot({
    shiny::req(input$sg_viewer)
    shiny::req(res[[input$sg_viewer]]$pred)
    plot(roc_chart_test(), main = "ROC Curve")
  })

  lift_chart_test <- shiny::reactive({
    shiny::req(input$sg_viewer)
    ROCR::performance(
      res[[input$sg_viewer]][[paste0("pred", glm_suffix(), "_test")]],
      "lift",
      "rpp"
    )
  })

  output$lift_test <- shiny::renderPlot({
    shiny::req(input$sg_viewer)
    shiny::req(res[[input$sg_viewer]]$pred)
    plot(lift_chart_test(), main = "Lift Curve")
  })

  shiny::observeEvent(input$save_diagnostics, {
    print(sg_modeled())

    foldername <- paste(
      input$sg_viewer,
      names(sg_modeled()[sg_modeled() == input$sg_viewer]),
      sep = "_"
    )
    foldername <- gsub('[\\/|*?:<>"]}| $', "", foldername)
    dirname <- paste0(charts_savedir, "/", foldername)

    dir.create(paste0(charts_savedir, "/", foldername))
    dir.create(paste0(charts_savedir, "/", foldername, "/model_diagnostics"))

    for (i in 1:4) {
      ggsave(
        paste0("Model Diagnostics ", i, ".png"),
        path = paste0(dirname, "/model_diagnostics"),
        plot = plot(res[[input$sg_viewer]]$glm_s, i)
      )
    }

    session[["sendCustomMessage"]](
      type = "testmessage",
      message = "Saved Plots"
    )
  })

  shiny::observeEvent(input$save_roc_lift, {
    foldername <- paste(
      input$sg_viewer,
      names(sg_modeled()[sg_modeled() == input$sg_viewer]),
      sep = "_"
    )
    foldername <- gsub('[\\/|*?:<>"]}| $', "", foldername)
    dirname <- paste0(charts_savedir, "/", foldername)

    dir.create(paste0(charts_savedir, "/", foldername))
    dir.create(paste0(charts_savedir, "/", foldername, "/other"))

    ggsave(
      "Train - ROC Chart.png",
      path = paste0(dirname, "/other"),
      plot = plot(roc_chart(),
      main = "ROC curve")
    )
    ggsave(
      "Train - Lift Curve.png",
      path = paste0(dirname, "/other"),
      plot = plot(lift_chart(),
      main = "lift curve")
    )

    ggsave(
      "Test - ROC Chart.png",
      path = paste0(dirname, "/other"),
      plot = plot(roc_chart_test(),
      main = "ROC curve")
    )
    ggsave(
      "Test - Lift Curve.png",
      path = paste0(dirname, "/other"),
      plot = plot(lift_chart_test(),
      main = "lift curve")
    )

    session[["sendCustomMessage"]](
      type = "testmessage",
      message = "Saved Plots"
    )
  })
} # end of tab6_md_server()
