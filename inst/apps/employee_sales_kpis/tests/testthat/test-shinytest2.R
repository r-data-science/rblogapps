library(shinytest2)
library(vdiffr)
library(withr)

test_that("{shinytest2} recording: employee_sales_kpis", {
  app <- AppDriver$new(expect_values_screenshot_args = FALSE,
                       screenshot_args = FALSE,
                       view = FALSE)
  withr::defer(app$stop())

  expect_all_exports <- function(app, id) {
    expect_store_orders(app)
    expect_employee_summary(app)
    expect_high_low_stats(app)
    expect_sales_per_day(app, id)
    expect_sales_per_hour(app, id)
    expect_staff_perf(app, id)
  }

  app$expect_values(input = TRUE)
  expect_all_exports(app, 1)

  app$set_inputs(org_selection = "Org 48")
  app$set_inputs(category_selection = "PREROLLS")
  app$set_inputs(bdr_selection = "Melanie V")

  expect_all_exports(app, 2)
})
