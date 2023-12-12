# Unit Tests For File: <No corresponding {pkg}/R/*.R File>
#
# Locally Testing of Shiny Apps
# ---------------------------------------------------------

library(shinytest2)

test_that("Testing all package apps", {
  skip_if(is_ci(), "On CI") # Skip CI bc we have a dedicated workflow for apps
  paths <- fs::path_package("rblogapps", "apps") |>
    fs::dir_ls(type = "directory")
  lapply(paths, test_app) |>
    expect_named(as.character(paths))
})



