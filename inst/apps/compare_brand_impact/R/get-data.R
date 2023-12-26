
## Get orders data for orgs without and with training over a time interval
getAppData <- function(yes, no, start_date, stop_date) {
  DT <- getBlogData("compare_brand_impact")
  appDT <- rbindlist(list(
    DT[org %in% yes][, has_brand_training := TRUE][],
    DT[org %in% no][, has_brand_training := FALSE][]
  ))[ order_date > start_date & order_date < stop_date ] |>
    setkey(brand_name, category)
  appDT[]
}

## Get choices for the UI
getOrgChoices <- function() {
  getBlogData("compare_brand_impact")[, .N, keyby = org][, as.character(org)]
}


## Subset by brand and category, then calculate stats
getStats <- function(DT, brand, cat) {
  if (!all(c("brand_name", "category") %in% key(DT)))
    stop("Keys missing - 'brand_name' and 'category' not set for argument DT")

  var_cols <- c("pct_disc", "order_subtot", "pct_order", "amt_order")

  stats_dt <- DT[.(brand, cat), .(
    pct_disc = -1 * sum(item_discount) / sum(item_subtotal),
    pct_order = sum(item_subtotal) / order_subtot,
    amt_order = sum(item_subtotal)
  ), c("order_id", "order_subtot", "has_brand_training")][
    !(pct_disc > 1 | pct_disc < 0),
    lapply(.SD, mean, trim = .01),
    keyby = has_brand_training,
    .SDcols = var_cols]

  if (nrow(stats_dt) < 2)
    return(NULL)

  OUT <- rbindlist(lapply(var_cols, function(x) {
    descr <- switch(
      x,
      pct_disc = "Average Discount for Brand in Selected Category",
      order_subtot = "Average Ticket Size for Orders that Include Brand",
      pct_order = "Average Share of Dollars Per Order Attributed to Brand",
      amt_order = "Average Dollar Amount Per Order Attributed to Brand"
    )
    sn <- stats_dt[.(FALSE), get(x)]
    sy <- stats_dt[.(TRUE), get(x)]
    data.table(
      var = x,
      stat_desc = descr,
      no_training = sn,
      with_training = sy,
      pct_delta = (sy - sn) / sn
    )
  })) |>
    setkeyv("var")
  return(OUT[])
}



# ## Testing
# start_date <- "2022-12-15"
# stop_date <- "2023-09-15"
# yes <- sample(paste0("Org ", 1:5), 3)
# no <- sample(paste0("Org ", 6:10), 3)
