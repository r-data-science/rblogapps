#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#
# library(bs4Dash)
library(data.table)
# library(hcaconfig)
library(stringr)
library(lubridate)
library(shiny)
library(shinyjs)
library(shinybusy)
library(scales)
library(callr)
library(bslib)
library(bsicons)
library(shinyWidgets)
# library(crosstalk)
library(DT)
library(DBI)
# library(htmltools)
library(rpgconn)


# Define UI for application that draws a histogram
ui <- page_sidebar(
  useShinyjs(),
  title = "Transactions Data Report",
  window_title = "Point-of-Sale",
  sidebar = sidebar(
    width = "300px",
    open = TRUE,
    bslib::accordion(
      bslib::accordion_panel(
        icon = icon("calendar"),
        title = "Select Date",
        dateInput(
          inputId = "report_date",
          label = NULL,
          value = today() - days(90),
          max = today() - days(1),
          min = today() - days(90),
          width = "100%"
        )
      ),

      bslib::accordion_panel(
        icon = icon("database"),
        title = "Filter by POS",

        shinyWidgets::multiInput(
          "pos_filter",
          "Select None to Include All In Report",
          choices = index_full[, sort(unique(store_pos))],
          options = list(
            limit = -1,
            selected_header = "Selected",
            non_selected_header = "POS"
          )
        )
      )
    )
  ),

  bslib::card(
    shinyWidgets::radioGroupButtons(
      status = "default",
      size = "normal",
      justified = TRUE,
      width = "100%",
      inputId = "host_config",
      label = NULL,
      choices = c("prod", "dev", "stage", "local"),
      selected = "prod",
      checkIcon = list(
        yes = htmltools::tags$i(
          class = "fa fa-check-square",
          style = "color: red"
        ),
        no = htmltools::tags$i(
          class = "fa fa-square-o",
          style = "color: red")
      )
    ),

    max_height = "200px",

    fluidRow(
      column(
        width = 8,
        shinyWidgets::actionBttn(
          inputId = "begin_job",
          icon = icon("arrows-rotate"),
          label = "Run Job",
          style = "fill",
          color = "danger",
          size = "sm",
          block = TRUE
        )
      ),
      column(
        width = 4,
        shinyWidgets::actionBttn(
          inputId = "pause_job",
          label = "Pause Job",
          icon = icon("pause"),
          style = "fill",
          color = "primary",
          size = "sm",
          block = TRUE
        )
      )
    ),
    bslib::card_footer(
      shinybusy::progress_line(
        text = "Status: Not Started",
        value = 0,
        shiny_id = "bar",
        color = "red",
        stroke_width = 40,
        duration = 500,
        easing = "easeInOut",
        text_color = "firebrick",
        width = "100%",
        trail_color = "white",
        trail_width = 20
      ),
      class = "m-0"
    )
  ),

  bslib::card(
    min_height = "500px",
    max_height = "500px",
    bslib::card_header(
      fluidRow(
        column(
          width = 10,
          bslib::tooltip(
            shinyWidgets::prettyToggle(
              inputId = "download_on_complete",
              shape = "curve",
              value = TRUE,
              width = "20%",
              fill = TRUE,
              thick = TRUE,
              bigger = TRUE,
              label_on = "Auto-Download On",
              icon_on = icon("check"),
              status_on = "danger",
              status_off = "primary",
              label_off = "Auto-Download Off",
              icon_off = icon("xmark")
            ),
            "Download automatically when complete",
            placement = "bottom")
        ),
        column(
          width = 2,
          shinyWidgets::downloadBttn(
            block = TRUE,
            outputId = 'download',
            label = "",
            icon = bslib::tooltip(
              shiny::span(bsicons::bs_icon("download")),
              "Download logs currently shown",
              placement = "top"
            ),
            color = "primary",
            style = "jelly",
            size = "xs"
          )
        )
      ),
      class = "p-3"
    ),
    bslib::card_body(
      DT::DTOutput("tableOutput"),
      padding = "10px",
      gap = 0,
      fill = TRUE
    ),
    class = "m-0 p-0 border border-top-0 rounded-bottom"
  )
)





server <- function(input, output, session) {

  # Global var containing column names for the output table
  cnams <- c("org_name",
             "store",
             "report_date",
             "orders",
             "sales",
             "db",
             "source")

  # Helper fun to init an Entries table each time a new report is launched
  newLogTable <- function() {
    cbind(
      entry = integer(0),
      setDT(sapply(cnams, function(x) list(character(0))))
    )
  }

  # filter index on orgs and locations if selected
  r_indx <- reactive({
    if (!is.null(input$pos_filter))
      setkey(index_full, "store_pos")[
        (input$pos_filter)
      ][order(store_pos, org_short)]
    else
      index_full[]
  })

  HAS_DOWNLOADED <- FALSE                 # Flag ensures auto-download runs only once on completion if option is enabled
  tot <- 0                                # Get total orgs/store rows for progress bar, init with 0
  entries <- newLogTable()                # For persisting log entries into session table
  r_timer <- reactiveValues(poll = FALSE) # reactive flag to stop polling when report is complete

  r <- eventReactive(input$begin_job, {
    indx <- r_indx()

    tot <<- indx[, .N]           # Update total orgs/store rows for progress bar
    r_timer$poll <- TRUE         # initialize flag to let renderDT know to keep polling for new data
    shinyjs::enable("pause_job") # Enable the pause button on new job launch
    HAS_DOWNLOADED <<- FALSE     # Reset flag to ensure auto-download runs only once if option enabled

    # Ensure start/stop button says pause when job has started
    updateActionButton(
      inputId = "pause_job",
      icon = icon("pause"),
      label = "Pause Job"
    )
    shinybusy::update_progress(
      shiny_id = "bar",
      value = 0,
      text = "Status...Starting"
    )

    # Reset persisted entries if they exist and start background job
    entries <<- newLogTable()

    bg <- callr::r_bg(
      func = dbSummaryLog,
      args = list(
        cfg = input$host_config,
        rep_date = input$report_date,
        indx = r_indx()
      ),
      package = TRUE,
      supervise = TRUE
    )

    # Register kill function to run on app stop and return bg object
    onStop(bg$kill, session)
    return(bg)
  })

  observeEvent(input$pause_job, {
    if (r()$get_status() == "stopped") {
      r()$resume()
      updateActionButton(
        session,
        inputId = "pause_job",
        icon = icon("pause"),
        label = "Pause Job"
      )
    } else {
      r()$suspend()
      updateActionButton(
        session,
        inputId = "pause_job",
        icon = icon("play"),
        label = "Resume Job"
      )
    }
  })

  # React to new entries if they exist, binding them to the full results
  r_all_entries <- reactive({
    invalidateLater(500, session) # Poll for new log entries printed by bg job every 500ms

    # parse into table, bind new rows to full entry table
    new_rows <- r()$read_output_lines() |>
      stringr::str_trim("both") |>
      stringr::str_split(pattern = " +", n = length(cnams), simplify = TRUE) |>
      data.table::as.data.table()

    if (nrow(new_rows) > 0) {
      new_rows[, entry := as.integer((nrow(entries) + 1):(nrow(entries) + .N))]
      new_rows |>
        data.table::setcolorder("entry") |>
        data.table::setnames(names(entries))
      entries <<- data.table::rbindlist(list(new_rows, entries), use.names = TRUE)
    }
    entries[order(-entry)]
  })

  # Observe progress and set flag when complete so finished table stops rendering
  observe({
    pct <- nrow(r_all_entries()) / tot
    pct_lab <- scales::percent(pct, accuracy = 1)

    # If near complete, disable pause to avoid user action on finished job
    if (pct > .9)
      shinyjs::disable("pause_job")

    if (nrow(r_all_entries()) == tot) {
      r_timer$poll <- FALSE
    } else {
      status <- tryCatch(
        r()$get_status(),
        error = function(c) "done",
        warning = function(c) "done"
      )

      if (status == "stopped") {
        shinybusy::update_progress("bar", pct, "Status ...Paused")  # If job is paused, update the status on the progress bar
      } else if (status == "done") {
        shinybusy::update_progress("bar", 1, "Status ...Complete")  # If job is paused, update the status on the progress bar
      } else if (nrow(r_all_entries()) > 0) {
        shinybusy::update_progress("bar", pct, paste0("Status ...Running (", pct_lab, ")"))
      }
    }
  })

  # get new parsed entries, append to existing rows and display
  output$tableOutput <- DT::renderDT({

    # If job is running, render the reactive entries var, else, isolate the completed table
    if (r_timer$poll)
      OUT <- r_all_entries()
    else
      OUT <- isolate(r_all_entries())

    DT::datatable(
      OUT,
      filter = "none",
      fillContainer = TRUE,
      style = "bootstrap4",
      rownames = FALSE,
      options = list(
        lengthChange = FALSE,
        searching = FALSE,
        paging = FALSE
      )
    )
  }, server = FALSE)

  # Handle the download action, provide data as csv file
  output$download <- downloadHandler(
    filename = function() {
      cfg <- input$host_config
      utc <- input$report_date
      uid <- str_sub(as.numeric(now()), 12, 14)
      return(str_glue("{cfg}_{utc}_x{uid}.csv"))
    },
    content = function(fn) write.csv(r_all_entries(), fn, row.names = FALSE)
  )

  # Auto-download results on finish if option is active,
  observe({
    if (nrow(r_all_entries()) == tot) {
      shinybusy::update_progress("bar", 1, "Status: ...Complete")

      if (input$download_on_complete) {       # Check if user option to auto-download is checked
        if (!HAS_DOWNLOADED) {                # Ensure completed report has not already been auto-downloaded
          HAS_DOWNLOADED <<- TRUE             # Set flag to TRUE to avoid this running more than once per report
          shinyjs::runjs("$('#download')[0].click();") # Trigger the auto-download
        }
      }
    }
  })
}

# Run the application
shinyApp(ui = ui, server = server)

