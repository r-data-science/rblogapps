#' App Utilities
#'
#' Functions used across all package apps
#'
#' @param name app name
#'
#' @name app-utils
NULL

#' @importFrom data.table as.data.table
#'
#' @describeIn app-utils retrieves an apps primary dataset given a valid app name
#' @export
#'
#' @examples
#' getAppData("employee_sales_kpis")
#'
getAppData <- function(name = "employee_sales_kpis") {
  as.data.table(get(is_app_valid(name)))
}
