# UI function

tab4_woe_ui <- function(id) {
  ns <- shiny::NS(id)
  
  shiny::fluidPage(
    shiny::fluidRow(
      box(
        title = "Weight of Evidence Table Conversion",
        width = NULL,
        solidHeader = TRUE,
        status = "warning",
        collapsible = FALSE,
        shiny::uiOutput(ns("convert_woe")),
        shiny::br(),
        shiny::uiOutput(ns("woeviewer")),
        shiny::div(
          style = "overflow-x: scroll",
          DT::dataTableOutput(ns("tabwoe"))
        )
      )
    )
  )
} # end of tab4_woe_ui()

# Server function 
tab4_woe_server <- function(input, output, session, td_ids) {
  
  res_vals <- shiny::reactiveValues(segment_groups_dt = NULL)
  
  output$convert_woe <- shiny::renderUI({shiny::actionButton(session$ns("convert_woe"), "Convert WOE Table")})
  
  woe_table <- shiny::reactiveValues()
  
  shiny::observeEvent(input$convert_woe, {
    
    progress <- shiny::Progress$new()
    on.exit(progress$close())
    progress$set(message = "Connecting", value = 0)
    
    #Initializing Variables
    coarse_class_dt <- DBI::dbReadTable(con, td_ids()[["coarse_class_tbl"]])
    coarse_class_woe_dt <- DBI::dbReadTable(con, td_ids()[["coarse_class_woe_tbl"]])
    res_vals$segment_groups_dt <- DBI::dbReadTable(con, td_ids()[["segment_group_tbl"]])
    
    train_dt <- read.csv("data/training_data.csv")
    test_dt <- read.csv("data/test_data.csv")
    
    woe_table$orig_train <- train_dt
    woe_table$orig_test <- test_dt
    
    incl_vars <- coarse_class_dt %>%
      select(segment_group, variable) %>%
      unique
    
    total <- nrow(incl_vars)
    var_ctr <- 0
    progress$set(message = "Converting table", value = var_ctr / total / 2)
    
    convertwoetab <- function(
      bin_sample_dt, 
      var_ctr, 
      sg,
      coarse_class_dt_seg, 
      coarse_class_woe_dt_seg) 
      
    {
      
      relevant_vars <- incl_vars %>%
        filter(segment_group == sg) %>% 
        select(variable) %>% pull
      
      bin_sample_dt <- bin_sample_dt %>%
        select(acct_id, segment, UQ(relevant_vars), target)
      
      #For Loop starts
      for (curr_var in relevant_vars) 
      {
        
        curr_var_lab <- paste0(curr_var, "_woe")
        
        bin_sample_dt <- bin_sample_dt %>%
          rename(curr_var = UQ(curr_var)) %>% 
          left_join(coarse_class_dt_seg %>%
                      filter(variable == curr_var) %>%
                      inner_join(coarse_class_woe_dt_seg %>%
                                   select(variable, new_bin, woe),
                                 by = c("variable", "new_bin")),
                    by = c("curr_var" = "bin")) %>%
          group_by(acct_id) %>% mutate(!!curr_var_lab := woe) %>%
          select(-one_of(c("curr_var", "variable", "new_bin", "woe")))
        
        
        progress$set(message = "Converting table", value = var_ctr / total / 2)
        var_ctr <- var_ctr + 1
      }
      return(bin_sample_dt %>% 
               group_by(acct_id) %>%
               select(matches("(_woe)$|(target)|(segment)|(acct_id)")) %>%
               ungroup
      )
    }
    
    
    segment_groups <- coarse_class_dt %>% 
      select(segment_group) %>%
      pull %>% 
      unique
    
    for (i in segment_groups) 
    {
      
      relevant_segments <- res_vals$segment_groups_dt %>%
        filter(segment_group == i) %>%
        select(segment) %>% 
        pull
      
      train <- train_dt %>% 
        filter(segment %in% relevant_segments)
      
      test <- test_dt %>% 
        filter(segment %in% relevant_segments)
      
      coarse_class_dt_seg <- coarse_class_dt %>% 
        filter(segment_group == i) %>%
        select(-segment_group)
      
      coarse_class_woe_dt_seg <- coarse_class_woe_dt %>%
        filter(segment_group == i) %>% 
        select(-segment_group)
      
      #Calling Function
      woe_table[[as.character(i)]]$train_dt <- convertwoetab(
        train,
        0,
        i,
        coarse_class_dt_seg,
        coarse_class_woe_dt_seg
      )
      
      #Calling Function
      woe_table[[as.character(i)]]$test_dt <- convertwoetab(
        test,
        total,
        i,
        coarse_class_dt_seg,
        coarse_class_woe_dt_seg
      )
    }
    
    
    output$woeviewer <- shiny::renderUI({
      
      sg_labels <- res_vals$segment_groups_dt %>%
        select(segment_group, group_label) %>%
        filter(segment_group %in% (incl_vars %>% 
                                     select(segment_group) %>%
                                     unique %>% 
                                     pull)) %>%
        unique %>% 
        arrange(segment_group)
      
      sg <- sg_labels$segment_group
      names(sg) <- sg_labels$group_label
      
      shiny::selectInput(session$ns("woeviewer"),
                         "Show Segment Group Train WOE Data",
                         choices = sg, 
                         selected = min(sg))
    })
    
  })
  
  output$tabwoe <- DT::renderDataTable({
    
    shiny::req(input$woeviewer)
    
    colnums <- ncol(woe_table[[as.character(input$woeviewer)]]$train_dt)
    
    datatable(
      woe_table[[as.character(input$woeviewer)]]$train_dt,
      rownames = FALSE,
      selection = "none",
      extensions = c("Scroller"),
      options = list(lengthMenu = c(10, 25, 50), pageLength = 25)
    ) %>% DT::formatRound(c(4:colnums), 4)
  })
  
  return(woe_table)
} # end of tab4_woe_server()
