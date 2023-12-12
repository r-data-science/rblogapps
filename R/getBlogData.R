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
#'
getBlogData <- function(name = "employee_sales_kpis") {
  as.data.table(get(is_app_valid(name)))
}
