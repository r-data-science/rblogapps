#' Get App Dataset
#'
#' Function used by all package apps to read the internally
#' stored appdata required by each. The primary app dataset
#' is returned given a valid name corresponding to an app
#' in this package
#'
#' @param name app name
#'
#' @importFrom data.table as.data.table
#'
#' @export
#'
#' @examples
#' getBlogData("employee_sales_kpis")
#' getBlogData("house_brands_kpis")
#' getBlogData("stockout_sales_impact")
#' getBlogData("event_impact_kpis")
#'
getBlogData <- function(name) {
  as.data.table(base::get(is_app_valid(name)))
}
