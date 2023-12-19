library(shiny)
library(shinyjs)
library(shinyWidgets)
library(bs4Dash)
library(ggplot2)
library(ggthemes)
library(ggtext)
library(datamods)
library(DT)
library(data.table)
library(stringr)
library(scales)
library(fs)
library(magick)
library(rblogapps)

ui <- fluidPage(
  useShinyjs(),
  h2("Revenue Impact of Product Stockouts"),
  panel(
    height = "850px",
    heading = tagList(
      pickerInput(
        inputId = "org",
        label = "Select Organization",
        multiple = FALSE,
        width = "100%",
        selected = "Org 1",
        choices = c("Org 1", "Org 4", "Org 8"),
        options = list(`live-search` = TRUE, title = "None Selected")
      )
    ),
    select_group_ui(
      id = "my-filters",
      params = list(
        store = list(inputId = "store", placeholder = "Stores"),
        category = list(inputId = "category", placeholder = "Categories"),
        brand_name = list(inputId = "brand_name", placeholder = "Brands"),
        product_sku = list(inputId = "product_sku", placeholder = "Products")
      )
    ),
    status = "primary",
    extra = column(12, DTOutput("args_table", height = "350px")),
    footer = actionBttn(
      inputId = "eval",
      style = "fill",
      block = TRUE,
      size = "sm",
      color = "primary",
      label = "Select Product From Table Above"
    )
  ),
  tabBox(
    id = "tabset1",
    status = "primary",
    collapsible = FALSE,
    headerBorder = TRUE,
    height = "1150px",
    width = 12,
    side = "right",
    solidHeader = TRUE,
    elevation = 1,
    selected = 1,
    tabPanel(
      value = 1,
      title = "Impact Plot",
      icon = icon("line-chart"),
      plotOutput(outputId = "plot_impact", height = 1250)
    ),
    tabPanel(
      value = 2,
      title = "Dataset",
      icon = icon("table"),
      DTOutput(outputId = "plot_data", height = "450px")
    )
  )
)

server <- function(input, output, session) {
  r_index <- reactive(getAppIndex(req(input$org)))

  res_mod <- select_group_server(
    id = "my-filters",
    data_r = r_index,
    vars_r = c("store", "category", "brand_name", "product_sku")
  )

  output$args_table <- renderDT(getArgsDT(res_mod()), server = TRUE)

  observe({
    if (!is.null(input$args_table_rows_selected)) {
      updateActionButton(
        session = session,
        inputId = "eval",
        label = "Estimate Stockout Revenue Loss"
      )
      enable("eval")
    } else {
      updateActionButton(
        session = session,
        inputId = "eval",
        label = "Select Product From Table Above"
      )
      disable("eval")
    }
  })

  r_plot_impact <- eventReactive(input$eval, {
    store <- r_index()[req(input$args_table_rows_selected), store]
    sku <- r_index()[req(input$args_table_rows_selected), product_sku]
    salesDT <- getVtDaily(req(input$org), store, sku)
    plot_period_impact(salesDT, sku, 50)
  })

  exportTestValues(plot_impact = r_plot_impact())

  output$plot_data <- renderDT(getPlotDT(r_plot_impact()), server = TRUE)
  output$plot_impact <- renderPlot(r_plot_impact(), res = 150)
}

shinyApp(ui, server)
