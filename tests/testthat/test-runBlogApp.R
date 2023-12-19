# Unit Tests For File: {pkg}/R/runBlogApp.R
# ---------------------------------------------------------

test_that("Test Run App", {
  runBlogApp("fdksjf") |>
    expect_error()
  runBlogApp("employee_sales_kpis") |>
    expect_s3_class("shiny.appobj")
  runBlogApp("house_brands_kpis") |>
    expect_s3_class("shiny.appobj")
  runBlogApp("stockout_sales_impact") |>
    expect_s3_class("shiny.appobj")
})
