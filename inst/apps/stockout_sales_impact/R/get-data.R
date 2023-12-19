#' Get Primary App Dataset
#'
#' @param org_name anonymized org name
#'
#' @importFrom rblogapps getBlogData
#'
getAppIndex <- function(org_name) {
  rblogapps::getBlogData("stockout_sales_impact")[, unique(.SD), .SDcols = c(
    "org",
    "store",
    "product_sku",
    "category",
    "brand_name",
    "tot_sales",
    "units_sold"
  )][org == org_name, .(
    store,
    category,
    brand_name,
    product_sku
  )]
}

#' Get App's Plot Dataset
#'
#' @param org_name anonymized org name
#' @param store_location anonymized store identifier
#' @param sku product sku
#'
#' @importFrom rblogapps getBlogData
#'
getVtDaily <- function(org_name, store_location, sku) {
  rblogapps::getBlogData("stockout_sales_impact")[
    org == org_name &
      store == store_location &
      product_sku == sku
  ][, c("units_sold", "tot_sales") := NULL][]
}


#' Get Formatted DataTable Containing Plot Dataset For UI
#'
#' @param p plot object to extract dataset from
#'
#' @importFrom DT datatable
#'
getPlotDT <- function(p) {
  tmp <- p$data[, .(
    period_units_sold,
    ave_disc_r,
    ave_ticket,
    c_sales_actual,
    c_sales_est
  )]
  rownames(tmp) <- p$data[, order_date]

  cols <- list(
    "Date",
    "Units Sold",
    "Discount",
    "Ave Ticket",
    "Actual",
    "Expected"
  )
  DT::datatable(
    data = tmp,
    style = "bootstrap",
    colnames = cols,
    rownames = TRUE,
    selection = "single",
    fillContainer = TRUE,
    options = list(
      dom = "tp",
      lengthChange = TRUE,
      lengthMenu = c(10, 20, 50),
      pageLength = 10,
      initComplete = JS(
        "function(settings, json) {",
        "$(this.api().table().header()).css({'background-color': '#fff', 'color': '#000'});",
        "}")
    )
  )
}

#' Get Formatted DataTable Containing App Dataset For UI
#'
#' @param data appdata containing selection criteria for user filtering
#'
#' @importFrom DT datatable JS
#'
getArgsDT <- function(data) {
  DT::datatable(
    data = data,
    style = "bootstrap",
    rownames = FALSE,
    selection = "single",
    fillContainer = TRUE,
    colnames = c("Store", "Category", "Brand", "Sku"),
    options = list(
      dom = "tp",
      lengthChange = TRUE,
      lengthMenu = c(10, 20, 50),
      pageLength = 10,
      initComplete = JS(
        "function(settings, json) {",
        "$(this.api().table().header()).css({'background-color': '#fff', 'color': '#000'});",
        "}"),
      columnDefs = list(list(
        targets = c(1,2,3),
        render = DT::JS(
          "function(data, type, row, meta) {",
          "return type === 'display' && data.length > 10 ?",
          "'<span title=\"' + data + '\">' + data.substr(0, 10) + '...</span>' : data;",
          "}")
      ))
    ))
}
