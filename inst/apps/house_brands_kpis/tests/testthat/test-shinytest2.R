library(shinytest2)
library(vdiffr)

test_that("{shinytest2} recording: house_brands_kpis", {

  # increment each time a new snapshot is created
  test_iter <- 0

  expect_exports <- function() {

    ## Check the KPI info box
    app$get_value(export = "stat_kpi") |>
      as.character() |>
      stringr::str_squish() |>
      expect_snapshot_value()

    ## Check the plot
    p <- app$get_value(export = "plot_kpi")

    # Need unique name for each plot snapshot
    test_iter <<- test_iter + 1
    plot_name <- paste0("plot_kpi_", test_iter)

    expect_doppelganger(p, title = plot_name)
  }

  app <- AppDriver$new(name = "house_brands_kpis")
  expect_exports()

  app$set_inputs(metric_selection = "order_days")
  expect_exports()

  app$set_inputs(metric_selection = "orders_per_day")
  expect_exports()

  app$set_inputs(metric_selection = "dollars_per_day")
  expect_exports()

  app$set_inputs(metric_selection = "ave_order_size_no_house")
  expect_exports()

  app$set_inputs(metric_selection = "ave_order_size_house")
  expect_exports()

  app$set_inputs(metric_selection = "ave_house_dollars_per_order")
  expect_exports()

  app$set_inputs(metric_selection = "house_order_premium")
  expect_exports()

  app$set_inputs(metric_selection = "pct_orders_house")
  expect_exports()

  app$set_inputs(metric_selection = "pct_sales_house")
  expect_exports()

  app$set_inputs(period_selection = "Last Month")
  expect_exports()

  app$set_inputs(period_selection = "Historical")
  expect_exports()
})
