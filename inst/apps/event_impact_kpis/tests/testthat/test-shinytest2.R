library(shinytest2)
library(vdiffr)


test_that("{shinytest2} recording: event_impact_kpis", {

  expect_exports <- function(id) {
    app$get_value(export = "plot_obj") |>
      expect_doppelganger(title = paste0("plot ", id))

    if (app$get_value(input = "facet_plot")) {
      app$get_value(export = "stats_by_store") |>
        expect_snapshot_value(style = "json2", tolerance = .001)
    } else {
      app$get_value(export = "stats_by_org") |>
        expect_snapshot_value(style = "json2", tolerance = .001)
    }
    app$get_value(export = "select_labs_ui") |>
      as.character() |>
      expect_snapshot_value(style = "json2")

    app$get_value(export = "summary_stat_ui") |>
      as.character() |>
      expect_snapshot_value(style = "json2")
  }

  app <- AppDriver$new(name = "event_impact_kpis")
  expect_exports(1)
  app$set_inputs(kpi_selection = "total_sales")
  expect_exports(2)
  app$set_inputs(kpi_selection = "total_units")
  expect_exports(3)
  app$set_inputs(kpi_selection = "total_orders")
  expect_exports(4)
  app$set_inputs(kpi_selection = "pct_retail_units")
  expect_exports(5)
  app$set_inputs(kpi_selection = "pct_retail_sales")
  expect_exports(6)
  app$set_inputs(kpi_selection = "n_uniq_customers")
  expect_exports(7)
  app$set_inputs(kpi_selection = "n_uniq_brands")
  expect_exports(8)
  app$set_inputs(kpi_selection = "n_uniq_products")
  expect_exports(9)
  app$set_inputs(kpi_selection = "ave_disc_rate")
  expect_exports(10)
  app$set_inputs(facet_plot = FALSE)
  app$wait_for_idle(1000)
  expect_exports(id = 11)
  app$set_inputs(kpi_selection = "n_uniq_products")
  expect_exports(12)
  app$set_inputs(kpi_selection = "n_uniq_brands")
  expect_exports(13)
  app$set_inputs(kpi_selection = "n_uniq_customers")
  expect_exports(14)
  app$set_inputs(kpi_selection = "pct_retail_sales")
  expect_exports(15)
  app$set_inputs(kpi_selection = "pct_retail_units")
  expect_exports(16)
  app$set_inputs(kpi_selection = "total_orders")
  expect_exports(17)
  app$set_inputs(kpi_selection = "total_units")
  expect_exports(18)
  app$set_inputs(kpi_selection = "total_sales")
  expect_exports(19)
  app$set_inputs(kpi_selection = "sales_per_order")
  expect_exports(20)
  app$set_inputs(org_selection = "Org 8")
  expect_exports(21)
  app$set_inputs(kpi_selection = "total_orders")
  app$set_inputs(facet_plot = TRUE)
  app$wait_for_idle(1000)
  expect_exports(22)
  app$set_inputs(org_selection = "Org 12")
  app$set_inputs(kpi_selection = "ave_disc_rate")
  expect_exports(23)
})
