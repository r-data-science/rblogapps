library(data.table)

test_that("App Utils", {
  getAppData("employee_sales_kpis") |>
    is.data.table() |>
    expect_true()
})
