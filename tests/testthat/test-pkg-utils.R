test_that("Package Utilities", {

  expect_error(is_app_valid("fkasdjfs"))

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

  nf_package_deps("employee_sales_kpis") |>
    expect_null()

  stop_nf_depends("mypackage") |>
    expect_error("\nDependencies missing: mypackage")
})


test_that("Testing dev/test utils (On CI)", {
  skip_if(is_ci(), "On CI")
  expect_true(is_testing())
  expect_false(is_ci())
})

test_that("Testing dev/test utils (No CI)", {
  skip_if_not(is_ci(), "Not on CI")
  expect_true(is_testing())
  expect_true(is_ci())
})
