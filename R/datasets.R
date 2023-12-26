#' Cannabis Employee Sales Performance
#'
#' Dataset is primary appdata for employee_sales_kpis app included in this
#' package. This data contains a time series of sales transactions for various
#' cannabis retailers and their locations.
#'
#' @format ## `employee_sales_kpis`
#' A data table with 60,502 rows and 14 columns.
#' \describe{
#'   \item{org}{Anonymized Org Name}
#'   \item{store}{Anonymized Retail Location}
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
#' @source <Anonymized Proprietary Data>
"employee_sales_kpis"


#' Sales Performance of Retailer's House Brand
#'
#' Dataset is primary appdata for house_brands_kpis app included in this
#' package. This data contains a series of KPIs calculated across various time
#' periods. These performance metrics describe how well employees at a retail
#' location perform when selling the retailer's house branded products.
#'
#' @format ## `house_brands_kpis`
#' A data table with 53,570 rows and 5 columns.
#' \describe{
#'   \item{store}{Anonymized Retail Location}
#'   \item{employee}{Anonymized Names of retailer employees}
#'   \item{period}{The time period associated with the KPI value}
#'   \item{kpi_name}{The name of the performance KPI metric}
#'   \item{kpi_value}{The calculated value of the performance KPI metric}
#' }
#' @source <Anonymized Proprietary Data>
"house_brands_kpis"


#' Estimated Revenue Impact From Product Stockouts
#'
#' Dataset is primary appdata for app stockout_sales_impact which is included
#' in this package. This data contains a timeseries of product sales statistics
#' including days in which a product was out of stock and not sold. Additionally,
#' dataset includes estimated total sales loss for days in which a stockout occurs.
#'
#' @format ## `stockout_sales_impact`
#' A data table with 34,114 rows and 17 columns.
#' \describe{
#'   \item{org}{Anonymized Retailer Name}
#'   \item{store}{Anonymized Retail Location}
#'   \item{product_sku}{Product Sku}
#'   \item{order_date}{Date of Retail Order Sales}
#'   \item{category}{Product Category}
#'   \item{brand_name}{Product Brand}
#'   \item{tot_sales}{Total Sales over all time}
#'   \item{units_sold}{Total Unit Sales over all time}
#'   \item{has_sales}{Whether a product has sales on given order date}
#'   \item{period_units_sold}{Total units sold on order date}
#'   \item{period_tot_sales}{Total sales on order date}
#'   \item{ave_disc_r}{Average discount rate for product sales on order_date}
#'   \item{ave_ticket}{Average order size when product is included in order on given order_date}
#'   \item{wts}{Weights starting at 0 on day 1, ending at 1 on the last order_date for a given product}
#'   \item{tot_sales_est}{Estimated total sales on order_date assuming no product stockout}
#'   \item{c_sales_est}{Estimated cumulative total sales for days 1 through a given order_date assuming no product stockout}
#'   \item{c_sales_actual}{Actual cumulative total sales for days 1 through a given order_date with stockout events included}
#' }
#' @source <Anonymized Proprietary Data>
"stockout_sales_impact"



#' Event Impact Analysis
#'
#' Dataset is primary appdata for app event_impact_kpis which is included
#' in this package. This data is used to explore the impact across various
#' business success metrics, with a comparison of KPIs before and after some
#' business or operational event.
#'
#' @format ## `event_impact_kpis`
#' A data.table with 1360 rows and 15 columns.
#' \describe{
#'   \item{org}{[factor] Anonymized Retailer Name}
#'   \item{store}{[character] Anonymized Retail Location}
#'   \item{is_post_event}{[logical] Whether an monthly observation (row) occurs after the event}
#'   \item{mon_date}{[POSIXct] month start date}
#'   \item{ave_disc_rate}{[numeric] average discount rate in month}
#'   \item{n_uniq_products}{[integer] number of unique products sold in month}
#'   \item{n_uniq_brands}{[integer] number of unique brands sold in month}
#'   \item{n_uniq_customers}{[integer] number of distinct customers with purchases in month}
#'   \item{pct_retail_sales}{[numeric] percent of total sales dollars that were retail orders (vs. delivery)}
#'   \item{pct_retail_units}{[numeric] percent of total units sold that were retail orders (vs. delivery)}
#'   \item{total_orders}{[integer] total orders in month}
#'   \item{total_units}{[numeric] total units sold in month}
#'   \item{total_sales}{[numeric] total sales dollars generated in month}
#'   \item{sales_per_order}{[numeric] average ticket size in month}
#'   \item{month_id}{[integer] an index identifying the month (negative means prior to event, positive means post event)}
#' }
#' @source <Anonymized Proprietary Data
"event_impact_kpis"



#' Compare Brand Training Impact
#'
#' Dataset is primary appdata for app compare_brand_impact which is included
#' in this package. This data is used to evaluate the impact that employee
#' brand training has on retail sales.
#'
#' @format ## `compare_brand_impact`
#' A data.table with 344,933 rows and 8 columns.
#' \describe{
#'   \item{org}{[factor] Anonymized Retailer Name}
#'   \item{order_id}{[character] Anonymized Order Id}
#'   \item{order_subtot}{Subtotal of all items sold in an order}
#'   \item{order_date}{Date of the order}
#'   \item{item_discount}{discount in dollars applied to the order line item}
#'   \item{item_subtotal}{Subtotal for an order line item}
#'   \item{brand_name}{brand name for order line item sold}
#'   \item{category}{product category for the order line item sold}
#' }
#' @source <Anonymized Proprietary Data
"compare_brand_impact"
