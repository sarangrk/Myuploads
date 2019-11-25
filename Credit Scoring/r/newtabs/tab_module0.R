

tab0_traintest_ui <- function(id) {

  ns <- shiny::NS(id)

  shiny::fluidPage(
    shiny::sidebarLayout(
      shiny::sidebarPanel(
        shiny::selectInput(
          ns("select_schema"),
          "Select Schema",
          choices = c("Japan" = "JAPAN_DAP", "German" = "GERMAN"),
          selected = 'Japan'
        ),
        shiny::uiOutput(ns("load_btn_ui")),
        shiny::tags$br(),
        box(
          title = "Partition data",
          width = NULL,
          solidHeader = TRUE,
          status = "warning",
          collapsible = TRUE,
          collapsed = TRUE,
          shiny::numericInput(
            ns("select_seed"), label = "Select Seed Value", value = 1
          ),
          shiny::numericInput(
            ns("select_ratio"),
            label = "Select % of Data in Training Data",
            value = 80, min = 1, max = 99),
          shiny::uiOutput(ns("start_partition"))
        ),
        shiny::uiOutput(ns("save_tables")),
        shiny::hr(),
        shiny::uiOutput(ns("target_ratio"))
      ),

      shiny::mainPanel(
        h4("Training Data:"),
        br(),
        div(
          style = "overflow-x: scroll",
          DT::dataTableOutput(ns("traindata_dt"))
        ),
        hr(),
        h4("Test Data:"),
        br(),
        div(style = "overflow-x: scroll",
        DT::dataTableOutput(ns("testdata_dt")))
      )
    )
  )
}

tab0_traintest_server <- function(input, output, session, td_schema, td_ids) {
  acct_segment_dt <- shiny::reactive({
    DBI::dbReadTable(con, td_ids()[["acct_segment_tbl"]])
  })
  
  train_or_test_table <- "tbl_acct_trainortest"

  traindata <- shiny::reactiveVal(data.frame())
  testdata <- shiny::reactiveVal(data.frame())

  output$start_partition <- shiny::renderUI({
    shiny::actionButton(
      session$ns("start_partition"), "Start Train-Test Partition"
    )
  })

  output$load_btn_ui <- shiny::renderUI({
    table_exists <- DBI::dbExistsTable(con, train_or_test_table)
    #table_exists <- DBI::dbExistsTable(con, td_ids()[["sampling_weight_view"]])
    if (table_exists) {
      shiny::actionButton(
        session$ns("load_btn"),
        "Load from Teradata"
      )
    } else {
      NULL
    }
  })

  shiny::observeEvent(input$select_schema, {
    td_schema(input$select_schema)
    td_ids(lapply(td_tables, function(x) DBI::Id(
      schema  = td_schema(),
      table   = x
    )))
  })

  shiny::observeEvent(input$load_btn, {
    asd <- acct_segment_dt()
    progress <- shiny::Progress$new()
    on.exit(progress$close())
    progress$set(message = "Connecting", value = 0)

    train_or_test_table_id <- DBI::Id(
      schema = td_schema(),
      table = train_or_test_table
    )

    train_or_test_data <- DBI::dbReadTable(con, train_or_test_table_id)
    bin_sample <- DBI::dbReadTable(con, td_ids()[["bin_sample_tbl"]])
    traindata(
      bin_sample %>%
        filter(acct_id %in% (
          train_or_test_data %>%
            filter(train_type == 0)
        )$acct_id
      ) %>% inner_join(asd, by = "acct_id")
    )

    testdata(
      bin_sample %>%
        filter(acct_id %in% (
          train_or_test_data %>%
            filter(train_type == 1)
        )$acct_id
      ) %>% inner_join(asd, by = "acct_id")
    )

    progress$set(message = "Done", value = 1)
  })

  shiny::observeEvent(input$start_partition, {
    asd <- acct_segment_dt()

    progress <- shiny::Progress$new()
    on.exit(progress$close())
    progress$set(message = "Connecting", value = 0)

    bin_sample <- DBI::dbReadTable(con, td_ids()[["bin_sample_tbl"]])

    set.seed(input$select_seed)
    progress$set(message = "Creating Partititions", value = 0.25)
    strat <- bin_sample %>% splitstackshape::stratified(
      "target", input$select_ratio / 100, bothSets = TRUE
    )

    progress$set(message = "Applying Partititions", value = 0.5)

    traindata(
      strat$SAMP1 %>% inner_join(asd, by = "acct_id")
    )
    testdata(
      strat$SAMP2 %>%
        inner_join(asd, by = "acct_id")
    )

    progress$set(message = "Saving to Teradata table", value = 0.75)

    # detect if train_or_test table exists
    table_exists <- DBI::dbExistsTable(con, train_or_test_table)
    if (!table_exists) {
      full_table_name <- paste0(td_schema(), ".", train_or_test_table)
      print(full_table_name)
      query <- paste0("CREATE TABLE ", full_table_name, "
        (
          acct_id INTEGER,
          train_type INTEGER
        )
        PRIMARY INDEX (acct_id);
      ")
      DBI::dbSendQuery(con, query)
    }

    # Save to table
    train_or_test_table_id <- DBI::Id(
      schema = td_schema(),
      table = train_or_test_table
    )
    combined_tbl <- (
      traindata() %>% mutate(train_type = as.integer(0)) %>%
      select(acct_id, train_type)
    ) %>% union(
      testdata() %>% mutate(train_type = as.integer(1)) %>%
      select(acct_id, train_type)
    )
    DBI::dbWriteTable(
      con, train_or_test_table_id, combined_tbl, overwrite = TRUE
    )
    progress$set(message = "Done", value = 1)
  })

  output$traindata_dt <- DT::renderDataTable({
    DT::datatable(traindata(), rownames = FALSE, selection = "none")
  })

  output$testdata_dt <- DT::renderDataTable({
    DT::datatable(testdata(), rownames = FALSE, selection = "none")
  })

  output$save_tables <- shiny::renderUI({
    shiny::req(testdata())
    shiny::actionButton(session$ns("save_tables"), "Export Data to CSV")
  })

  output$target_ratio <- shiny::renderUI({
    if (nrow(traindata()) > 0 && nrow(testdata()) > 0) {
      ntrain_good <- traindata() %>%
        filter(target == 0) %>% nrow
      ntrain_bad <- traindata() %>%
        filter(target == 1) %>% nrow
      ntest_good <- testdata() %>%
        filter(target == 0) %>% nrow
      ntest_bad <- testdata() %>%
        filter(target == 1) %>% nrow
      shiny::wellPanel(
        shiny::h3("Target Ratio"),
        shiny::div(
          shiny::tags$b("Train data: "),
          shiny::span(
            paste0(
              ntrain_good, " good / ",
              ntrain_bad, " bad"
            )
          )
        ),
        shiny::div(
          shiny::tags$b("Test data: "),
          shiny::span(
            paste0(
              ntest_good, " good / ",
              ntest_bad, " bad"
            )
          )
        )
      )
    }
    else {
      return(NULL)
    }
  })

  shiny::observeEvent(input$save_tables, {

    write.csv(traindata(), file = "data/training_data.csv", row.names = FALSE)
    write.csv(testdata(), file = "data/test_data.csv", row.names = FALSE)

    session[["sendCustomMessage"]](
      type = "testmessage",
      message = "Export Completed"
    )
  })

  session[["onSessionEnded"]](function() {
    DBI::dbDisconnect(con)
    print("disconnecting now")
  })
}