# Unit Tests For File: {pkg}/R/utilities.R
# ---------------------------------------------------------

test_that("Package Utilities", {

  expect_error(is_app_valid("fkasdjfs"))

  listBlogApps() |>
    expect_no_error()

  listBlogData() |>
    expect_no_error()

  app_name <- "employee_sales_kpis"
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


test_that("Checking App Descriptions", {
  for (app in listBlogApps()) {
    get_app_dir(app) |>
      fs::path("DESCRIPTION") |>
      fs::file_exists() |>
      expect_true()
  }
})


test_that("Testing Package Dependency Declarations", {
  pkg_deps <- list_pkg_deps() |>
    expect_no_error()

  for (app in listBlogApps()) {
    print(paste0("Testing dependendies for: ", app))
    expect_in(list_app_deps(app), pkg_deps)
  }

})
