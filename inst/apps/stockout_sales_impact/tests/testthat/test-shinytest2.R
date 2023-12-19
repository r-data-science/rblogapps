library(shinytest2)
library(vdiffr)


test_that("{shinytest2} recording: stockout_sales_impact", {
  app <- AppDriver$new( load_timeout = 35000 )
  app$wait_for_idle(1000)

  app$expect_values(input = TRUE)

  app$set_inputs(`my-filters-store` = "Florence-Graham, CA", wait_ = FALSE)
  app$wait_for_idle()

  app$set_inputs(`my-filters-category` = "Edibles", wait_ = FALSE)
  app$wait_for_idle()

  app$expect_values(input = TRUE)

  app$set_inputs(args_table_rows_selected = 2, allow_no_input_binding_ = TRUE, wait_ = FALSE)
  app$wait_for_idle()

  app$click("eval")

  app$expect_values(output = "args_table")

  p <- app$get_value(export = "plot_impact")

  expect_doppelganger(p, title = "Impact Plot 1")

  app$set_inputs(tabset1 = "2", wait_ = FALSE)
  app$wait_for_idle()

  app$expect_values(output = "plot_data")

  app$click("my-filters-reset_all")

  app$get_value(input = "my-filters-brand_name") |>
    expect_null()
  app$get_value(input = "my-filters-category") |>
    expect_null()
  app$get_value(input = "my-filters-product_sku") |>
    expect_null()
  app$get_value(input = "my-filters-store") |>
    expect_null()

  app$set_inputs(org = "Org 4", wait_ = FALSE)
  app$wait_for_idle()

  app$expect_values(output = "args_table")

  expect_identical(
    stringr::str_trim(app$get_text("button")[2]),
    "Select Product From Table Above"
  )

  app$set_inputs(args_table_rows_selected = 3, allow_no_input_binding_ = TRUE, wait_ = FALSE)
  app$wait_for_idle()

  expect_identical(
    stringr::str_trim(app$get_text("button")[2]),
    "Estimate Stockout Revenue Loss"
  )
  app$click("eval")

  p <- app$get_value(export = "plot_impact")

  expect_doppelganger(p, title = "Impact Plot 2")

  app$expect_values(output = "plot_data")

  app$stop()
})
