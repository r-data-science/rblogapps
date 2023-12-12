# File: tests/testthat/test-inst-apps.R
library(shinytest2)

test_that("Testing all package apps", {
  skip_on_cran() # Don't run these tests on the CRAN build servers

  fs::path_package("rblogapps", "apps") |>
    fs::dir_ls(type = "directory") |>
    lapply(test_app)
})



