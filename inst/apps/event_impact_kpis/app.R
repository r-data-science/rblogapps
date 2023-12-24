#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#
library(data.table)
library(lubridate)
library(stringr)
library(scales)
library(ggplot2)
library(ggthemes)
library(shiny)
library(shinydashboard)
library(shinydashboardPlus)
library(shinycssloaders)
library(shinyWidgets)
library(rblogapps)


# Define UI for application that draws a histogram
ui <- dashboardPage(
    header = dashboardHeader(title = "Event Impact Comparison"),
    sidebar = dashboardSidebar(
        width = 400,
        collapsed = FALSE,
        fixed = TRUE,
        selectInput("org_selection",
                    label = NULL,
                    choices = get_orgs(),
                    selectize = FALSE,
                    size = 15),
        selectInput("kpi_selection",
                    label = NULL,
                    choices = get_kpi_vars(),
                    selectize = FALSE,
                    size = 10)
    ),
    body = dashboardBody(
        fluidRow(
            box(
                collapsible = FALSE,
                id = "bxstat",
                width = 10,
                status = "primary",
                label = prettyToggle(
                    inputId = "facet_plot",
                    width = "100%",
                    inline = TRUE,
                    bigger = TRUE,
                    icon_off = icon("up-down"),
                    icon_on = icon("compress"),
                    outline = FALSE,
                    thick = TRUE,
                    fill = TRUE,
                    label_on = "Click to show by org",
                    label_off = "Click to show by store",
                    value = TRUE
                ),
                title = uiOutput("selected_labs_ui"),
                withSpinner(
                    tagList(
                        uiOutput("summary_stats_ui"),
                        plotOutput("plot_eventimpact", height = "435px")
                    )
                )
            )
        )
    )
)

# Define server logic required to draw a histogram
server <- function(input, output, session) {

    appdata <- getAppData()

    ## Depending on user input, get corresponding plot
    r_plot_obj <- reactive({
        if (input$facet_plot == TRUE) {
            plotVarByStore(
                dT = appdata[input$org_selection],
                y = input$kpi_selection
            )
        } else {
            plotVarByOrg(
                dT = appdata[input$org_selection],
                y = input$kpi_selection
            )
        }
    })

    ## Retrieve the plot dataset and calculate desired metric average
    ## By Org
    r_stats_by_org <- reactive({
        period_stats <- r_plot_obj()$data[, mean(get(input$kpi_selection)), .(
            b4_hca = month_id < 0
        )]
        prior_start <- r_plot_obj()$data[, min(mon_date)]
        hca_start <- r_plot_obj()$data[
            month_id == 0,
            min(mon_date)
        ]

        ## reformat before and after stats into clean and legible list
        list(
            prior_start = as_date(prior_start),
            hca_start = as_date(hca_start),
            prior_value = period_stats[
                b4_hca == TRUE,
                ifelse(length(V1) == 0, 0, V1)
            ],
            post_value = period_stats[
                b4_hca != TRUE,
                V1
            ]
        )
    })

    ## Retrieve the plot dataset and calculate desired metric average
    ## By Org and Store
    r_stats_by_store <- reactive({

        ## calculate the before and after averages for the KPI using
        ## data extracted from plot
        period_stats <- r_plot_obj()$data[, mean(get(input$kpi_selection)), .(
            facil,
            b4_hca = month_id < 0
        )]


        ## reformat before and after stats into clean and legible list
        stats <- sapply(split(period_stats, period_stats$facil), function(x) {

            ## TODO: may not have 'before' data for some stores
            setNames(list(list(
                prior_value = x[
                    b4_hca == TRUE,
                    ifelse(length(V1) == 0, 0, V1)
                ],
                post_value = x[
                    b4_hca == FALSE,
                    V1
                ]
            )), input$kpi_selection)
        }, simplify = FALSE)



        ## form the data needed for each info box into it's own list element
        lapply(names(stats), function(x) {
            list(
                store = x,
                prior_start = r_plot_obj()$data[
                    facil == x,
                    min(mon_date)
                ],
                hca_start = r_plot_obj()$data[
                    facil == x & month_id == 0,
                    mon_date
                ],
                prior_value = stats[[x]][[input$kpi_selection]]$prior_value,
                post_value = stats[[x]][[input$kpi_selection]]$post_value
            )
        })
    })

    ## Build the appropriate UI statistics boxes containing
    ## the calculated stats above
    r_summary_stat_ui <- reactive({

        ## if toggle false then show by org, else show by org and store
        if (input$facet_plot == FALSE) {
            get_org_stat_summary_ui(
                stat_ll = r_stats_by_org(),
                y = input$kpi_selection
            )
        } else {
            get_store_stat_summary_ui(
                stat_ll = r_stats_by_store(),
                y = input$kpi_selection
            )
        }
    })

    ## Create the badges UI elements containing the user selection inputs
    r_select_labs_ui <- reactive({
        column(12, fluidRow(get_axis_ll(input$kpi_selection)$axis_labl))
    })

    exportTestValues(
        plot_obj = r_plot_obj(),
        stats_by_org = r_stats_by_org(),
        stats_by_store = r_stats_by_store(),
        summary_stat_ui = r_summary_stat_ui(),
        select_labs_ui = r_select_labs_ui()
    )

    ## Render outputs
    output$summary_stats_ui <- renderUI(r_summary_stat_ui())
    output$selected_labs_ui <- renderUI(r_select_labs_ui())
    output$plot_eventimpact <- renderPlot(r_plot_obj(), res = 100)
}

shinyApp(ui = ui, server = server)

