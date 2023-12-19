# Unit Tests For File: {pkg}/R/getBlogData.R
# ---------------------------------------------------------

library(data.table)


# Validation Checks -------------------------------------------------------



test_that("Ensure there is a dataset per app in package", {
  expect_equal(length(listBlogApps()), length(listBlogData()))
})

test_that("Ensure dataset names match app names", {
  expect_identical(listBlogApps(), listBlogData())
})


# Dataset Checks ----------------------------------------------------------

expect_data <- function(DT) {
  test_iter <<- test_iter + 1
  expect_true(is.data.table(DT))                           # is data.table
  expect_true(all(sapply(DT, function(v) !any(is.na(v))))) # no na values
  expect_snapshot_value(names(DT), style = "json2")        # column names
}

#  Count the number of tests ran  for each dataset
#  and ensure at the end that there is a test for each
#  dataset exported in package
test_iter <- 0

test_that("Testing dataset - employee_sales_kpis", {
  expect_data(getBlogData("employee_sales_kpis"))
})

test_that("Testing Dataset - house_brands_kpis", {
  expect_data(getBlogData("house_brands_kpis"))
})

test_that("Testing Dataset - stockout_sales_impact", {
  expect_data(getBlogData("stockout_sales_impact"))
})



# Confirm All Datasets Have Been Tested -----------------------------------


# When adding new tests to this file, ensure this is the last test run
test_that("Last check to ensure all data have unit tests", {
  expect_equal(length(listBlogData()), test_iter)
})

