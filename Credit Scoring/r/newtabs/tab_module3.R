# UI function

tab3_ccres_ui <- function(id) {

  ns <- shiny::NS(id)

  shiny::fluidPage(
    shiny::fluidRow(
      box(
        title = "Save output",
        solidHeader = TRUE,
        width = NULL,
        status = "primary",
        shiny::column(6, shiny::uiOutput(ns("save_td"))),
        shiny::column(6, shiny::uiOutput(ns("save_woe_charts")))
      )
    ),
    shiny::fluidRow(
      shiny::br(),
      DT::dataTableOutput(ns("coarseclass_tab"))
    )
  )
} # end of tab2_cc_ui()

# Server function 
tab3_ccres_server <- function(input, output, session, cc_results, td_ids) {
  output$coarseclass_tab <- DT::renderDataTable({
    datatable(
      cc_results$woedata %>% arrange(segment_group, variable, new_bin),
      rownames = FALSE,
      selection = "none",
      options = list(
        lengthMenu = c(10, 25, 50),
        pageLength = 25
      )
    ) %>% DT::formatRound(c(5, 7, 8, 9), 2)
  })

  output$save_td <- shiny::renderUI({
    shiny::req(cc_results$woedata)
    shiny::actionButton(session$ns("save_td"), "Save to Teradata")
  })

  shiny::observeEvent(input$save_td, {
    progress <- shiny::Progress$new()
    on.exit(progress$close())

    print(cc_results$data)

    progress$set(message = "Connecting", value = 0)
    DBI::dbWriteTable(
      con, td_ids()[["coarse_class_tbl"]], cc_results$data, overwrite = TRUE
    )
    progress$set(message = "Saving to Teradata", value = .50)

    DBI::dbWriteTable(
      con,
      td_ids()[["coarse_class_woe_tbl"]],
      cc_results$woedata,
      overwrite = TRUE
    )

    progress$set(message = "Saved to Teradata", value = .95)
    Sys.sleep(0.25)
    progress$set(message = "Saved to Teradata", value = 1)

    session[["sendCustomMessage"]](
      type = "testmessage",
      message = "Saved to Teradata"
    )
  })

  output$save_woe_charts <- shiny::renderUI({
    shiny::req(cc_results$woedata)
    shiny::actionButton(session$ns("save_woe_charts"), "Save WOE Charts")
  })

  shiny::observeEvent(input$save_woe_charts, {
    progress <- shiny::Progress$new()
    on.exit(progress$close())

    progress$set(message = "Connecting", value = 0)

    segment_groups_dt <- DBI::dbReadTable(con, td_ids()[["segment_group_tbl"]])

    incl_vars <- cc_results$woedata %>%
      select(segment_group, variable) %>% unique
    incl_vars$segment_group <- as.character(incl_vars$segment_group)
    incl_vars$variable <- as.character(incl_vars$variable)

    print(incl_vars)

    var_ctr <- 0

    vartable <- DBI::dbReadTable(con, td_ids()[["hierarchy_tbl"]])

    for (i in 1:nrow(incl_vars)) {
      progress$set(message = "Saving charts", value = var_ctr / nrow(incl_vars))

      var_dtype <- vartable %>% filter(varname == incl_vars[i, 2]) %>%
        select(datatype) %>% pull
      if (!(var_dtype %in% c("CATEGORICAL"))) {
        cc_results$woedata %>%
          filter(
            variable == incl_vars[i, 2] & segment_group == incl_vars[i, 1]
          ) %>%
          ggplot(aes(
            x = new_bin,
            y = woe,
            label = round(woe, 2),
            group = 1)
          ) + geom_point() +
          geom_line(color = "blue") +
          geom_hline(yintercept = 0) +
          labs(
            title = "Weight of Evidence Chart", x = "Bin Number", y = "WoE"
          ) + theme_bw() + geom_label()
      } else {
        num_groups <- cc_results$woedata %>%
          filter(
            variable == incl_vars[i, 2] & segment_group == incl_vars[i, 1]
          ) %>% nrow

        cc_results$woedata %>% filter(
          variable == incl_vars[i, 2] & segment_group == incl_vars[i, 1]
        ) %>%
          ggplot(aes(
            x = new_bin,
            y = woe,
            label = round(woe, 2)
          )) + geom_col(fill = rev(viridis(num_groups))) +
          geom_hline(yintercept = 0) +
          labs(
            title = "Weight of Evidence Chart", x = "Bin Number", y = "WoE") +
          theme_bw() + geom_label()
      }
      foldername <- segment_groups_dt %>%
        filter(segment_group == incl_vars[i, 1]) %>%
        select(segment_group, group_label) %>%
        unique %>% paste0(., collapse = "_")
      foldername <- gsub('[\\/|*?:<>"]}| $', "", foldername)

      dir.create(paste0(charts_woe_savedir, "/", foldername))
      ggsave(
        paste0(incl_vars[i, 2], "_woe.png"),
        path = paste0(charts_woe_savedir, "/", foldername))
      var_ctr <- var_ctr + 1
    }

    progress$set(message = "Saved charts", value = 1)
    session[["sendCustomMessage"]](
      type = "testmessage",
      message = "Finished saving charts"
    )
  })

} # end of tab3_ccres_server()
