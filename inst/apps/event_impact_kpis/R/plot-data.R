## labeling function used by the app
f_label <- function(y) {
  switch(
    y,
    "ave_disc_rate" = percent,
    "n_uniq_products" = comma,
    "n_uniq_brands" = comma,
    "n_uniq_customers" = comma,
    "pct_retail_sales" = percent,
    "pct_retail_units" = percent,
    "total_orders" = comma,
    "total_units" = comma,
    "total_sales" = dollar,
    "sales_per_order" = dollar
  )
}


## Internal function used by the plot function below
get_axis_ll <- function(i) {
  switch(
    i,
    month_id = list(
      axis_frmt = NULL,
      axis_labl = "Month"
    ),
    ave_disc_rate = list(
      axis_frmt = percent_format(),
      axis_labl = "Average Discount Rate"
    ),
    n_uniq_products = list(
      axis_frmt = comma_format(),
      axis_labl = "Count Distinct Products Sold"
    ),
    n_uniq_brands = list(
      axis_frmt = comma_format(),
      axis_labl = "Count Distinct Brands Sold"
    ),
    n_uniq_customers = list(
      axis_frmt = comma_format(accuracy = .1, scale = .001, suffix = "K"),
      axis_labl = "Count of Distinct Customers"
    ),
    pct_retail_sales = list(
      axis_frmt = percent_format(),
      axis_labl = "Percent of Retail Sales"
    ),
    pct_retail_units = list(
      axis_frmt = percent_format(),
      axis_labl = "Percent of Retail Units"
    ),
    total_orders = list(
      axis_frmt = comma_format(scale = .001, suffix = "K"),
      axis_labl = "Total Orders"
    ),
    total_units = list(
      axis_frmt = comma_format(scale = .001, suffix = "K"),
      axis_labl = "Total Units"
    ),
    total_sales = list(
      axis_frmt = dollar_format(scale = .001, suffix = "K"),
      axis_labl = "Total Sales"
    ),
    sales_per_order = list(
      axis_frmt = dollar_format(),
      axis_labl = "Sales Per Order"
    )
  )
}


plotVarByStore <- function(dT, y) {
  y_ll <- get_axis_ll(y)

  ## don't plot first and last month in the data because of
  ## likely data ingestion issues
  setkeyv(dT, "store")
  dT2 <- dT[
    dT[, .(max(month_id), min(month_id)), store]
  ][ month_id > V2 & month_id < V1 ]

  ## subset rows to show a sliding window over the months prior
  ## to being an hca customer
  dT3 <- dT2[month_id > -1 * (max(month_id) + 1)][, c("V1", "V2") := NULL][]

  ## For legend labelling
  dT3[, facil := store]

  ## build plot
  p1 <- ggplot(dT3, aes(month_id, .data[[y]], group = facil, color = facil)) +
    geom_line(linetype = 3) +
    geom_point() +
    geom_vline(aes(xintercept = 0, color = facil)) +
    scale_color_gdocs(name = NULL) +
    scale_y_continuous(
      name = y_ll$axis_labl,
      labels = y_ll$axis_frmt
    ) +
    theme(
      axis.title = element_blank(),
      strip.text = element_blank(),
      panel.grid.minor = element_blank(),
      legend.position = "top"
    )

  ## relabel x-axis to show friendly labels
  setkeyv(dT3, "month_id")
  tmp <- dT3[.(as.numeric(na.omit(layer_scales(p1)$x$break_positions()))), .(
    month_id = unique(month_id)
  )]
  tmp[month_id < 0,
      mon_label := paste0(abs(month_id), " Months Before Event")]
  tmp[month_id == 0,
      mon_label := "Event Occurred"]
  tmp[month_id > 0,
      mon_label := paste0(abs(month_id), " Months After Event")]

  p2 <- p1 +
    scale_x_continuous(
      oob = function(x, range) x,
      breaks = tmp$month_id,
      labels = str_wrap(tmp$mon_label, width = 12),
      limits = c(dT3[, min(month_id)], dT3[, -1*min(month_id)])
    ) +
    facet_grid(facil ~ ., scales = "free")
  p2
}


plotVarByOrg <- function(dT, y) {
  y_ll <- get_axis_ll(y)

  ## don't plot first and last month in the data because of likely data
  ## ingestion issues
  dT2 <- dT[month_id > min(month_id) & month_id < max(month_id)]

  ## subset rows to show a sliding window over the months prior to being
  ## an hca customer
  dT3 <- dT2[month_id > -1 * (max(month_id) + 1)]

  ## summarize average across stores to get to org
  dT4 <- dT3[, .(y = mean(get(y)), mon_date = min(mon_date)), .(month_id)] |>
    setnames("y", y) |>
    setkey(month_id)

  ## build plot
  p1 <- ggplot(dT4, aes(month_id, .data[[y]])) +
    geom_line(linetype = 3) +
    geom_point() +
    geom_vline(aes(xintercept = 0)) +
    scale_color_gdocs(name = NULL) +
    scale_y_continuous(
      name = y_ll$axis_labl,
      labels = y_ll$axis_frmt
    ) +
    theme(
      axis.title = element_blank(),
      strip.text = element_blank(),
      panel.grid.minor = element_blank()
    )

  ## relabel x-axis to show friendly labels
  setkeyv(dT4, "month_id")
  tmp <- dT4[
    .(as.numeric(na.omit(layer_scales(p1)$x$break_positions()))),
    .(month_id = unique(month_id))
  ]
  tmp[month_id < 0,
      mon_label := paste0(abs(month_id), " Months Before Event")]
  tmp[month_id == 0,
      mon_label := "Event Occurred"]
  tmp[month_id > 0,
      mon_label := paste0(abs(month_id), " Months After Event")]

  p2 <- p1 +
    scale_x_continuous(
      oob = function(x, range) x,
      breaks = tmp$month_id,
      labels = str_wrap(tmp$mon_label, width = 12),
      limits = c(dT4[, min(month_id)], dT4[, -1*min(month_id)])
    )
  p2
}
