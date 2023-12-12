# Unit Tests For File: {pkg}/R/getBlogData.R
# ---------------------------------------------------------

library(data.table)

test_that("App Utils", {
  getBlogData("employee_sales_kpis") |>
    is.data.table() |>
    expect_true()
})
