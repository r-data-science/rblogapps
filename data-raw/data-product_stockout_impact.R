## code to prepare `stockout_sales_impact` dataset goes here
library(data.table)
library(stringr)
library(rpgconn)
library(httr2)
library(fs)
library(lubridate)
library(jsonlite)
library(DBI)

sample_us_cities <- function(n = 1, us_state = "California") {
  data_url <- "https://github.com/r-data-science/corpora/blob/master/data"

  # Get cities dataset from gh
  DT <- fs::path(data_url, "geography/us_cities.json") |>
    httr2::request() |>
    httr2::req_perform() |>
    httr2::resp_body_string() |>
    jsonlite::fromJSON() |>
    (function(x) x$payload$blob$rawLines)() |>
    stringr::str_flatten() |>
    jsonlite::fromJSON() |>
    (function(x) data.table::setDT(x$cities)[])() |>
    data.table::setkeyv("state")

  # Get index of all states to join in abbreviations
  index <- data.table::data.table(state = state.name, abb = state.abb) |>
    data.table::setkeyv("state")

  # Filter index if user provided states
  if (!is.null(us_state))
    index <- index[.(match.arg(us_state, state.name, several.ok = TRUE))]

  # Join on cities data, create location name, and sample
  DT[index, paste0(city,  ", ", abb)] |>
    sample(n, replace = FALSE)
}


getAppData <- function() {
  cn <- rpgconn::dbc(db = "appdata")
  on.exit(rpgconn::dbd(cn))
  qry <- "SELECT * FROM vindex_product_velocity_daily"
  tmp <- setDT(dbGetQuery(cn, qry))
  select_oids <- tmp[, .N, org_uuid][, sample(org_uuid, 10, replace = FALSE)]
  DT <- setkey(tmp, org_uuid)[select_oids]
  na_url <- "https://www.staticwhich.co.uk/static/images/products/no-image/no-image-available.png"
  DT[, image_url := na_url]
  setkey(DT, org, store, category3, brand_name)
  return(DT[])
}

dbGetVtDaily <- function (org_uuid, store_uuid) {
  print(org_uuid)
  cn <- rpgconn::dbc(db = "appdata")
  on.exit(dbd(cn))
  qry <- stringr::str_glue(
    "SELECT *
      FROM product_velocity_daily
      WHERE org_uuid = '{org_uuid}'
      AND store_uuid = '{store_uuid}'"
  )
  keyCols <- c("product_sku", "order_date")
  setDT(dbGetQuery(cn, qry), key = keyCols)[]
}


tmp <- getAppData()
org_ids <- tmp[, .N, org_uuid][N > 100 & N < 1000, org_uuid]
summDT <- tmp[
  org_uuid %in% org_ids &
    !category3 %in% c("ACCESSORIES", "OTHER")
]

index <- summDT[, .N, keyby = .(org_uuid, store_uuid)][, !"N"]

vtDailyDT <- rbindlist(lapply(apply(index, 1, as.list), function(ll) {
  do.call(dbGetVtDaily, ll)
}))
vtDailyDT[, c("category3", "brand_name", "created_utc") := NULL]

setcolorder(
  vtDailyDT,
  c("org_uuid", "store_uuid", "product_sku", "order_date", "has_sales")
)

setnames(
  vtDailyDT,
  c("units_sold", "tot_sales"),
  c("period_units_sold", "period_tot_sales")
)


keyCols <- c("org_uuid", "store_uuid", "product_sku")
setkeyv(vtDailyDT, keyCols)
setkeyv(summDT, keyCols)

stockout_sales_impact <- summDT[vtDailyDT]



# anonymize ---------------------------------------------------------------



stockout_sales_impact[, org := paste("Org", .GRP), org_uuid]
index <- stockout_sales_impact[, .N, .(org_uuid, store_uuid)][, !"N"]
index[, store := sample_us_cities(.N), org_uuid]
keyCols <- c("org_uuid", "store_uuid")
setkeyv(stockout_sales_impact, keyCols)
setkeyv(index, keyCols)
stockout_sales_impact[index, store := store]

stockout_sales_impact[, org_uuid := NULL]
stockout_sales_impact[, store_uuid := NULL]

setcolorder(stockout_sales_impact, c("org", "store", "product_sku",  "order_date"))
stockout_sales_impact[, image_url := NULL]


stockout_sales_impact <- stockout_sales_impact[
  org %in% c("Org 1", "Org 4", "Org 8")
]

setnames(stockout_sales_impact, "category3", "category")

stockout_sales_impact <- stockout_sales_impact[!is.na(category)]

levs <- stockout_sales_impact[, .N, category][, category]
labs <- c("Flower",
          "Edibles",
          "Vapes & Carts",
          "Prerolls",
          "Concentrates",
          "Tinctures",
          "Topicals",
          "Infused Drinks")
stockout_sales_impact[, category := factor(
  category,
  levels = levs,
  labels = labs
)]

stockout_sales_impact[, org :=
                          factor(org, levels = c("Org 1", "Org 4", "Org 8"))]


setkey(stockout_sales_impact, org, store, order_date, category, brand_name)
usethis::use_data(stockout_sales_impact, overwrite = TRUE)




