library(data.table)
library(stringr)
library(lubridate)
library(hcadatatools)
library(DBI)
library(rdstools)
library(rpgconn)
library(randomNames)

# Source functions -------------------------------------------------------------


## Function to get population data for verano
##
getRetailerPop <- function(oid) {
  cn <- rpgconn::dbc(db = "integrated")
  on.exit(rpgconn::dbd(cn))
  qry <- stringr::str_glue("
    SELECT brand_name,
      order_line_subtotal,
      order_time_utc,
      sold_by,
      order_facility
    FROM population
    WHERE org_uuid = '{oid}'
  ")

  res <- dbSendQuery(cn, qry)
  on.exit(dbClearResult(res), add = TRUE, after = FALSE)
  DT <- setDT(dbFetch(res, 0))[]
  iter <- 0
  rdstools::log_inf("Getting Retailer Population Data")
  cat("\n")
  while (!dbHasCompleted(res)) {
    cat(iter <- iter + 1, "\n")
    DT <- rbindlist(list(DT, setDT(dbFetch(res, 10^6))[]))
  }
  rdstools::log_suc("Population Query Complete")
  return(DT)
}


## Function to perform the following:
##  1. summarize orders with and without house brand products
##  2. Calculate various stats by store, budtender, and month
##
buildAppdata <- function(DT, house_brand = NULL, house_pat = NULL) {

  if (is.null(house_brand))
    stop("house_brand arg is null", call. = FALSE)

  # if a brand detection pattern to group multiple brands into a single house
  # brand is not provided, use the house brand name as the pattern
  if (is.null(house_pat))
    house_pat <- house_brand

  ###--------

  DT[, sold_by := str_to_upper(sold_by)]

  rdstools::log_inf("Standardizing Retailer Brands")

  DT[, brand_name := str_trim(str_to_upper(brand_name), side = "both")]
  DT[brand_name == "" | brand_name == "NO_VALUE" | is.na(brand_name),
     brand_name := "OTHER"]
  DT[ str_detect(brand_name, house_pat),
      brand_name := house_brand]


  ###--------
  rdstools::log_inf("Sales Summary by Store/Employee/Timestamp")
  cat("\n")


  orderSumm <- DT[, {
    hcadatatools::print_prog(2000000)
    list(
      has_house = any(brand_name == house_brand),
      order_total = sum(order_line_subtotal),
      house_total = sum(c(0, order_line_subtotal[brand_name == house_brand]))
    )
  }, .(order_facility, sold_by, order_time_utc)]
  cat("Progress: Complete\n")

  ###--------
  rdstools::log_inf("Orders Summary by Store/Employee/Month")
  cat("\n")

  houseSumm <- orderSumm[, {
    hcadatatools::print_prog(5000)
    n_odays <- length(unique(as_date(order_time_utc)))
    list(
      total_orders = .N,
      total_sales = sum(order_total),
      total_house_sales = sum(house_total),
      order_days = n_odays,
      orders_per_day = .N / n_odays,
      share_orders_house = sum(has_house) / .N,
      ave_order_size_no_house = mean(order_total[has_house == FALSE]),
      ave_order_size_house = mean(order_total[has_house == TRUE]),
      ave_house_dollars_per_order = mean(house_total)
    )
  }, keyby = .(
    order_facility,
    sold_by,
    month_date = floor_date(as_date(order_time_utc), unit = "months")
  )]

  cat("Progress: Complete\n")

  ###--------
  rdstools::log_inf("Cacluate House Premium Statistic")
  houseSumm[, house_order_premium :=  (
    ave_order_size_house - ave_order_size_no_house
  ) / ave_order_size_no_house ]

  ###--------
  rdstools::log_inf("Group Orders Data Into Time Periods")

  # the data is not current, so use the latest date to simulate
  # month to date period
  curr <- floor_date(
    DT[, as_date(max(order_time_utc))],
    unit = "months"
  )

  # curr <- floor_date(today(), "months")
  houseSumm[month_date == curr, period := "Month-To-Date"]
  houseSumm[month_date == curr - months(1), period := "Last Month"]
  houseSumm[month_date < curr - months(1),  period := "Historical"]

  levs <- c("Month-To-Date", "Last Month", "Historical")
  houseSumm[, period := factor(period, levels = levs)]

  ###--------
  rdstools::log_inf("Cacluate KPIs by Store/Employee/Period")

  appdata <- houseSumm[!is.na(sold_by), .(
    order_days = round(mean(order_days), 0),
    total_sales = round(mean(total_sales), 1),
    dollars_per_day = round(mean(total_sales) / mean(order_days), 1),
    orders_per_day = round(mean(orders_per_day), 0),
    ave_order_size_no_house = round(mean(ave_order_size_no_house), 2),
    ave_order_size_house = round(mean(ave_order_size_house), 2),
    ave_house_dollars_per_order = round(mean(ave_house_dollars_per_order), 2),
    house_order_premium = round(mean(house_order_premium), 3),
    pct_orders_house = round(mean(share_orders_house), 3),
    pct_sales_house = round(mean(total_house_sales) / mean(total_sales), 3)
  ), .(order_facility, sold_by, period)] |>
    melt(id.vars = c("order_facility", "sold_by", "period"))


  # Some values may be NA, for example, if employee sold no
  # house products, pct_orders_house will be NA, but should be 0
  appdata[is.na(value), value := 0]

  ###--------
  rdstools::log_inf("Anonomizing Retailer Locations")

  store_index <- appdata[, .N, order_facility][, !"N"]
  store_index[, anon_store := sample_us_cities(.N, "California")]

  setkeyv(store_index, "order_facility")
  setkeyv(appdata, "order_facility")

  appdata[store_index, order_facility := anon_store]

  ###--------
  rdstools::log_inf("Anonomizing Retailer Employees")

  staff_index <- appdata[, .N, sold_by][, !"N"]
  staff_index[, anon_names := gen_random_name(.N)]

  setkeyv(staff_index, "sold_by")
  setkeyv(appdata, "sold_by")

  appdata[staff_index, sold_by := anon_names]

  ## Clean up column names
  setnames(
    appdata,
    c("order_facility", "sold_by", "variable", "value"),
    c("store", "employee", "kpi_name", "kpi_value")
  )

  ###--------
  rdstools::log_suc("Appdata Complete")
  return(appdata[])
}


# Run pipeline and build appdata -----------------------------------------------

pop <- getRetailerPop("a6cefdc6-0561-48ee-88cf-7e1e47420e41")

DT <- pop[
  order_line_subtotal > 5 &
    !is.null(sold_by) &
    !is.na(sold_by) &
    !is.na(order_time_utc)
]

house_pat <- "SAVVY|BITS|ENCORE|VERANO|ON THE ROCKS|HOLY UNION|AVEXIA|MUV"
house_brand <- "VERANO"

house_brands_kpis <- buildAppdata(DT, house_brand, house_pat)

## TODO: For some reason, a few observations for house_order_premium
##       are negative values. Look into this later, but zero out the
##       invalid metric values for now.
house_brands_kpis[kpi_value < 0, kpi_value := 0]

# save data to package ----------------------------------------------------


usethis::use_data(house_brands_kpis, overwrite = TRUE)
