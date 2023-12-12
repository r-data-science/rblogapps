#' Cannabis Employee Sales Performance
#'
#' Dataset is primary appdata for employee_sales_kpis app included in this
#' package. This data contains a time series of sales transactions for various
#' cannabis retailers and their locations.
#'
#' @format ## `employee_sales_kpis`
#' A data table with 60,502 rows and 14 columns.
#' \describe{
#'   \item{org}{Anonomized Org Name}
#'   \item{store}{Anonomized Retail Location}
#'   \item{order_utc}{Timestamp associated with an order}
#'   \item{employee}{Name of employee that facilitated order}
#'   \item{order_id}{Random ID associated with an order}
#'   \item{category}{Product category associated with items purchased in an order}
#'   \item{units_sold}{Count of units of a category sold in an order}
#'   \item{order_qty}{Count of total units (of any category) sold in an order}
#'   \item{sub_total}{Subtotal (After Discounts) of category items sold in an order}
#'   \item{list_total}{Total (Before Discounts) of category items sold in an order}
#'   \item{disc_total}{Percentage Discount applied to category items sold in an order}
#'   \item{order_subtotal}{Subtotal of all items (all categories) sold in an order}
#'   \item{order_pct_disc}{Percentage Discount applied to all items in an order}
#'   \item{ticket_share}{Share of total order dollars that category items make up}
#' }
#' @source <Anonomized Proprietary Data>
"employee_sales_kpis"
