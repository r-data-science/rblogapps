library(shinytest2)


expect_vals <- function(app) {
  app$get_values(export = "stats")$export$stats |>
    jsonlite::toJSON() |>
    expect_snapshot_value(style = "json2")

  app$get_values(export = "appDT")$export$appDT |>
    head() |>
    jsonlite::toJSON() |>
    expect_snapshot_value(style = "json2")

  app$expect_values(output = TRUE)
}

test_that("{shinytest2} recording: compare_brand_impact", {
  app <- AppDriver$new(name = "app", seed = 121212, view = FALSE,
                       expect_values_screenshot_args = FALSE,
                       screenshot_args = FALSE)

  app$set_inputs(orgs_with_training = "Org 1")
  app$set_inputs(orgs_w_no_training = "Org 2")
  app$click("btn_run")

  expect_vals(app)

  app$set_inputs(brd_selection = "GELATO")
  app$set_inputs(cat_selection = "Prerolls")

  expect_vals(app)

  app$set_inputs(orgs_with_training = c("Org 1", "Org 3"))
  app$set_inputs(orgs_w_no_training = c("Org 2", "Org 8"))
  app$click("btn_run")

  expect_vals(app)

  app$set_inputs(brd_selection = "JEETER")

  expect_equal(
    app$get_text(selector = "div.swal2-html-container"),
    "Brand has no common category products across the selected retailer groups"
  )

  app$set_inputs(brd_selection = "BREEZ")
  app$set_inputs(cat_selection = "Tabs & Caps")

  expect_vals(app)
})
