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
#' runBlogApp(name = "employee_sales_kpis")
#' runBlogApp(name = "house_brands_kpis")
#' runBlogApp(name = "stockout_sales_impact")
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
