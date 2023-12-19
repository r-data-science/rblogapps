library(data.table)
library(stringr)
library(lubridate)
library(DBI)
library(rdsconfig)
library(rpgconn)

options(scipen = 1000)

# Script Functions ----------------------------------------------------------------------------

dbGetOrgPop2 <- function(oid) {
  fetch <- function(cn, qry) {
    res <- DBI::dbSendQuery(cn, qry)
    on.exit(DBI::dbClearResult(res))
    h <- as.data.table(DBI::dbFetch(res, 1))
    iter <- 0
    while (!DBI::dbHasCompleted(res)) {
      cat("Query iteration:", iter <- iter + 1, "\n")
      h <- rbindlist(list(h, as.data.table(DBI::dbFetch(res, 10^6))))
    }
    return(h)
  }
  cn <- rpgconn::dbc(db = "integrated")
  on.exit(rpgconn::dbd(cn))
  qry <- stringr::str_glue("SELECT * FROM population2 WHERE org_uuid = '{oid}'")
  DT <- fetch(cn, qry)
  setkey(DT, order_facility, order_time_utc)
  return(DT[])
}

buildAppData <- function(oid, event_date) {
  POP <- dbGetOrgPop2(oid)

  POP[, is_hca_customer := order_time_utc > event_date]

  cats <- c(
    "FLOWER", "VAPES", "EXTRACTS", "PREROLLS", "EDIBLES", "DRINKS",
    "TOPICALS", "TINCTURES", "TABLETS_CAPSULES"
  )

  ## Keep only categories with at least 100 sales
  keepCats <- POP[cats, on = "category3"][, .N, category3][N > 100, category3]

  CAT <- POP[
    !is.null(order_time_utc) & item_subtotal < 1000 & item_subtotal > 5
  ][keepCats, {
    st <- sum(item_subtotal)
    to <- length(unique(order_time_utc))
    tu <- sum(product_qty)
    list(
      ave_disc_rate = -1 * sum(item_discount) / sum(item_list_price),
      n_uniq_products = length(unique(product_name)),
      n_uniq_brands = length(unique(brand_name)),
      n_uniq_customers = length(unique(phone)),
      pct_retail_sales = sum(item_subtotal[order_type == "RETAIL"]) / st,
      pct_retail_units = sum(product_qty[order_type == "RETAIL"]) / tu,
      total_orders = to,
      total_units = tu,
      total_sales = st,
      sales_per_order = st / to
    )
  },
  keyby = .(
    org_uuid,
    order_facility,
    is_hca_customer,
    mon_date = lubridate::floor_date(order_time_utc, "month")
  ),
  on = .(category3)
  ][, month_id := rowid(org_uuid, order_facility)][]

  ## Add org shortname to the table for presentation
  DT <- setkeyv(orgIndex()[, .(short_name), key = org_uuid][CAT], "short_name")

  ## align month_id so month 0 is when each org/store started with HCA
  keyCols <- c("short_name", "order_facility")
  setkeyv(DT, keyCols)

  DT[
    DT[, month_id[which(is_hca_customer)[1]] + 2, keyby = keyCols],
    month_id := month_id - V1
  ]

  setkeyv(DT, "short_name")
  return(DT[])
}



# Run Script ----------------------------------------------------------------------------------


orgList <- list(
  "Org 1"  = list(oid = "9244cc3c-5ac1-47aa-b0b0-d6a4423b0547",
                  since = "2022-11-01"),
  "Org 2"  = list(oid = "f38cd5d0-f1e2-475c-ac14-d70d1595abb4",
                  since = "2022-09-01"),
  "Org 3"  = list(oid = "d0bd6c5d-19e6-4fa6-99ad-860681c92c63",
                  since = "2022-09-01"),
  "Org 4"  = list(oid = "3f6043b2-b7f7-4337-a866-f1d823d38fa9",
                  since = "2022-12-01"),
  "Org 5"  = list(oid = "a5c9adc3-b042-4aa0-bdae-56e4a5417092",
                  since = "2022-07-01"),
  "Org 6"  = list(oid = "184adb7c-bcb7-4e6f-89a6-6de9709ade7f",
                  since = "2022-10-01"),
  "Org 7"  = list(oid = "d3dde012-73b9-483b-814a-3971867e5a0e",
                  since = "2022-04-01"),
  "Org 8"  = list(oid = "0ec7399e-395c-4b17-b287-5abd20e957ee",
                  since = "2020-02-01"),
  "Org 9"  = list(oid = "de65e6a2-2bec-4608-8d9f-74f4a2015851",
                  since = "2022-01-01"),
  "Org 10" = list(oid = "b0214a42-292b-48e7-8a04-4a0d57d23ba7",
                  since = "2023-01-01"),
  "Org 11" = list(oid = "579c39f7-fe97-4803-ab70-6fe45dfe0e77",
                  since = "2021-06-01"),
  "Org 12" = list(oid = "b6c6ad09-62dc-43a5-9f88-c3c6f5a53eda",
                  since = "2021-10-01"),
  "Org 13" = list(oid = "04cf5be8-5855-44ef-a40e-98145517dfd8",
                  since = "2023-02-01"),
  "Org 14" = list(oid = "468f6d46-f932-49d7-a0b2-45be9d0be774",
                  since = "2022-02-01")
)

event_impact_kpis <- rbindlist(lapply(seq_along(orgList), function(i) {
  print(i)
  DT <- buildAppData(orgList[[i]]$oid, orgList[[i]]$since)
}))


# anonymize data ----------------------------------------------------------

event_impact_kpis[, org_uuid := NULL]
setnames(event_impact_kpis, "short_name", "org")
setnames(event_impact_kpis, "order_facility", "store")
setnames(event_impact_kpis, "is_hca_customer", "is_post_event")

setkey(event_impact_kpis, org, store, mon_date)

event_impact_kpis[, org := paste("Org", .GRP), org]

tot_orgs <- event_impact_kpis[, .N, org][, .N]
levs <- paste("Org", 1:tot_orgs)
event_impact_kpis[, org := factor(org, levels = levs)]


tmp <- event_impact_kpis[, .N, .(org, store)][, !"N"]
tmp[, anon_store := sample_us_cities(.N), org]

keyCols <- c("org", "store")
setkeyv(tmp, keyCols)
setkeyv(event_impact_kpis, keyCols)

event_impact_kpis[tmp, store := anon_store]

setkey(event_impact_kpis, org, store, mon_date)

usethis::use_data(event_impact_kpis, overwrite = TRUE)



# Get Org's Usage Trends -------------------------------------------------------


# library(DBI)
# library(data.table)
# library(hcaconfig)
# library(ggplot2)
#
# cn <- hcaconfig::dbc("prod2", "appdata")
#
# mscDT <- setDT(dbGetQuery(
#   cn,
#   "SELECT first_text as campaign_utc,
#     customers,
#     texts,
#     pct_delivered,
#     x24hr_roi
#   FROM mstudio_sms_campaigns
#   WHERE org = 'medithrive';"
# ), key = "campaign_utc")
#
# pdata <- mscDT[, .(
#   campaigns = .N,
#   customers = sum(customers),
#   texts = sum(texts),
#   ave_delivery = mean(pct_delivered),
#   total_roi = sum(x24hr_roi, na.rm = TRUE)
# ), keyby = .(
#   date = floor_date(as_date(campaign_utc), "month")
# )][-(.N-1):-.N]
#
#
# ggplot(pdata) +
#   geom_point(aes(date, campaigns)) +
#   geom_smooth(aes(date, campaigns), method = "lm", se = FALSE) +
#   theme(axis.title.x = element_blank()) +
#   ggtitle("Total Campaigns By Month", "Medithrive")
