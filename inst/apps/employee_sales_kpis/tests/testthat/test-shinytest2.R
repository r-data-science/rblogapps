library(shinytest2)
library(vdiffr)
library(withr)

test_that("{shinytest2} recording: employee_sales_kpis", {
  app <- AppDriver$new()
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

  app$set_inputs(category_selection = "PREROLLS")
  expect_all_exports(app, 2)

  app$set_inputs(bdr_selection = "Gabrielle K")
  expect_all_exports(app, 3)

  app$set_inputs(facility_selection = "Highland, CA")
  expect_all_exports(app, 4)

  app$set_inputs(org_selection = "Org 134")
  app$set_inputs(facility_selection = "Turlock, CA")
  app$set_inputs(category_selection = "VAPES")
  expect_all_exports(app, 5)

  app$set_inputs(bdr_selection = "Devon H")
  expect_all_exports(app, 6)
})
