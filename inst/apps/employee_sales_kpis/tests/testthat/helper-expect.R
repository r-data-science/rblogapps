library(data.table)

expect_store_orders <- function(app) {
  app$get_value(export = "r_store_orders") |>
    head() |>
    apply(1, as.list) |>
    expect_snapshot_value()
}

expect_employee_summary <- function(app) {
  app$get_value(export = "r_employ_summary") |>
    head() |>
    apply(1, as.list) |>
    expect_snapshot_value()
}

expect_high_low_stats <- function(app) {
  app$get_value(export = "r_high_low_stats") |>
    (function(ll) {
      list(
        list(overall = apply(ll$overall, 1, as.list)),
        list(category = lapply(ll$category, function(x) apply(x, 1, as.list)))
      )
    })() |>
    expect_snapshot_value(style = "json2")
}

expect_sales_per_day <- function(app, id) {
  val <- app$get_value(export = "r_sales_per_day")
  val$data |>
    apply(1, as.list) |>
    expect_snapshot_value()

  p <- val$plot
  expect_doppelganger(p, title = paste0("p", id, "-spd"))
}

expect_sales_per_hour <- function(app, id) {
  val <- app$get_value(export = "r_sales_per_hour")
  list(
    list(impact = val$impact),
    list(n_low = val$n_low),
    list(summ = apply(val$summ, 1, as.list))
  ) |>
    expect_snapshot_value(tolerance = .001)

  # Check plot but avoid warning from ggplot for dropping NA rows
  p <- val$plot
  p$data <- data.table::setDT(p$data)[is.na(labs), labs := ""]
  expect_doppelganger(p, title = paste0("p", id, "-sph"))
}

expect_staff_perf <- function(app, id) {
  p <- app$get_value(export = "r_plot_staff_perf")
  expect_doppelganger(p, title = paste0("p", id, "-esp"))
}
