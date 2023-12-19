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
library(data.table)
library(stringr)
library(ggplot2)
library(ggthemes)
library(scales)
library(lubridate)
library(rblogapps)

ui <- dashboardPage(
    header = dashboardHeader(
        titleWidth = 300,
        title = "Retail Sales Performance"
    ),
    sidebar = dashboardSidebar(
        width = 300,
        selectInput(
            inputId = "retail_selection",
            label = "Select Location",
            choices = "",
            multiple = FALSE
        ),
        selectInput(
            inputId = "period_selection",
            label = "Select Period",
            choices = c("Month-To-Date", "Last Month", "Historical"),
            multiple = FALSE
        ),
        selectInput(
            inputId = "metric_selection",
            label = "Select KPI",
            choices = get_kpi_choices(),
            selectize = FALSE,
            multiple = FALSE,
            size = 15
        )
    ),
    body = dashboardBody(
        fluidRow(infoBoxOutput(outputId = "stat_kpi", width = 12)),
        fluidRow(box(
            width = 12,
            height = "950px",
            headerBorder = FALSE,
            plotOutput("plot_kpi", height = 900)
        ))
    )
)

server <- function(input, output, session) {

    # Get data from the package datasets
    DT <- getBlogData("house_brands_kpis")

    # Population selection input with stores found in the data
    observe({
        updateSelectInput(
            inputId = "retail_selection",
            choices = DT[, sort(unique(store))]
        )
    })
    r_retail <- reactive(req(input$retail_selection)) # store location
    r_period <- reactive(req(input$period_selection)) # time period
    r_metric <- reactive(req(input$metric_selection)) # kpi metric

    # This is the html of the info_box
    r_stat_kpi <- reactive({
        get_kpi_definition(DT, r_retail(), r_period(), r_metric())
    })

    # Plot employee performance against selected kpi
    r_plot_kpi <- reactive({
        plotEmployees(DT, r_retail(), r_period(), r_metric())
    })

    # Export values for unit testing against snapshots
    exportTestValues(
        retail   = r_retail(),
        period   = r_period(),
        metric   = r_metric(),
        stat_kpi = r_stat_kpi(),
        plot_kpi = r_plot_kpi()
    )

    # UI output info box
    output$stat_kpi <- renderInfoBox(r_stat_kpi())

    # UI output plot
    output$plot_kpi <- renderPlot(r_plot_kpi(), res = 100, height = 900)
}


shinyApp(ui = ui, server = server)
