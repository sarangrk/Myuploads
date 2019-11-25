tab1_filter_ui <- function(id) {
  ns <- shiny::NS(id)
  
  shiny::fluidPage(
    shiny::fluidRow(
      box(
        title = "Create/Edit Segment Groups",
        width = NULL,
        solidHeader = TRUE,
        status = "warning",
        collapsible = TRUE,
        collapsed = TRUE,
        shiny::fluidRow(
          shiny::column(
            width = 6,
            shiny::wellPanel(
              shiny::uiOutput(ns("comp_select")),
              shiny::uiOutput(ns("group_labeler"))
              
            )
          ),
          shiny::column(
            width = 6,
            shiny::br(),
            shiny::uiOutput(ns("save_group")),
            shiny::br(),
            shiny::uiOutput(ns("delete_group")),
            shiny::br(),
            shiny::uiOutput(ns("save_group_td"))
          )
        ),
        shiny::br(),
        shiny::wellPanel(
          DT::dataTableOutput(ns("tabseggroup"))
        )
      )
    ),
    shiny::fluidRow(
      box(
        title = "Variable Selection",
        width = NULL,
        solidHeader = TRUE,
        status = "warning",
        collapsible = FALSE,
        shiny::uiOutput(ns("select_tgt")),
        shiny::uiOutput(ns("attribute_behaviour")),
        shiny::uiOutput(ns("select_num")),
        shiny::br(),
        DT::dataTableOutput(ns("iv_table_print"))
      )
    )
  )
}

tab1_filter_server <- function(input, output, session, td_ids) {
  
  segment_dt <- shiny::reactive({
    DBI::dbReadTable(con, td_ids()[["segment_tbl"]])
  })
  
  segment_groups_dt <- shiny::reactive({
    DBI::dbReadTable(con, td_ids()[["segment_group_tbl"]])
  })
  
  columns_bin <- shiny::reactive({
    DBI::dbReadTable(con, td_ids()[["bin_sample_tbl"]])
  })
  
  scorecard_type <- shiny::reactive({
    DBI::dbReadTable(con, td_ids()[["iv_table_tbl"]])
  })
  
  colum_names <- shiny::reactiveVal(data.frame())
  
  column_names <- shiny::reactive({
    x <- columns_bin() %>% names()
    x
  })
  
  res_vals <- shiny::reactiveValues(segment_groups_dt = NULL)
  rec_vals <- shiny::reactiveValues(old_group = NULL)
  
  
  segments_var <- shiny::reactive({
    sv <- segment_dt() %>% select(segment) %>% pull
    names(sv) <- segment_dt() %>% select(label) %>% pull
    sv
  })
  
  
  scorecard_names <- shiny::reactive({
    st <- scorecard_type() %>% 
          select(atr_behav) %>%
          unique() %>% 
          pull
  })
  
  output$select_tgt <- shiny::renderUI({
    shiny::selectInput(
      session$ns("filter_tgt_var"),
      "Choose Target Variable:",
      choices = column_names(), selected = "target"
    )
  })
  

  output$attribute_behaviour <- shiny::renderUI({
    shiny::selectInput(
      session$ns("filter_sc_behav"),
      "Choose Type of Scorecard Variable:",
      choices = c("Application", "Behavior","Hybrid"), selected = "Hybrid")
  })
  
  
  output$comp_select <- shiny::renderUI({
    shiny::selectInput(
      session$ns("comp_select"),
      "Select Segment Group Components",
      choices = segments_var(),
      multiple = TRUE
    )
  })
  
  shiny::observeEvent(input$save_group, {
    
    new_rows <- data.frame(
      segment = as.integer(input$comp_select),
      group_label = input$group_labeler
    )
    
    if (length(rec_vals$old_group) == 1) {
      new_segment_group <- rec_vals$old_group
      old_group <- rec_vals$old_group
      
    } else {
      
      nrows <- res_vals$segment_groups_dt %>%
        select(segment_group) %>% unique %>% nrow
      currlist <- res_vals$segment_groups_dt %>%
        select(segment_group) %>% pull %>% unique
      if (length(setdiff(currlist, seq(0, nrows - 1))) == 0) {
        new_segment_group <- nrows
      } else{
        new_segment_group <- setdiff(seq(0, nrows - 1), currlist)
      }
      
      old_group <- -99
    }
    
    new_rows <- new_rows %>% mutate(segment_group = new_segment_group) %>%
      select(segment_group, segment, group_label)
    
    res_vals$segment_groups_dt <- res_vals$segment_groups_dt %>%
      filter(segment_group != old_group) %>%
      rbind(new_rows)
  })
  
  output$tabseggroup <- DT::renderDataTable({
    if (!shiny::isTruthy(res_vals$segment_groups_dt)) {
      res_vals$segment_groups_dt <- segment_groups_dt()
    }
    
    shiny::req(res_vals$segment_groups_dt)
    
    dt <- res_vals$segment_groups_dt %>%
      inner_join(segment_dt(), by = "segment") %>%
      mutate(f_label = paste0("[", label, "]")) %>%
      group_by(segment_group, group_label) %>%
      mutate(components = paste0(f_label, collapse = ", ")) %>%
      select(segment_group, group_label, components) %>%
      arrange(segment_group) %>% unique
    
    datatable(
      dt,
      rownames = FALSE,
      selection = "none",
      options = list(lengthMenu = c(10, 25, 50), pageLength = 25)
    )
  })
  
  output$group_labeler <- shiny::renderUI({
    if (!is.null(input$comp_select))
      shiny::textInput(session$ns("group_labeler"), "Segment Group Name")
  })
  
  output$save_group <- shiny::renderUI({
    if (length(input$group_labeler) > 0) {
      
      if (input$group_labeler != "" & !is.null(input$comp_select))
        shiny::actionButton(session$ns("save_group"), "Save Group")
    }
  })
  
  output$delete_group <- shiny::renderUI({
    shiny::req(res_vals$segment_groups_dt)
    if (!is.null(input$comp_select)) {
      count_new <- length(input$comp_select)
      new_rows <- data.frame(segment = as.integer(input$comp_select))
      
      rec_vals$old_group <- res_vals$segment_groups_dt %>%
        group_by(segment_group, group_label) %>%
        mutate(ncomp = n()) %>%
        filter(ncomp == count_new) %>% inner_join(new_rows %>%
                                                    select(segment), by = "segment") %>%
        mutate(ncomp2 = n()) %>%
        filter(ncomp2 == count_new) %>% ungroup %>%
        select(segment_group) %>% unique %>% pull
      
      if (length(rec_vals$old_group) == 1 && nrow(new_rows) > 1) {
        shiny::actionButton(session$ns("delete_group"), "Delete Group")
      }
    }
  })
  
  shiny::observeEvent(
    input$delete_group,
    res_vals$segment_groups_dt <- res_vals$segment_groups_dt %>%
      filter(segment_group != rec_vals$old_group)
  )
  
  output$save_group_td <- shiny::renderUI({
    shiny::actionButton(session$ns("save_group_td"), "Save Groups to Teradata")
  })
  
  shiny::observeEvent(input$save_group_td, isolate({
    progress <- shiny::Progress$new()
    on.exit(progress$close())
    
    progress$set(message = "Connecting", value = 0)
    
    DBI::dbWriteTable(
      con,
      td_ids()[["segment_group_tbl"]],
      res_vals$segment_groups_dt,
      overwrite = TRUE
    )
    
    progress$set(message = "Saved to Teradata", value = .95)
    Sys.sleep(0.25)
    progress$set(message = "Saved to Teradata", value = 1)
    
    
    session[["sendCustomMessage"]](type = "testmessage",
                                   message = "Saved to Teradata")
  })
  )
  
  # old code starts here
  
  varnames <- shiny::reactive({
    DBI::dbReadTable(con, td_ids()[["iv_table_tbl"]])
  })
  
  output$select_num <- shiny::renderUI({
    p <- nrow(varnames())
    shiny::selectInput(
      session$ns("filter_num"),
      "Automatically choose how many features to retain:",
      choices = 1:p, selected = min(p, 200)
    )
  })
  
  iv_table <- shiny::reactive({
    if (input$filter_sc_behav == 'Hybrid') {
        shiny::req(input$filter_num)
        varnames() %>% 
        dplyr::arrange(ranknum)
    } else {
      shiny::req(input$filter_num)
        varnames() %>% 
        filter(atr_behav == input$filter_sc_behav ) %>%
        dplyr::arrange(ranknum)
    }
  })

  
  output$iv_table_print <- DT::renderDataTable({
    shiny::req(input$filter_num)
    
    datatable(
      iv_table(),
      rownames = FALSE,
      selection =  list(
        mode = "multiple",
        selected = 1:input$filter_num,
        target = "row"
      ),
      options = list(
        lengthMenu = c(10, 25, 50),
        pageLength = 25)
    ) %>% DT::formatRound(c(2), 4)
  })
  
  var_select <- reactive({
    vars <- iv_table()$varname[input$iv_table_print_rows_selected]
    vars
  })
  
  output$rows_selected <- shiny::renderPrint({
    print(var_select())
  })
  
  
  return(var_select)
}
