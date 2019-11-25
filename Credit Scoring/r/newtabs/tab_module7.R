# UI function

tab7_sc_ui <- function(id) {

  ns <- shiny::NS(id)

  shiny::fluidPage(
    shiny::sidebarLayout(
    shiny::sidebarPanel(
      box(width = NULL, 
      shiny::selectInput(ns("create_combine_sc"),
                         "Create/Edit or Combine Scorecard",
                         choices = c("Create or Edit Scorecard","Combine Scorecards"),
                         selectize = TRUE),
      shiny::conditionalPanel(
        paste0("input['",ns("create_combine_sc"),"'] == 'Create or Edit Scorecard'"),
          shiny::uiOutput(ns("sg_viewer")),
          shiny::uiOutput(ns("scorecard_label")),
          shiny::uiOutput(ns("create_sc"))),
      shiny::conditionalPanel(
        paste0("input['",ns("create_combine_sc"),"'] == 'Combine Scorecards'"),
        shiny::uiOutput(ns("sg_combiner")),
        shiny::uiOutput(ns("combine_sc"))
      ),
      shiny::uiOutput(ns("save_sc")),
      shiny::br(),
      shiny::uiOutput(ns("save_final_sc")),
      shiny::br() 
      )
    ),

    shiny::mainPanel(
      shiny::tabsetPanel(
          shiny::tabPanel("Option",
          #box(
            #background = "blue",
            width = NULL,
            shiny::conditionalPanel(paste0("input['",ns("create_combine_sc"),"'] == 'Create or Edit Scorecard'"),
                box(
                  title = "Scorecard Options",
                  width = NULL,
                  collapsible = TRUE,
                  collapsed = TRUE,
                  status = "warning",
                  solidHeader = TRUE,
                  shiny::numericInput(ns("pdo_val"), label = "pdo", value = 20),
                  shiny::numericInput(ns("score_val"), label = "score", value = 600),
                  shiny::numericInput(ns("odds_val"), label = "odds to one", value = 50),
                  shiny::verbatimTextOutput(ns("offset_factor_text"))
                )
            )
          #)
          ),
           shiny::tabPanel("Upload_CSV",
                           box(width = NULL,
                               shiny::br(),
                               shiny::uiOutput(ns("upload_csv_to_td")),
                               shiny::br()
                       )
           )
    )
    )
    ),

    shiny::fluidRow(
      box(
        title = "Scorecard",
        width = NULL,
        rhandsontable::rHandsontableOutput(ns("sc_table")))
    ),

    shiny::fluidRow(
      shiny::uiOutput(ns("visualize_score")),
      shiny::br(),
      shiny::fluidRow(
        shiny::column(
          width = 6,
          shiny::plotOutput(ns("scoredist"))
        ),
        shiny::column(
          width = 6,
          box(
            title = "Scorecard Statistics",
            width = NULL,
            shiny::tableOutput(ns("final_stats"))
          )
        )
      )
    )
  )


} # end of tab7_sc_ui()

# Server function 
tab7_sc_server <- function(
  input, output, session, res, woe_data, td_schema, td_ids
) {

  scorecards <- shiny::reactiveValues()
  sg_values <- shiny::reactiveValues(done = NULL, lastchoice = NULL)

  table_segment <- shiny::reactive({
    DBI::dbReadTable(con, td_ids()[["segment_tbl"]])
  })

  segment_names <- shiny::reactive({
    table_segment() %>% select(label) %>%
    pull %>% unique %>% sort
  })
  segment_colors <- shiny::reactive({
    sg <- rev(viridisLite::viridis(length(segment_names())))
    names(sg) <- segment_names()
    sg
  })
  

  output$sg_viewer <- shiny::renderUI({

    sg_values$segment_groups_dt <- DBI::dbReadTable(con, td_ids()[["segment_group_tbl"]])

    sg_with_modselect <- sapply(
      shiny::reactiveValuesToList(res),
      function(x) "model_select" %in% names(x)
    )
    
    sg_with_modselect <- names(sg_with_modselect)[sg_with_modselect]

    sg_labels <- sg_values$segment_groups_dt %>%
                 select(segment_group, group_label) %>%
                 unique %>% 
                 arrange(segment_group) %>%
                 filter(segment_group %in% sg_with_modselect)
    
    sg        <- as.character(sg_labels$segment_group)
    names(sg) <- sg_labels$group_label

    sg_values$sg_list <-  sg[sg %in% sg_with_modselect]

    sg_values$work    <-  sg[sg %in% setdiff(sg_with_modselect, sg_values$done)]


    list_choices <- list()
    for (i in names(sg_values$work)) {
      list_choices[["Processing"]][[i]] <- sg_values$sg_list[[i]]
    }
    for (i in names(sg_values$done)) {
      list_choices[["Processed"]][[i]] <- sg_values$sg_list[[i]]
    }

    if (input$create_combine_sc == "Create or Edit Scorecard") {
      shiny::selectInput(
        session$ns("sg_viewer"),
        "Select Segment Group/s",
        choices = list_choices, multiple = FALSE,
        selected = sg_values$lastchoice
      )
      
    }
  })

  output$create_sc <- shiny::renderUI({
    shiny::actionButton(session$ns("create_sc"), "Create scorecard", width = 300)
  })
  
  output$scorecard_label <- shiny::renderUI({
    shiny::textInput(session$ns("scorecard_label"), label = "Enter Unique Name for scorecard")
  })
  
  output$upload_csv_to_td <- shiny::renderUI({
    shiny::actionButton(session$ns("save_csv_as_table"),label = "Upload CSV as a Teradata table", width = 300)
  })

  output$save_sc <- shiny::renderUI({

    allow_save <- FALSE
    if (input$create_combine_sc == "Create or Edit Scorecard") {
      if (!is.null(
        coalesce(c(scorecards[[input$sg_viewer]], scorecards[["TEMPORARY"]])))
      )
        allow_save <- TRUE
    } else {
      if (!is.null(scorecards[[sc_label()]])){
        allow_save <- TRUE
      }
    }

    if (allow_save) {
      shiny::actionButton(session$ns("save_sc"), "Save scorecard", width = 300)
    }
  })

  shiny::observeEvent(input$create_sc, {

    shiny::isolate({
      scorecards[["TEMPORARY"]] <- NULL

      coarse_class_woe_list <- DBI::dbReadTable(
        con,
        td_ids()[["coarse_class_woe_tbl"]]
      ) %>%
        filter(segment_group == input$sg_viewer)
      coarse_class_list <- DBI::dbReadTable(
        con,
        td_ids()[["coarse_class_tbl"]]
      ) %>%
        filter(segment_group == input$sg_viewer)

      if (res[[input$sg_viewer]]$model_select == "forward"){
        eff_model <- res[[input$sg_viewer]]$glm_s
      } else {
        eff_model <- res[[input$sg_viewer]]$glm
      }

      print(eff_model)

      beta <- eff_model$coefficients
      beta0 <- beta["(Intercept)"]

      factor <- input$pdo_val / log(2)
      offset <- input$score_val - (factor * log(input$odds_val))

      n <- length(beta) - 1
      coef_tab <- eff_model$coefficients[-1] %>% data.frame %>%
        mutate(variable = gsub("_woe", "", names(beta[-1]))) %>%
        rename(beta = ".") %>% filter(complete.cases(.))

      curr_sg_name <- names(
        sg_values$sg_list[sg_values$sg_list == input$sg_viewer]
      )

      res_scorecard <- coarse_class_woe_list %>% inner_join(coef_tab) %>%
        mutate(score = - ( woe * beta + beta0 / n) * factor + offset / n,
               segment_group = input$sg_viewer,
               group_label = curr_sg_name
        ) %>% inner_join(coarse_class_list) %>%
        mutate(
          coarse_class_id = new_bin %>% as.character %>% as.integer
        ) %>%
        select(
          segment_group, group_label, variable,
          bin, new_label, score, coarse_class_id
        ) %>%
        rename(
          varname = variable, old_bin_id = bin
        ) %>%
        unique %>%
        mutate(score = round(score))

      print("updating scorecards")

      scorecards[[input$sg_viewer]] <- NULL
      scorecards[["TEMPORARY"]] <- res_scorecard
      sg_values$done <- sg_values$sg_list[
        sg_values$sg_list %in%
          setdiff(sg_values$done, as.character(input$sg_viewer))
        ]
      sg_values$lastchoice <- as.character(input$sg_viewer)

    })

  })

  output$sc_table <- rhandsontable::renderRHandsontable({

    if (input$create_combine_sc == "Create or Edit Scorecard") {
      if (!is.null(scorecards[[input$sg_viewer]])) {
        DF <- scorecards[[input$sg_viewer]]
      } else if (!is.null(scorecards[["TEMPORARY"]])){
        DF <- scorecards[["TEMPORARY"]]
      } else {
        return()
      }

      DF <- DF %>%
        arrange(varname, old_bin_id) %>%
        select(group_label, varname, new_label, coarse_class_id, score) %>% 
        mutate(scorecard_id = input$scorecard_label) %>%
        unique
    } else {
      sc_label <- paste(c("COMBINED", sort(input$sg_combiner)), collapse = "_")
      DF <- scorecards[[sc_label]]

      if (!is.null(scorecards[[sc_label]])) {
        DF <- scorecards[[sc_label]] %>%
          arrange(group_label, varname, old_bin_id) %>%
          select(group_label, varname, new_label, coarse_class_id, score) %>% 
          mutate(scorecard_id = input$scorecard_label) %>%
          unique
      } else
        return()
    }


    rhandsontable(DF, rowHeaders = NULL) %>%
      hot_col(col = "group_label", readOnly = TRUE) %>%
      hot_col(col = "varname", readOnly = TRUE) %>%
      hot_col(col = "new_label", readOnly = TRUE) %>%
      hot_col(col = "coarse_class_id", readOnly = TRUE) %>%
      hot_col(col = "score") %>%
      hot_col(col = "scorecard_id", readOnly = TRUE)

  })


  shiny::observeEvent(input$save_sc, {

    shiny::isolate({

      print("saving sc")
      DF <- scorecards[[sc_label()]]

      if (input$create_combine_sc == "Create or Edit Scorecard") {
        scorecards[[input$sg_viewer]] <- DF %>% select(-score) %>%
          inner_join(hot_to_r(input$sc_table))
      } else {
        sc_label <- paste(
          c("COMBINED", sort(input$sg_combiner)), collapse = "_"
        )
        scorecards[[sc_label]] <- DF %>% select(-score) %>%
          inner_join(hot_to_r(input$sc_table))
      }

      newly_done <- as.character(input$sg_viewer)
      names(newly_done) <- sg_values$sg_list[
        sg_values$sg_list == input$sg_viewer
      ]

      sg_values$done <- sg_values$sg_list[
        sg_values$sg_list %in% c(newly_done, sg_values$done)
      ]
      sg_values$lastchoice <- NULL

      session[["sendCustomMessage"]](
        type = "testmessage",
        message = "Saved Scorecard"
      )
      scorecards[["TEMPORARY"]] <- NULL
      sg_values[["TEMPORARY"]] <- NULL
    })

  })

  output$sg_combiner <- shiny::renderUI({
    if (input$create_combine_sc == "Combine Scorecards") {
      shiny::selectInput(
        session$ns("sg_combiner"),
        "Select Segment Group/s",
        choices = sg_values$done, multiple = TRUE
      )
    }
  })

  output$combine_sc <- shiny::renderUI({
    if (input$create_combine_sc == "Combine Scorecards") {
        sg_selected <- sg_values$segment_groups_dt %>%
                       filter(segment_group %in% input$sg_combiner) %>%
                       select(segment) %>% 
                       pull

        sg_all <- sg_values$segment_groups_dt %>%
                  select(segment) %>% 
                  pull %>% 
                  unique
        
        print("sg_selected")
        print(sg_selected)
        print("length(sg_selected)")
        print(length(sg_selected))
        print("length(unique(sg_selected))")
        print(length(unique(sg_selected)))
        print("setequal(sg_selected, sg_all)")
        print(setequal(sg_selected, sg_all))

      if (length(sg_selected) == length(unique(sg_selected)) && setequal(sg_selected, sg_all)) 
        {
        shiny::actionButton(session$ns("combine_sc"), "Finalize scorecard", width = 300)
        }
    }
  })

  shiny::observeEvent(input$combine_sc, {
    isolate({
      sc_label <- paste(c("COMBINED", sort(input$sg_combiner)), collapse = "_")
      print("i am here 375")
      scorecards[[sc_label]] <- do.call("rbind",lapply(input$sg_combiner,function(x) scorecards[[x]]))
      print(scorecards[[sc_label]])
    })
  })

  output$save_final_sc <- shiny::renderUI({
    shiny::req(input$sg_combiner)
    sc_label <- paste(c("COMBINED", sort(input$sg_combiner)), collapse = "_")
    if (!is.null(scorecards[[sc_label]]))
      {
        shiny::div(style = "align:left",
        shiny::actionButton(session$ns("save_final_sc"), "Save Scorecard to Teradata", width = 300),
        shiny::br(),
        #shiny::textInput(session$ns("segment_id"), label = "Table ID", value = "seg"),
        #shiny::br(),
        shiny::actionButton(session$ns("save_final_sc_csv"), "Save Scorecard as CSV", width = 300)
        #shiny::br(),
        #shiny::actionButton(inputId = session$ns("save_csv_as_table"),label = "Upload CSV as a Teradata table", width = 300)
      )
    }
  })

  shiny::observeEvent(input$save_final_sc, {

    shiny::isolate({
      progress <- shiny::Progress$new()
      on.exit(progress$close())

      progress$set(message = "Connecting", value = 0)

      sc_label <- paste(c("COMBINED", sort(input$sg_combiner)), collapse = "_")

      print("saving this to teradata")
      upload_data <- scorecards[[sc_label]]
      colnames(upload_data)[4] <- 'fine_bin_id'
      print(upload_data)

      DBI::dbWriteTable(con, td_ids()[["scorecard_tbl"]],upload_data,append = TRUE )#sarang

      progress$set(message = "Saved to Teradata", value = .95)
      Sys.sleep(0.25)
      progress$set(message = "Saved to Teradata", value = 1)


      session[["sendCustomMessage"]](
        type = "testmessage",
        message = "Saved to Teradata"
      )
    })
  })

  shiny::observeEvent(input$save_final_sc_csv, {
    isolate({
      sc_label <- paste(c("COMBINED", sort(input$sg_combiner)), collapse = "_")
      filename <- paste(
        #"data/tbl", input$segment_id, "scorecard.csv",
        "data/tbl", input$scorecard_label, "scorecard.csv",
        sep = "_"
      )
      write.csv(scorecards[[sc_label]], file = filename, row.names = FALSE)
      shiny::showModal(
        shiny::modalDialog(
          title = "CSV saved."
        )
      )
    })
  })

  shiny::observeEvent(input$save_csv_as_table, {
    shiny::showModal(
      shiny::modalDialog(
        shiny::div(
          shiny::fileInput(
            inputId = session$ns("csv_scorecard"),
            label = "Upload CSV Scorecard"
          ),
          shiny::br(),
          shiny::actionButton(session$ns("csv_upload_button"),label = "Upload to Teradata", width = 300)
        ),
        title = "Upload CSV"
      )
    )
  })

  shiny::observeEvent(input$csv_upload_button, {
    shiny::isolate({
      progress <- shiny::Progress$new()
      on.exit(progress$close())

      progress$set(message = "Connecting", value = 0)

      file_input <- input$csv_scorecard

      if (!is.null(file_input)) {
        table_name <- substr(file_input$name, 1, nchar(file_input$name) - 4)
        data_path <- file_input$datapath

        csv_data <- read.csv(data_path)

        # check if table exists
        # table_exists <- DBI::dbExistsTable(con, table_name)
        # if (!table_exists) {
        #   # create table
        #   full_table_name <- paste0(td_schema(), ".", table_name)
        #   query <- paste0("CREATE TABLE ", full_table_name, "
        #     (
        #       segment_group INTEGER
        #       ,group_label VARCHAR(200)
        #       ,varname VARCHAR(30)
        #       ,old_bin_id INTEGER
        #       ,new_label VARCHAR(200)
        #       ,score FLOAT
        #     )
        #     PRIMARY INDEX (varname ,old_bin_id );
        #   ")
        #   DBI::dbSendQuery(con, query)
        # }

        #table_schema <- DBI::Id(schema = td_schema(), table = table_name)
        colnames(csv_data)[4] <- 'fine_bin_id'
        #colnames(csv_data)[8] <- 'scorecard_id'
        print(names(csv_data))
        #DBI::dbWriteTable(con, table_schema, csv_data, overwrite = TRUE)
        DBI::dbWriteTable(con, td_ids()[["scorecard_tbl"]],csv_data,append = TRUE )
        progress$set(message = "Saved to Teradata", value = .95)
        Sys.sleep(0.25)
        progress$set(message = "Saved to Teradata", value = 1)

        session[["sendCustomMessage"]](
          type = "testmessage",
          message = "Saved to Teradata"
        )
      }
    })
  })

  output$offset_factor_text <- shiny::renderPrint({

    factor <- input$pdo_val / log(2)
    offset <- input$score_val - (factor * log(input$odds_val))

    cat(paste0("Factor = pdo / ln(2) = ", factor, "\n",
               "Offset = score - [Factor * ln(odds)] = ", offset))
  })

  output$visualize_score <- shiny::renderUI({
    if (!is.null(coalesce(c(
      scorecards[[input$sg_viewer]],
      scorecards[["TEMPORARY"]],
      scorecards[[sc_label()]])))
    ) {
      shiny::actionButton(session$ns("visualize_score"), "Show Statistics")
    }
  })

  score_table <- reactive({
    if (input$create_combine_sc == "Create or Edit Scorecard") {
      if (!is.null(scorecards[[input$sg_viewer]])) {
        DF <- scorecards[[input$sg_viewer]]
        sc_label <- input$sg_viewer
      } else {
        DF <- scorecards[["TEMPORARY"]]
        sc_label <- "TEMPORARY"
      }
    } else {
      sc_label <- paste(c("COMBINED", sort(input$sg_combiner)), collapse = "_")
      DF <- scorecards[[sc_label]]
    }

    DF$segment_group <- as.numeric(DF$segment_group)

    score_table <- DF %>% select(-score) %>%
      inner_join(hot_to_r(input$sc_table)) %>%
      inner_join(sg_values$segment_groups_dt) %>%
      inner_join(woe_data$orig_train %>% melt(
        id = c("acct_id", "segment", "target"),
        variable.name = "varname", value.name = "old_bin_id"
      )) %>% group_by(acct_id, segment, target) %>%
        summarize(score = sum(score))

    score_table

  })

  shiny::observeEvent(input$visualize_score, {
    shiny::isolate(
      sg_values[[sc_label()]] <- score_table()
    )
  })

  shiny::observeEvent(input$save_sc, {
    shiny::isolate(
      sg_values[[sc_label()]] <- score_table()
    )
  })


  sc_label <- reactive({
    if (input$create_combine_sc == "Create or Edit Scorecard") {
      if (!is.null(scorecards[[input$sg_viewer]])) {
        sc_label <- input$sg_viewer
      } else {
        sc_label <- "TEMPORARY"
      }
    } else {
      validate(
        need(!is.null(input$sg_combiner), "Please select segments")
      )
      sc_label <- paste(c("COMBINED", sort(input$sg_combiner)), collapse = "_")
    }

    sc_label
  })


  output$scoredist <- shiny::renderPlot({

    if (input$create_combine_sc == "Create or Edit Scorecard") {
      if (!is.null(scorecards[[input$sg_viewer]])) {
        sc_label <- input$sg_viewer
      } else {
        sc_label <- "TEMPORARY"
      }
    } else {
      validate(
        need(!is.null(input$sg_combiner), "Please select segments")
      )
      print("sc_label")
      print(paste(c("COMBINED", sort(input$sg_combiner)), collapse = "_"))
      sc_label <- paste(c("COMBINED", sort(input$sg_combiner)), collapse = "_")
    }

    if (!is.null(sg_values[[sc_label]])) {
      sg_values[[sc_label]] %>% inner_join(table_segment(), by = "segment") %>%
        ggplot(aes(x = score, fill = label)) + geom_histogram() +
        scale_fill_manual(values = segment_colors()) +
        theme_bw()  +
        theme(legend.position = "bottom")
    }
  })

  output$final_stats <- shiny::renderTable({

    if (input$create_combine_sc == "Create or Edit Scorecard") {
      if (!is.null(scorecards[[input$sg_viewer]])) {
        sc_label <- input$sg_viewer
      } else {
        sc_label <- "TEMPORARY"
      }
    } else {
      validate(
        need(!is.null(input$sg_combiner), "Please select segments")
      )
      print("sc_label")
      print(paste(c("COMBINED", sort(input$sg_combiner)), collapse = "_"))
      sc_label <- paste(c("COMBINED", sort(input$sg_combiner)), collapse = "_")
    }

    if (!is.null(sg_values[[sc_label]])) {
      pred <- prediction(
        sg_values[[sc_label]]$score, sg_values[[sc_label]]$target
      )

      perf <- ROCR::performance(pred, "tpr", "fpr")
      KS <- max(
        abs(attr(perf, "y.values")[[1]] - attr(perf, "x.values")[[1]])
      )

      print("KS")
      print(KS)

      # divergence computation
      divtable <- sg_values[[sc_label]] %>% group_by(target) %>%
        summarize(score_mean = mean(score), score_var = var(score))

      divtable_good <- divtable %>% filter(target == 0) %>% data.frame
      divtable_bad <- divtable %>% filter(target == 1) %>% data.frame

      divergence <- as.numeric(
        ( ( divtable_good[2] - divtable_bad[2]) ^ 2) /
        (0.5 * ( divtable_good[3] + divtable_bad[3] ) ) )
      names(divergence) <- NULL


      data.frame(stat = c("KS", "Divergence"), values = c(KS, divergence))

    }
  })
} # end of tab7_sc_server()
