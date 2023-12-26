
#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(shinyWidgets)
library(shinydashboard)
library(shinydashboardPlus)
library(waiter)
library(stringr)
library(lubridate)
library(data.table)
library(scales)
library(rblogapps)

org_choices <- getOrgChoices()

ui <- dashboardPage(
    skin = "midnight",
    dashboardHeader(disable = TRUE),
    dashboardSidebar(
        width = "450px",
        dateRangeInput(
            inputId = "daterange",
            label = "Date range:",
            start  = today() - months(12),
            end    = today() - months(3),
            min    = today() - months(12),
            max    = today() - months(3),
            format = "mm/dd/yy",
            separator = " - ",
            width = "100%"
        ),
        multiInput(
            inputId = "orgs_with_training",
            label = "With ZT Training",
            choices = org_choices,
            selected = "bloomroom",
            width = "100%",
            options = list(
                non_selected_header = "Choose:",
                selected_header = "Selection:"
            )
        ),
        multiInput(
            inputId = "orgs_w_no_training",
            label = "Without ZT Training",
            choices = org_choices,
            selected = "spaceflyt",
            width = "100%",
            options = list(
                non_selected_header = "Choose:",
                selected_header = "Selection:"
            )
        ),
        column(11,
               fluidRow(
                   actionBttn(
                       inputId = "btn_run",
                       label = "Run Analysis",
                       block = TRUE,
                       color = "danger",
                       style = "material-flat"
                   )
               )
        )
    ),
    dashboardBody(
        useWaiter(),
        box(
            title = "Comparison of Statistics",
            width = 12,
            headerBorder = FALSE,
            footer = NULL,
            column(
                width = 12,
                fluidRow(
                    column(6, selectInput("brd_selection", "Brand", "", "", width = "100%")),
                    column(6, selectInput("cat_selection", "Category", "", "", width = "100%"))
                )
            ),
            br(),
            fluidRow(
                uiOutput("stats_ui")
            )
        )
    )
)



server <- function(input, output) {
    r_appDT <- eventReactive(input$btn_run, {
        if (is.null(input$orgs_w_no_training) | is.null(input$orgs_with_training)) {
            show_alert("Oops", "Orgs not selected...", type = "error", closeOnClickOutside = TRUE)
            NULL
        } else {
            waiter_show(html = spin_fading_circles())

            appDT <- getAppData(
                yes = input$orgs_with_training,
                no = input$orgs_w_no_training,
                start_date = input$daterange[1],
                stop_date = input$daterange[2]
            )

            brands <- dcast(
                data = appDT[, .N, .(brand_name, has_brand_training)],
                formula = brand_name ~ has_brand_training,
                value.var = "N"
            )[`FALSE` > 10 & `TRUE` > 10, sort(brand_name)]


            tmp <- appDT[brand_name == brands[1], .N, .(
                has_brand_training,
                category
            )]

            categories <- tmp[N > 10, .N, category][N > 1, category]
            updateSelectInput(
                inputId = "cat_selection",
                choices = categories,
                selected = categories[1]
            )

            updateSelectInput(
                inputId = "brd_selection",
                choices = brands,
                selected = brands[1]
            )

            waiter_hide()
            appDT[]
        }
    })

    observe({
        tmp <- req(r_appDT())[brand_name == req(input$brd_selection), .N, .(
            has_brand_training,
            category
        )]
        x <- tmp[N > 5, .N, category][N > 1, category]
        if (length(x) == 0) {
            shinyWidgets::show_alert(
                title = "Oops!",
                text = "Brand has no common category products across the selected retailer groups",
                type = "error"
            )
        } else {
            updateSelectInput(
                inputId = "cat_selection",
                choices = x
            )
        }
    })

    r_stats <- eventReactive(input$cat_selection, {
        getStats(
            req(r_appDT()),
            req(input$brd_selection),
            req(input$cat_selection)
        )
    })


    exportTestValues(
        appDT = r_appDT(),
        stats = r_stats()
    )

    ## Percent Discount
    r_ui_pct_discount <- reactive({
        req(r_stats())

        box(
            title = formatBoxTitle(r_stats()["pct_disc", stat_desc]),
            width = 12,
            headerBorder = TRUE,
            br(),
            valueBox(
                value = r_stats()["pct_disc", formatPercent(no_training)],
                subtitle = "No Brand Training",
                color = r_stats()["pct_disc", c("red", "orange")[c(pct_delta > 0, pct_delta <= 0)]],
                icon = icon("thumbs-down"),
                width = 4
            ),
            valueBox(
                value = r_stats()["pct_disc", formatPercent(with_training)],
                subtitle = "With Brand Training",
                color = r_stats()["pct_disc", c("orange", "red")[c(pct_delta > 0, pct_delta <= 0)]],
                icon = icon("thumbs-up"),
                width = 4
            ),
            valueBox(
                value = r_stats()["pct_disc", formatPercent(pct_delta)],
                subtitle = "Percent Delta",
                color = r_stats()["pct_disc", ifelse(pct_delta < 0, "green", "light-blue")],
                icon = icon("percentage"),
                width = 4
            )
        )
    })

    ## Order Subtotal
    r_ui_order_subtot <- reactive({
        req(r_stats())
        box(
            title = formatBoxTitle(r_stats()["order_subtot", stat_desc]),
            width = 12,
            headerBorder = TRUE,
            br(),
            valueBox(
                value = r_stats()["order_subtot", formatDollers(no_training)],
                subtitle = "No Brand Training",
                color = r_stats()["order_subtot", c("red", "orange")[c(pct_delta > 0, pct_delta <= 0)]],
                icon = icon("thumbs-down"),
                width = 4
            ),
            valueBox(
                value = r_stats()["order_subtot", formatDollers(with_training)],
                subtitle = "With Brand Training",
                color = r_stats()["order_subtot", c("orange", "red")[c(pct_delta > 0, pct_delta <= 0)]],
                icon = icon("thumbs-up"),
                width = 4
            ),
            valueBox(
                value = r_stats()["order_subtot", formatPercent(pct_delta)],
                subtitle = "Percent Delta",
                color = r_stats()["order_subtot", ifelse(pct_delta > 0, "green", "light-blue")],
                icon = icon("percentage"),
                width = 4
            )
        )
    })

    ## Share of order (percent)
    r_ui_order_share_pct <- reactive({
        req(r_stats())

        box(
            title = formatBoxTitle(r_stats()["pct_order", stat_desc]),
            width = 12,
            headerBorder = TRUE,
            br(),
            valueBox(
                value = r_stats()["pct_order", formatPercent(no_training)],
                subtitle = "No Brand Training",
                color = r_stats()["pct_order", c("red", "orange")[c(pct_delta > 0, pct_delta <= 0)]],
                icon = icon("thumbs-down"),
                width = 4
            ),
            valueBox(
                value = r_stats()["pct_order", formatPercent(with_training)],
                subtitle = "With Brand Training",
                color = r_stats()["pct_order", c("orange", "red")[c(pct_delta > 0, pct_delta <= 0)]],
                icon = icon("thumbs-up"),
                width = 4
            ),
            valueBox(
                value = r_stats()["pct_order", formatPercent(pct_delta)],
                subtitle = "Percent Delta",
                color = r_stats()["pct_order", ifelse(pct_delta > 0, "green", "light-blue")],
                icon = icon("percentage"),
                width = 4
            )
        )
    })

    ## Share of order (dollars)
    r_ui_order_share_usd <- reactive({
        req(r_stats())
        box(
            title = formatBoxTitle(r_stats()["amt_order", stat_desc]),
            width = 12,
            headerBorder = TRUE,
            br(),
            valueBox(
                value = r_stats()["amt_order", formatDollers(no_training)],
                subtitle = "No Brand Training",
                color = r_stats()["amt_order", c("red", "orange")[c(pct_delta > 0, pct_delta <= 0)]],
                icon = icon("thumbs-down"),
                width = 4
            ),
            valueBox(
                value = r_stats()["amt_order", formatDollers(with_training)],
                subtitle = "With Brand Training",
                color = r_stats()["amt_order", c("orange", "red")[c(pct_delta > 0, pct_delta <= 0)]],
                icon = icon("thumbs-up"),
                width = 4
            ),
            valueBox(
                value = r_stats()["amt_order", formatPercent(pct_delta)],
                subtitle = "Percent Delta",
                color = r_stats()["amt_order", ifelse(pct_delta > 0, "green", "light-blue")],
                icon = icon("percentage"),
                width = 4
            )
        )
    })

    output$stats_ui <- renderUI({
        tagList(
            r_ui_pct_discount(),
            r_ui_order_subtot(),
            r_ui_order_share_pct(),
            r_ui_order_share_usd()
        )
    })
}

# Run the application
shinyApp(ui = ui, server = server)
