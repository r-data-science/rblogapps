## code to prepare `employee_sales_kpi` dataset goes here

library(data.table)
library(stringr)
library(lubridate)
library(rdsconfig)
library(DBI)
library(fst)
library(fs)
library(randomNames)
library(httr2)
library(jsonlite)


# Utilities used in building appdata -----------------------------------------

get_pop_data <- function(oid) {
  qry <- stringr::str_glue(
    "SELECT order_facility,
      sold_by,
      order_id,
      order_time_utc,
      category3,
      product_qty,
      order_line_subtotal,
      order_line_list_price,
      order_line_discount
    FROM population
    WHERE org_uuid = '{oid}'
    AND order_time_utc >= '{lubridate::today() - lubridate::days(60)}'")

  cn <- rpgconn::dbc(db = "integrated")
  on.exit(rpgconn::dbd(cn))

  res  <- dbSendQuery(cn, qry)
  on.exit(DBI::dbClearResult(res), add = TRUE, after = FALSE)

  DT <- setDT(dbFetch(res, 0))[]
  print("Starting query...")
  while(!dbHasCompleted(res)) {
    DT <- rbindlist(list(DT, as.data.table(dbFetch(res, 10^6))))
    print(paste0("Total rows queried: ", nrow(DT)))
  }
  return(DT)
}

orgIndexAnon <- function() {
  index <- rdsconfig::orgIndex()
  setkey(index[curr_client & in_pop], org_uuid)[, .(
    short_name = paste0("Org ", .GRP)
  ), keyby = org_uuid]
}


# Function to build app datasets ------------------------------------------


build_appdata <- function(oid, anon = TRUE) {

  ##
  ## Get population and build store orders data
  ##
  salesDT <- get_pop_data(oid)[, sold_by := stringr::str_trim(
    stringr::str_to_upper(sold_by),
    "both"
  )][
    !is.na(sold_by) &
      category3 %in% c(
        "VAPES",
        "FLOWER",
        "PREROLLS",
        "EXTRACTS",
        "EDIBLES",
        "DRINKS",
        "TABLETS_CAPSULES",
        "TINCTURES",
        "TOPICALS"
      ) &
      order_line_list_price > 0 &
      order_line_subtotal > 0 &
      order_line_discount <= 0
  ][, .(
    units_sold = sum(product_qty),
    sub_total  = sum(order_line_subtotal),
    list_total = sum(order_line_list_price),
    disc_total = sum(order_line_discount)
  ), keyby = .(
    order_facility,
    sold_by,
    order_id,
    order_time_utc,
    category3
  )][, c(
    "order_qty",
    "order_subtotal",
    "order_pct_disc"
  ) := .(
    sum(units_sold),
    sum(sub_total),
    -1 * sum(disc_total) / sum(list_total)
  ),
  keyby = .(
    order_facility,
    order_id,
    order_time_utc
  )][, ticket_share := sub_total / order_subtotal]

  if (anon) {
    ##
    ## Anonymize Org, Store and Employee Names
    ##
    anon_org <- orgIndexAnon()[org_uuid == oid, short_name]

    ## Get anon mapping of order_facility
    loc_map <- salesDT[, .N, keyby = order_facility][, !"N"]
    loc_map[, anon := sample_us_cities(.N, "California")]

    ## Get anon mapping of employee names
    emp_map <- salesDT[, .N, keyby = sold_by][, !"N"]
    emp_map[, anon := gen_random_name(.N)]

    ## Anonymize retail store names
    setkeyv(loc_map, "order_facility")
    setkeyv(salesDT, "order_facility")

    salesDT[loc_map, order_facility := anon]

    ## Anonymize store employee names
    setkeyv(emp_map, "sold_by")
    setkeyv(salesDT, "sold_by")

    salesDT[emp_map, sold_by := anon]

    ## Add anon org name
    salesDT[, org := anon_org]
  }

  salesDT[]

}


# Build app dataset -------------------------------------------------------

oids <- orgIndexAnon()[, sample(org_uuid, 4)]
# oids <- c(
#   "d0bd6c5d-19e6-4fa6-99ad-860681c92c63",
#   "e6394ce1-2463-4a4b-b0a4-beb3e84d827d"
# )
employee_sales_kpis <- rbindlist(lapply(oids, build_appdata))


keyCols <- c("org",
             "order_facility",
             "order_time_utc",
             "sold_by",
             "order_id")
setcolorder(employee_sales_kpis, keyCols)
setorderv(employee_sales_kpis, keyCols)

setnames(employee_sales_kpis,
         c("order_time_utc", "sold_by", "order_facility", "category3"),
         c("order_utc", "employee", "store", "category"))

employee_sales_kpis[, order_id := .GRP, .(org, store, order_id)]
# employee_sales_kpis[, .N, .(org, store)]

# Save package data -------------------------------------------------------


usethis::use_data(employee_sales_kpis, overwrite = TRUE)
