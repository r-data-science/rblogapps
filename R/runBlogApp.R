#' Launch Package Apps
#'
#' @param name Name of app included in package. Lookup with \code{listBlogApps()}
#'
#' @importFrom shiny runApp as.shiny.appobj
#'
#' @export
#'
#' @examples
#' \dontrun{
#' runBlogApp("employee_sales_kpis")
#' runBlogApp("house_brands_kpis")
#' runBlogApp("stockout_sales_impact")
#' runBlogApp("event_impact_kpis")
#' }
#'
runBlogApp <- function(name) {
  for (pkg in list_app_deps(name))
    try(attachNamespace(pkg), silent = TRUE)
  app <- has_app_deps(name) |>
    get_app_dir() |>
    shiny::as.shiny.appobj()
  if (is_testing())
    return(app)
  runApp(app)
}
