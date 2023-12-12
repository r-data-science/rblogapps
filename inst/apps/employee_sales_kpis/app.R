#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(shinydashboard)
library(shinydashboardPlus)
library(shinyWidgets)
library(shinycssloaders)
library(data.table)
library(stringr)
library(ggplot2)
library(ggthemes)
library(ggpubr)
library(scales)
library(lubridate)
library(rblogapps)

# UI ------------------------------------------------------------------------------------------

cat_choices <- list(
    Flower = "FLOWER",
    Prerolls = "PREROLLS",
    Vapes = "VAPES",
    Extracts = "EXTRACTS",
    Edibles = "EDIBLES",
    Drinks = "DRINKS",
    `Tabs & Caps` = "TABLETS_CAPSULES",
    Topicals = "TOPICALS",
    Tinctures = "TINCTURES"
)

## dashboard sidebar
sidebar <- dashboardSidebar(
    width = 300,
    sidebarMenu(
        menuItem(
            selected = TRUE,
            startExpanded = TRUE,
            text = "Select Org",
            tabName = "dashboard",
            icon = icon("store"),
            selectInput(inputId = "org_selection",
                        label = NULL,
                        choices = "",
                        multiple = FALSE)
        ),
        menuItem(
            text = "Select Location",
            tabName = "dashboard",
            icon = icon("map"),
            selectInput(inputId = "facility_selection",
                        label = NULL,
                        choices = "",
                        multiple = FALSE)
        ),
        menuItem(
            text = "Overall Velocity",
            tabName = "dashboard",
            icon = icon("dashboard")
        ),
        menuItem(
            text = "By Category",
            icon = icon("joint"),
            menuSubItem(
                href = NULL,
                tabName = "widgets",
                icon = NULL,
                newtab = FALSE,
                selectInput(
                    inputId = "category_selection",
                    label = "Performance By Category",
                    choices = cat_choices
                )
            )
        ),
        menuItem(
            text = "By Employee",
            icon = icon("user"),
            menuSubItem(
                href = NULL,
                tabName = "panels",
                icon = NULL,
                newtab = FALSE,
                selectInput(
                    inputId = "bdr_selection",
                    label = "Performance By Budtender",
                    choices = ""
                )
            )
        )
    )
)

## dashboard body
body <- dashboardBody(
    tabItems(
        tabItem(
            tabName = "dashboard",
            fluidRow(
                box(
                    id = "foo1",
                    title = "",
                    label = "",
                    headerBorder = FALSE,
                    height = "100px",
                    width = 12,
                    tags$head(tags$style('#foo1 .box-header{ display: none}')),
                    withSpinner(
                        uiOutput("ui_perf_overall"),
                        proxy.height = "100px"
                    )
                )
            ),
            fluidRow(
                box(
                    id = "foo2",
                    title = "",
                    headerBorder = FALSE,
                    height = "100px",
                    width = 6,
                    tags$head(tags$style('#foo2 .box-header{ display: none}')),
                    withSpinner(
                        uiOutput("ui_perf_cats_1"),
                        proxy.height = "200px"
                    )
                ),
                box(
                    id = "foo3",
                    title = "",
                    headerBorder = FALSE,
                    height = "100px",
                    width = 6,
                    tags$head(tags$style('#foo3 .box-header{ display: none}')),
                    withSpinner(
                        uiOutput("ui_perf_cats_2"),
                        proxy.height = "200px"
                    )
                )
            ),
            fluidRow(
                box(
                    id = "foo4",
                    title = "",
                    label = "",
                    collapsible = FALSE,
                    width = 12,
                    headerBorder = FALSE,
                    tags$head(tags$style('#foo4 .box-header{ display: none}')),
                    withSpinner(
                        plotOutput("plot_sales_per_day", fill = TRUE, height = 1000)
                    )
                )
            )
        ),
        tabItem(
            tabName = "widgets",
            fluidRow(
                box(
                    title = "Average Sales Per Hour",
                    label = uiOutput("box_label_1"),
                    collapsible = FALSE,
                    background = "gray",
                    headerBorder = FALSE,
                    solidHeader = TRUE,
                    width = 12,
                    fluidRow(
                        withSpinner(
                            tagList(
                                valueBoxOutput("ibx_cat_sphr_high", width = 4),
                                valueBoxOutput("ibx_cat_sphr_mid", width = 4),
                                valueBoxOutput("ibx_cat_sphr_low", width = 4)
                            ),
                            proxy.height = "100px"
                        )
                    ),
                    footer = withSpinner(
                        uiOutput("impact_analysis_ui"),
                        proxy.height = "100px"
                    )
                )
            ),
            fluidRow(
                box(
                    title = "Budtenders Sales Per Hour",
                    label = uiOutput("box_label_2"),
                    collapsible = FALSE,
                    width = 12,
                    headerBorder = TRUE,
                    withSpinner(
                        plotOutput("plot_sales_per_hour", fill = TRUE, height = 1000)
                    )
                )
            )
        ),
        tabItem(
            tabName = "panels",
            fluidRow(
                box(
                    title = "Sales Per Hour by Category",
                    label = uiOutput("box_label_3"),
                    collapsible = FALSE,
                    width = 12,
                    headerBorder = FALSE,
                    withSpinner(
                        plotOutput("plot_bdr_performance", fill = TRUE, height = 1000)
                    )
                )
            )
        )
    )
)

# dashboard page
ui <- dashboardPage(
    header = dashboardHeader(titleWidth = 300, title = "Budtender KPIs"),
    sidebar = sidebar,
    body = body
)

# server --------------------------------------------------------------------------------------

server <- function(input, output, session) {

    ## Get app data and update first required selection box
    appdata <- getAppData("employee_sales_kpis")

    observe({
        updateSelectInput(
            inputId = "org_selection",
            choices = appdata[, unique(org)]
        )
    })


    ## Get Org Orders on selection
    ##
    r_ordersDT <- reactive({
        appdata[org == req(input$org_selection)]
    })

    ## Update select UI elements with values
    ##
    observe({
        updateSelectInput(
            inputId = "facility_selection",
            choices = r_ordersDT()[, .N, keyby = store][, store]
        )
    })
    observe({
        updateSelectInput(
            inputId = "bdr_selection",
            choices = r_ordersDT()[
                store == req(input$facility_selection),
                sort(unique(employee))
            ]
        )
    })

    ## Filter on orders on store selection
    ##
    r_store_orders <- reactive({
        r_ordersDT()[store == req(input$facility_selection)]
    })

    ## Export test data
    exportTestValues(r_store_orders = r_store_orders())

    ## Set box titles and labels where needed
    ##
    output$box_label_1 <- renderUI({
        boxLabel(
            str_to_title(req(input$category_selection)),
            status = "primary"
        )
    })
    output$box_label_2 <- renderUI({
        list(
            boxLabel(
                str_to_title(req(input$category_selection)),
                status = "primary"
            ), "vs",
            boxLabel("All Others", status = "info")
        )
    })
    output$box_label_3 <- renderUI({
        list(
            boxLabel(
                str_to_title(req(input$bdr_selection)),
                status = "warning"
            ), "vs",
            boxLabel(
                paste0(str_to_title(req(input$facility_selection)), " Average"),
                status = "info"
            )
        )
    })

    ## Get first reactive result. Note this function returns a list
    ##
    r_sales_per_day <- reactive({
        plotSalesPerDay(r_store_orders())
    })
    r_sales_per_hour <- reactive({
        plotSalesPerHour(r_store_orders(), req(input$category_selection))
    })
    r_high_low_stats <- reactive({
        getHighLowStats(r_sales_per_day()$data)
    })

    ## Export test data
    exportTestValues(
        r_sales_per_day  = r_sales_per_day(),
        r_sales_per_hour = r_sales_per_hour(),
        r_high_low_stats = r_high_low_stats()
    )

    ## Set the value boxes describing average performance by group
    ##
    output$ibx_cat_sphr_high <- renderValueBox({
        valueBox(
            value = req(r_sales_per_hour())$summ[
                category2 == req(input$category_selection),
                Top
            ],
            subtitle = "Top Performing Budtenders",
            icon = shiny::icon("dollar-sign"),
            color = "green",
            width = 12,
            href = NULL
        )
    })

    output$ibx_cat_sphr_mid <- renderInfoBox({
        valueBox(
            value = req(r_sales_per_hour())$summ[
                category2 == req(input$category_selection),
                Middle
            ],
            subtitle = "Mid Performing Budtenders",
            icon = shiny::icon("dollar-sign"),
            color = "light-blue",
            width = 12,
            href = NULL
        )
    })

    output$ibx_cat_sphr_low <- renderInfoBox({
        valueBox(
            value = req(r_sales_per_hour())$summ[
                category2 == req(input$category_selection),
                Low
            ],
            subtitle = "Low Performing Budtenders",
            icon = shiny::icon("dollar-sign"),
            color = "red",
            width = 12,
            href = NULL
        )
    })

    ## Set the description block UI describing the training impact analysis
    ##
    output$impact_analysis_ui <- renderUI({

        SPH <- req(r_sales_per_hour())

        ## budtenders identified
        n_bdrs <- SPH$n_low

        ## training impact on category velocity
        tr_imp <- SPH$impact$target_training_impact

        ## training impact on revenue velocity
        vt_imp <- SPH$impact$pct_sales_per_hour_gain

        ## training impact on revenue per day
        sd_imp <- SPH$impact$est_sales_per_day_impact

        boxPad(
            fluidRow(
                column(
                    width = 3,
                    descriptionBlock(
                        number = n_bdrs,
                        numberColor = "red",
                        numberIcon = icon("crosshairs"),
                        header = "Identified Budtenders",
                        text = "Training Targets",
                        rightBorder = TRUE,
                        marginBottom = TRUE
                    )
                ),
                column(
                    width = 3,
                    descriptionBlock(
                        number = scales::percent(tr_imp, prefix = "+", accuracy = 1),
                        numberColor = "blue",
                        numberIcon = icon("bullseye"),
                        header = "Increase in Unit Sales",
                        text = "Category Sales",
                        rightBorder = TRUE,
                        marginBottom = TRUE
                    )
                ),
                column(
                    width = 3,
                    descriptionBlock(
                        number = scales::percent(vt_imp, prefix = "+", accuracy = 1),
                        numberColor = "green",
                        numberIcon = icon("chart-line"),
                        header = "Higher Overall Sales",
                        text = "Revenue Growth",
                        rightBorder = TRUE,
                        marginBottom = TRUE
                    )
                ),
                column(
                    width = 3,
                    descriptionBlock(
                        number = scales::dollar(sd_imp, accuracy = 1),
                        numberColor = "green",
                        numberIcon = icon("money-bill-trend-up"),
                        header = "Additional $ Per Day",
                        text = "Dollar Impact",
                        rightBorder = FALSE,
                        marginBottom = TRUE
                    )
                )
            )
        )
    })

    output$ui_perf_overall <- renderUI({

        HLS <- req(r_high_low_stats())

        ## ave sales per day
        spd_top <- HLS$overall[perf_group == "ave_sales_pday", Top]
        spd_low <- HLS$overall[perf_group == "ave_sales_pday", Low]

        ## ave units per day
        upd_top <- HLS$overall[perf_group == "ave_units_pday", Top]
        upd_low <- HLS$overall[perf_group == "ave_units_pday", Low]

        fluidRow(
            column(
                width = 3,
                descriptionBlock(
                    number = "High Performance",
                    header = upd_top,
                    numberColor = "green",
                    numberIcon = icon("trophy"),
                    text = "Units Per Day",
                    marginBottom = FALSE,
                    rightBorder = FALSE
                )
            ),
            column(
                width = 3,
                descriptionBlock(
                    number = "Low Performance",
                    numberColor = "yellow",
                    numberIcon = icon("face-frown"),
                    header = upd_low,
                    text = "Units Per Day",
                    marginBottom = FALSE,
                    rightBorder = TRUE
                )
            ),
            column(
                width = 3,
                descriptionBlock(
                    number = "High Performance",
                    header = spd_top,
                    numberColor = "green",
                    numberIcon = icon("trophy"),
                    text = "Sales Per Day",
                    marginBottom = FALSE,
                    rightBorder = FALSE
                )
            ),
            column(
                width = 3,
                descriptionBlock(
                    number = "Low Performance",
                    header = spd_low,
                    numberColor = "yellow",
                    numberIcon = icon("face-frown"),
                    text = "Sales Per Day",
                    marginBottom = FALSE,
                    rightBorder = FALSE
                )
            )
        )
    })

    ## For UI description box elements below
    f <- function(r, perf) {
        if (r[["category"]] == "TABLETS_CAPSULES")
            r[["category"]] <- "TABS & CAPS"
        descriptionBlock(
            number = r[[perf]],
            header = str_to_title(r[["category"]]),
            rightBorder = FALSE,
            marginBottom = FALSE
        )
    }

    ## Ave orders per day
    ##
    output$ui_perf_cats_1 <- renderUI({

        HLS <- req(r_high_low_stats())

        opd_cats_top <- HLS$category$ordersPerDay[order(category)]

        ll_db_high <- tagList(
            descriptionBlock(
                number = "High Performance",
                numberIcon = icon("trophy"),
                text = "Orders Per Day",
                rightBorder = FALSE,
                marginBottom = FALSE
            ),
            apply(opd_cats_top, 1, f, perf = "Top", simplify = FALSE)
        )
        ll_db_low <- tagList(
            descriptionBlock(
                number = "Low Performance",
                numberIcon = icon("face-frown"),
                text = "Orders Per Day",
                rightBorder = FALSE,
                marginBottom = FALSE
            ),
            apply(opd_cats_top, 1, f, perf = "Low", simplify = FALSE)
        )
        fluidRow(
            column(width = 6, boxPad(color = "olive", ll_db_high)),
            column(width = 6, boxPad(color = "yellow", ll_db_low))
        )
    })

    ## Ave Ticket Size
    ##
    output$ui_perf_cats_2 <- renderUI({

        HLS <- req(r_high_low_stats())

        osz_cats_top <- HLS$category$ticketSize[order(category)]

        ll_db_high <- tagList(
            descriptionBlock(
                number = "High Performance",
                numberIcon = icon("trophy"),
                text = "Ave Ticket Size",
                rightBorder = FALSE,
                marginBottom = FALSE
            ),
            apply(osz_cats_top, 1, f, perf = "Top", simplify = FALSE)
        )
        ll_db_low <- tagList(
            descriptionBlock(
                number = "Low Performance",
                numberIcon = icon("face-frown"),
                text = "Ave Ticket Size",
                rightBorder = FALSE,
                marginBottom = FALSE
            ),
            apply(osz_cats_top, 1, f, perf = "Low", simplify = FALSE)
        )
        fluidRow(
            column(width = 6, boxPad(color = "olive", ll_db_high)),
            column(width = 6, boxPad(color = "yellow", ll_db_low))
        )
    })

    r_employ_summary <- reactive({
        req(r_ordersDT())[, .(
            orders = length(unique(order_id)),
            units = sum(units_sold),
            sales = sum(sub_total)
        ), keyby = .(
            store,
            employee,
            order_date = lubridate::as_date(order_utc),
            order_hour = lubridate::hour(order_utc),
            category
        )][, sales_per_unit := sales / units][]
    })

    r_plot_staff_perf <- reactive({
        plotBdrPerformance(
            req(r_employ_summary()),
            req(input$facility_selection),
            req(input$bdr_selection)
        )
    })

    exportTestValues(
        r_employ_summary = r_employ_summary(),
        r_plot_staff_perf = r_plot_staff_perf()
    )

    ## Set the plot ui elements
    ##
    output$plot_sales_per_day <- renderPlot(res = 75, height = 1000, {
        r_sales_per_day()$plot
    })
    output$plot_sales_per_hour <- renderPlot(res = 75, height = 1000, {
        r_sales_per_hour()$plot
    })
    output$plot_bdr_performance <- renderPlot(res = 75, height = 1000, {
        r_plot_staff_perf()
    })
}

# Run the application
shinyApp(ui = ui, server = server)
