test_that("Package Utilities", {
  app_name <- "employee_sales_kpis"

  list_app_names() |>
    expect_no_error()

  list_app_deps(app_name) |>
    expect_snapshot()

  has_app_deps(app_name) |>
    expect_equal(app_name)

  is_app_valid(app_name) |>
    expect_equal(app_name)

  get_app_dir(app_name) |>
    fs::dir_exists() |>
    expect_true()
})
