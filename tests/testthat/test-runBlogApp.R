# Unit Tests For File: {pkg}/R/runBlogApp.R
# ---------------------------------------------------------

test_that("Test Run App", {
  runBlogApp("fdksjf") |>
    expect_error()
  runBlogApp("employee_sales_kpis") |>
    expect_s3_class("shiny.appobj")
})
