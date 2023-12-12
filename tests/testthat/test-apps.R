# File: tests/testthat/test-inst-apps.R
library(shinytest2)

test_that("Testing all package apps", {
  skip_on_cran() # Don't run these tests on the CRAN build servers
  skip_on_ci() # Skip this on CI since we have a dedicated workflow for testing apps
  fs::path_package("rblogapps", "apps") |>
    fs::dir_ls(type = "directory") |>
    lapply(test_app)
})



