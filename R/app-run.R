#' Launch Package Shiny Apps
#'
#' @param name Name of app included in package. Lookup with \code{list_app_names()}
#'
#' @importFrom shiny runApp
#'
#' @examples
#' \dontrun{
#' runBlogApp(name = "employee_sales_kpis")
#' }
#'
runBlogApp <- function(name) {
  app_dir <- has_app_deps(name) |>
    get_app_dir()
  for (pkg in list_app_deps(name))
    try(attachNamespace(pkg), silent = TRUE)
  shiny::runApp(app_dir)
}
