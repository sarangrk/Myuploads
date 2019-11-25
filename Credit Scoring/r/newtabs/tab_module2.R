# UI function

tab2_cc_ui <- function(id) {

  ns <- shiny::NS(id)

  shiny::fluidPage(
    shiny::sidebarLayout(
      shiny::sidebarPanel(
        box(width = NULL, status = "primary",
          shiny::uiOutput(ns("sg_select")),
          shiny::uiOutput(ns("selectcol")),
          shiny::uiOutput(ns("select_bintype")),
          shiny::conditionalPanel(
            paste0("input['", ns("select_bintype"), "']", "=='Breaks'"),
            shiny::uiOutput(ns("selectbreaks"))
          ),
          shiny::conditionalPanel(
            paste0("input['", ns("select_bintype"), "']", "=='Manual'"),
            rhandsontable::rHandsontableOutput(ns("selectmanualtable"))
          )
        ),
        shiny::fluidRow(
          column(6, shiny::uiOutput(ns("save_button"))),
          column(6, shiny::uiOutput(ns("remove_button")))
        ),
        br(),
        shiny::conditionalPanel(
          paste0("input['", ns("select_bintype"), "']", "=='Breaks'"),
          shiny::verbatimTextOutput(ns("console"))
        ),
        shiny::fluidRow(
          shinydashboard::valueBoxOutput(ns("train_iv_vbox")),
          shinydashboard::valueBoxOutput(ns("test_iv_vbox"))
        )
      ),
      shiny::mainPanel(
        box(
          background = "blue",
          width = NULL,
          shiny::plotOutput(ns("woe_plot")),
          plotly::plotlyOutput(ns("dist_plot"))
        )
      )
    )
  )
} # end of tab2_cc_ui()

# Server function 
tab2_cc_server <- function(input, output, session, td_ids) {

  replace_NA_0 <- function(x){
    dplyr::if_else(is.na(x), 0, x)
  }

  binned_sample <- shiny::reactiveFileReader(500, session,
                                      "data/training_data.csv", read.csv)
  binned_test <- shiny::reactiveFileReader(500, session,
                                      "data/test_data.csv", read.csv)

  coarse_class_list <- shiny::reactive({DBI::dbReadTable(con, td_ids()[["coarse_class_tbl"]])})
  coarse_class_woe_list <- shiny::reactive({DBI::dbReadTable(con, td_ids()[["coarse_class_woe_tbl"]])})
  
  vartable <- shiny::reactive({DBI::dbReadTable(con, td_ids()[["hierarchy_tbl"]])})

  v <- shiny::reactiveValues(
    data = NULL,
    woedata = NULL
  )
  
  datacols <- shiny::reactiveVal(list())

  segment_groups_dt <- shiny::reactive({DBI::dbReadTable(con, td_ids()[["segment_group_tbl"]])})
  
  rec_vals <- shiny::reactiveValues(
    segment_groups_dt = NULL
  )

  output$sg_select <- shiny::renderUI({
    if (!shiny::isTruthy(v$data)) {
      v$data <- coarse_class_list()
      v$woedata <- coarse_class_woe_list()
    }

    if (!shiny::isTruthy(rec_vals$segment_groups_dt)) {
      rec_vals$segment_groups_dt <- segment_groups_dt()
    }

    shiny::req(rec_vals$segment_groups_dt)
    
    sg_labels <- rec_vals$segment_groups_dt %>%
                 select(segment_group, group_label) %>%
                 unique %>% 
                 arrange(segment_group)
    sg <- as.character(sg_labels$segment_group)
    names(sg) <- sg_labels$group_label
    
    shiny::selectInput(session$ns("sg_select"), "Choose Segment Group",choices = sg)
  })

  shiny::observeEvent(input$sg_select, {
    shiny::req(vars_selected())
    shiny::req(v$data)
    excl <- v$data %>% 
            filter(segment_group == input$sg_select) %>%
            select(variable) %>% 
            unique %>% 
            pull %>% 
            as.character
    
    v$excl_vars <- excl[excl %in% vars_selected()]
    v$relevant_segments <- rec_vals$segment_groups_dt %>%
                           filter(segment_group == input$sg_select) %>%
                           select(segment) %>% 
                           pull
  })

  shiny::observeEvent(input$save_button, {
    newrecord <- eff_group_table() %>%
      mutate(
        segment_group = input$sg_select,
        variable = input$datacol,
        bin_type = input$select_bintype
      ) %>% select(
        segment_group,
        variable,
        bin,
        new_bin,
        new_label,
        bin_type
      )
    
    v$data <- v$data %>% 
              filter(variable %in% vars_selected()) %>%
              filter(!(variable == input$datacol & segment_group == input$sg_select)) %>% 
              rbind(newrecord)


    v$excl_vars <- v$data %>% 
                   filter(segment_group == input$sg_select) %>%
                   select(variable) %>% 
                   pull %>% 
                   unique %>% 
                   as.character
    

    newrecord_woe <- cbind(segment_group = input$sg_select,variable = input$datacol,target_table() %>% select(-woe_rank))
    

    v$woedata <- v$woedata %>% 
                 filter(variable %in% vars_selected()) %>%
                 filter(!(variable == input$datacol & segment_group == input$sg_select)) %>% 
                 rbind(newrecord_woe)
    isolate({
      shiny::updateSelectInput(session,"datacol",selected = input$datacol)
      shiny::updateSelectInput(session,"sg_select",selected = input$sg_select)
    })
  })

  shiny::observeEvent(input$remove_button, {
    v$data <- v$data %>% filter(variable %in% vars_selected()) %>%
      filter(!(variable == input$datacol & segment_group == input$sg_select))
    v$excl_vars <- v$data %>% filter(segment_group == input$sg_select) %>%
      select(variable) %>% pull %>% unique %>% as.character
    v$woedata <- v$woedata %>% filter(variable %in% vars_selected()) %>%
      filter(!(
        variable == input$datacol & segment_group == input$sg_select)
      )
  })

  output$selectcol <- shiny::renderUI({
    shiny::req(vars_selected())

    all_vars <- vars_selected() %>% na.omit()
    #print("all_vars")
    #print(all_vars)
    tbd_vars <- all_vars[!(all_vars %in% v$excl_vars)]
    #print("tbd_vars")
    #print(tbd_vars)
    var_choices <- list()
    if (length(tbd_vars) > 0) {
      for (i in tbd_vars){
        var_choices[["Processing"]][[i]] <- i
      }
    }

    if (length(v$excl_vars) > 0) {
      for (i in v$excl_vars){
        var_choices[["Processed"]][[i]] <- i
      }
    }

    datacols(var_choices)

    shiny::selectInput(session$ns("datacol"), "Column:", choices = var_choices,multiple = FALSE, selectize = TRUE)

  })

  fine_classes <- reactive({
    shiny::req(input$datacol)

    fine_class_tbl <- DBI::dbReadTable(con, td_ids()[["fine_class_labels_tbl"]]) %>% 
                      filter(varname == input$datacol) %>%
                      select(bin_id, label) %>% 
                      arrange(bin_id)
    values <- fine_class_tbl %>% 
              select(bin_id) %>% 
              pull
    names(values) <- fine_class_tbl %>% 
                     select(label) %>% 
                     pull
    
    values
  })

  init_breaks <- reactive({
    if (length(v$excl_vars) > 0 && input$datacol %in% v$excl_vars){

      init_breaks_lbl <- v$data  %>%
        filter(
          variable == input$datacol & segment_group == input$sg_select
        ) %>%
        group_by(new_bin) %>%
        summarize(MAX_BREAKS = max(bin)) %>%
        pull

      init_breaks_lbl <- init_breaks_lbl[
        init_breaks_lbl != tail(fine_classes(), 1)
      ]
      names(fine_classes())[fine_classes() %in% init_breaks_lbl]
    } else {
      NULL
    }
  })

  output$selectbreaks <- shiny::renderUI({

    shiny::req(input$datacol)

    shiny::selectInput(session$ns("cutbreaks"), "Breaks:",
                choices = names(fine_classes()),
                multiple = TRUE, selectize = TRUE, selected = init_breaks())
  })

  # sort values in cutbreaks
  shiny::observeEvent(input$cutbreaks, {
    selected <- names(fine_classes()) %>% dplyr::intersect(input$cutbreaks)
    shiny::updateSelectInput(session, "cutbreaks", selected = selected)
  })

  actualbreaks <- reactive({

    if (is.null(input$cutbreaks)){
      cb <- names(fine_classes())
    } else {
      cb <- input$cutbreaks
    }
    cb[cb != tail(names(fine_classes()), 1)]
  })

  eff_group_table <- reactive({
    fc <- fine_classes()
    if (!is.null(input$select_bintype) && input$select_bintype == "Breaks"){
      ab <- actualbreaks()
      breaks <- c(-Inf, fc[ab], Inf)
      grouping_factor <- cut(
        fine_classes(),
        breaks = breaks,
        labels = FALSE
      )
      
      data_label <- data.frame(
        bin = fc,
        new_bin = grouping_factor,
        OLD_LABEL = names(fc)
      )
      data_minmax <- data_label %>% group_by(new_bin) %>%
        arrange(bin) %>%
        slice(c(1, n())) %>%
        mutate(minmax = c("min_label", "max_label")) %>%
        dcast(new_bin~minmax, value.var = "OLD_LABEL")
      
      data_label %>% inner_join(data_minmax, by = "new_bin") %>%
        mutate(
          new_label = apply(
            .[, c("min_label", "max_label")],
            1,
            function(x) paste(unique(x), collapse = " to ")
          )
        ) %>%
        select(-one_of(c("min_label", "max_label")))
      
    }
    else {
      if (!is.null(input$selectmanualtable)) {
        DF <- hot_to_r(input$selectmanualtable)
        # print("Index:")
        # print(DF$index)
        # print("Original Data frame: ")
        # print(DF)
        # print("Orginal group: ")
        # print(DF$group)
        DF$new_label <- DF$group
        DF$bin <- fc
        unique_group <- unique(DF$group)
        n_bins <- lapply(DF$group, function(x) match(x, unique_group))
        #unique_group <- unique(DF$index)
        #n_bins <- lapply(DF$index, function(x) match(x, unique_group))

        DF %>% 
        rename(OLD_LABEL = category) %>%
        mutate(new_bin = unlist(n_bins, use.names = FALSE)) %>%
        select(bin, new_bin, OLD_LABEL, new_label)
      }
    }
  })

  target_table <- reactive({
    shiny::req(actualbreaks())
    shiny::req(eff_group_table())
    shiny::req(input$datacol)
    filtered <- filter(binned_sample(), segment %in% v$relevant_segments)
    selected <- select(filtered, target, UQ(input$datacol))
    renamed <- rename(selected, bin = UQ(input$datacol))
    selected_egt <- select(eff_group_table(), bin, new_bin)
    #selected_egt <- select(eff_group_table(), bin, new_bin,new_label)
    joined <- right_join(renamed, selected_egt, by = "bin")
    joined %>%
      mutate(target0 = ifelse(is.na(target), 0, target)) %>%
      group_by(new_bin) %>%
      summarize(
        bincount = sum(!is.na(target)), bintargetcount = sum(target0)
      ) %>%
      mutate(
        bincount = bincount + 2,
        bintargetcount = bintargetcount + 1
      ) %>% ## adjustments for empty cases
      mutate(target_pct = bintargetcount / bincount) %>%
      mutate(bingoodcount = bincount - bintargetcount)  %>%
      mutate(
        bingoodpct = bingoodcount / sum(bingoodcount),
        binbadpct = bintargetcount / sum(bintargetcount),
        woe = log(bingoodpct / binbadpct),
        woe_rank = rank(woe, ties.method = "first")
      ) %>%
      #mutate(woe_rank = rank(woe, ties.method = "first")) %>% #sarang
      arrange(woe_rank) #sarang
  })

  target_table_test <- reactive({

    shiny::req(actualbreaks())
    shiny::req(binned_test())
    shiny::req(eff_group_table())

    filtered <- filter(binned_test(), segment %in% v$relevant_segments)
    selected <- select(filtered, target, UQ(input$datacol))
    renamed <- rename(selected, bin = UQ(input$datacol))
    selected_egt <- select(eff_group_table(), bin, new_bin)
    joined <- right_join(renamed, selected_egt, by = "bin")
    joined %>%
      group_by(new_bin) %>%
      summarize(
        bincount = sum(!is.na(target)),
        bintargetcount = sum(target)
      ) %>%
      mutate_all(funs(ifelse(is.na(.), 0, .))) %>%
      mutate(
        bincount = bincount + 2,
        bintargetcount = bintargetcount + 1
      ) %>% ## adjustments for empty cases
      mutate(target_pct = bintargetcount / bincount) %>%
      mutate(bingoodcount = bincount - bintargetcount) %>%
      mutate(
        bingoodpct = bingoodcount / sum(bingoodcount),
        binbadpct = bintargetcount / sum(bintargetcount),
        woe = log(bingoodpct / binbadpct),
        woe_rank = rank(woe, ties.method = "first")
      ) %>%   
      #mutate(woe_rank = rank(woe, ties.method = "first")) %>% #sarang
      arrange(woe_rank)

  })


  output$train_iv_vbox <- shinydashboard::renderValueBox({
    shiny::req(binned_sample())
    shiny::req(target_table())
    t <- target_table() %>% mutate(iv_part = (bingoodpct - binbadpct) * woe) %>%
      summarize(sum(iv_part)) %>% pull %>% round(4)
    shinydashboard::valueBox(
      value = tags$p(t, style = "font-size: 50%;"),
      "Train IV",
      color = "blue"
    )
  })

  output$test_iv_vbox <- shinydashboard::renderValueBox({
    shiny::req(binned_test())
    if (!is.null(target_table_test())) {
      t <- target_table_test() %>%
        mutate(iv_part = (bingoodpct - binbadpct) * woe) %>%
        summarize(sum(iv_part)) %>% pull %>% round(4)
      shinydashboard::valueBox(
        value = tags$p(t, style = "font-size: 50%;"),
        "Test IV",
        color = "orange"
      )
    } else {
      return(NULL)
    }
  })


  split_list <- reactive({
    ef <- eff_group_table()
    fc <- fine_classes()
    shiny::req(input$datacol)
    shiny::req(ef)
    shiny::req(fc)
    split(fc, ef %>% dplyr::select(new_bin))
  })

  output$console <- shiny::renderPrint({

    if (input$select_bintype == "Breaks") {
      sp <- split_list()
      print(sp)
      minmax_list <- lapply(
        sp,
        function(x) paste(
          unique(names(c(x[1], tail(x, 1)))),
          collapse = " to ")) #min and max
    }
  })

  output$dist_plot <- plotly::renderPlotly({
    if (is.null(target_table())) {
      return(NULL)
    }
    
    if (input$select_bintype == "Breaks") {
    shiny::req(target_table())
    num_groups <- eff_group_table() %>% 
                  select(new_bin) %>%
                  pull %>% 
                  unique %>% 
                  length

    new_bins <- target_table() %>% 
                select(new_bin) %>%
                pull %>% 
                unique
    
    manual_colors <- rev(viridisLite::viridis(num_groups))
    names(manual_colors) <- as.factor(new_bins)
    
    
    dist_table <- target_table() %>% mutate(
      bincount = bincount - 2,
      bintargetcount = bintargetcount - 1,
      new_bin = paste0(
        "GROUP_",
        formatC(
          new_bin,
          width = 2,
          format = "d",
          flag = "0"
        )
      )
    ) %>%
    mutate(bingoodcount = bincount - bintargetcount)

    dist_table %>% plotly::plot_ly(
      x = ~new_bin,
      y = ~bintargetcount,
      type = "bar",
      name = "Bad" 
    ) %>% plotly::add_trace(
      y = ~bingoodcount,
      name = "Good" 
    ) %>% plotly::layout(
      yaxis = list(title = "Count"),
      xaxis = list(title = "Bins"),
      title = "Distribution Chart",
      barmode = "stack",
      legend = list(orientation = 'h')
    )
    } else{
      
      shiny::req(target_table())
      num_groups <- eff_group_table() %>% 
        select(new_bin) %>%
        pull %>% 
        unique %>% 
        length
      
      new_bins <- target_table() %>% 
        select(new_bin) %>%
        pull %>% 
        unique
      
      manual_colors <- rev(viridisLite::viridis(num_groups))
      names(manual_colors) <- as.factor(new_bins)
      
      
      dist_table <- target_table() %>% mutate(
        bincount = bincount - 2,
        bintargetcount = bintargetcount - 1,
        new_bin = paste0(
          "",
          formatC(
            #new_bin,
            woe_rank, #sarang
            width = 2,
            format = "d",
            flag = "0"
          ),
          ": GROUP_",
          formatC(
            new_bin,
            #woe_rank,
            width = 2,
            format = "d",
            flag = "0"
          )
        )
      ) %>%
        mutate(bingoodcount = bincount - bintargetcount)
      
      dist_table %>% plotly::plot_ly(
        x = ~new_bin,
        y = ~bintargetcount,
        type = "bar",
        name = "Bad" 
      ) %>% plotly::add_trace(
        y = ~bingoodcount,
        name = "Good" 
      ) %>% plotly::layout(
        yaxis = list(title = "Count"),
        xaxis = list(title = "Bins"),
        title = "Distribution Chart",
        barmode = "stack",
        legend = list(orientation = 'h')
      )
      
      
      
    }
  })

  output$woe_plot <- shiny::renderPlot({
    shiny::req(binned_sample())
    shiny::req(target_table())
    if (input$select_bintype == "Breaks") {
      target_table() %>% 
        mutate(
          new_bin = paste0(
            "GROUP_",
            formatC(
              new_bin,
              width = 2,
              format = "d",
              flag = "0"
            )
          )
        ) %>%
        ggplot(
        aes(
          x = new_bin,
          y = woe,
          label = round(woe, 2),
          group = 1)
        ) + geom_point() +
        geom_line(color = "blue") +
        geom_hline(yintercept = 0) +
        labs(title = "Weight of Evidence Chart", x = "Bin Number", y = "WoE") +
        theme_bw() + geom_label(fill = "white")
    }
    else{
      num_groups <- eff_group_table() %>% 
                    select(new_bin) %>%
                    pull %>% 
                    unique %>% 
                    length

      new_bins <- target_table() %>% 
                  select(new_bin) %>%
                  pull %>% 
                  unique
      manual_colors <- rev(viridisLite::viridis(num_groups))
      names(manual_colors) <- as.factor(new_bins)

      target_table() %>%
        mutate(
          new_bin = paste0(
            "",
            formatC(
              #new_bin,
              woe_rank,
              width = 2,
              format = "d",
              flag = "0"
            ),
            ": GROUP_",
            formatC(
              new_bin,
              #woe_rank,
              width = 2,
              format = "d",
              flag = "0"
            )
          )
        ) %>%
        ggplot(
        aes(
          x = new_bin,
          y = woe,
          label = round(woe, 2),
          group = 1)
        ) + geom_point() +
        geom_line(color = "blue") +
        geom_hline(yintercept = 0) +
        labs(title = "Weight of Evidence Chart", x = "Bin Number", y = "WoE") +
        theme_bw() + geom_label(fill = "white")
    }
  })
  
  output$save_button <- shiny::renderUI({
    shiny::req(binned_sample())
    shiny::req(target_table())
    shiny::actionButton(session$ns("save_button"), "Save Bins")
  })

  output$remove_button <- shiny::renderUI({
    shiny::req(binned_sample())
    shiny::req(target_table())
    if (input$datacol %in% v$excl_vars) {
      shiny::actionButton(session$ns("remove_button"), "Remove Bins")
    }
  })

  output$selectmanualtable <- rhandsontable::renderRHandsontable({
    shiny::req(input$datacol)
    shiny::req(fine_classes)
    
    if (input$datacol %in% v$excl_vars) {

        old_classes <- data.frame(bin = fine_classes(),old_label = names(fine_classes()))
        #print(old_classes)
        new_group <- old_classes %>% 
                     inner_join(v$data %>% filter(variable == input$datacol & segment_group == input$sg_select),by = "bin") %>%
                     arrange(bin) %>% 
                     select(new_label) %>% 
                     pull
      
        
    } else {
      new_group <- names(fine_classes())
    }
    
    unique_ng <- unique(new_group)
    index <- unlist(lapply(new_group, function(x) match(x, unique_ng)))

    DF <- data.frame(
      index = index,
      category = names(fine_classes()),
      group = new_group
    )
    if (!is.null(DF)){
      rhandsontable(DF, rowHeaders = NULL) %>%
        hot_cols(columnSorting = TRUE) %>%
        hot_col(col = "index", readOnly = TRUE, width = 30) %>%
        hot_col(col = "category", readOnly = TRUE, width = 180) %>%
        hot_col(col = "group", width = 140,type = "autocomplete", source = c("new bin"),strict = FALSE) 
    }
  })

  output$select_bintype <- shiny::renderUI({
    vt <- vartable()
    shiny::req(vt)
    shiny::req(input$datacol)

    choice_list <- c("Manual")
    select_option <- "Manual"
    var_dtype <- vt %>% filter(
        varname == input$datacol
      ) %>% select(datatype) %>% pull
      init_bintype <- v$data %>% filter(
        variable == input$datacol & segment_group == input$sg_select
      ) %>%
      select(bin_type) %>% pull %>% unique

    if (length(init_bintype) == 0){
      init_bintype <- "NULL"
    }

    if (!(var_dtype == "CATEGORICAL")){
    # if(var_dtype %in% c("INTEGER","DECIMAL")){
      if (!(init_bintype %in% ("Manual"))){
        select_option <- "Breaks"
        choice_list <- c("Breaks", "Manual")
      }
    }

    shiny::selectInput(session$ns("select_bintype"), label = "Select Bin Type",
                choices = choice_list,
                selected = select_option)
  })
  return(v)

} # end of tab2_cc_server()
