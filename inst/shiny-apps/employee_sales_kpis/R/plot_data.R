

plotSalesPerDay <- function(store_orders) {

  ## get velocity in units sold per day
  vtPerDay <- store_orders[, .(
    upday = sum(units_sold),
    spday = sum(sub_total),
    ave_order_size = mean(order_subtotal),
    ave_order_spend = mean(sub_total),
    total_orders = length(unique(order_id))
  ), .(
    employee,
    order_date = lubridate::as_date(order_utc),
    category
  )]

  vtSumm <- vtPerDay[, .(
    ave_upday = mean(upday),
    ave_spday = mean(spday),
    ave_order_size = mean(ave_order_size),
    ave_order_spend = mean(ave_order_spend),
    ave_orders_per_day = mean(total_orders),
    tot_days = length(unique(order_date))
  ), .(employee, category)]

  vt_q3 <- vtSumm[, sum(ave_spday), employee][, quantile(V1, .75)]
  vt_q1 <- vtSumm[, sum(ave_spday), employee][, quantile(V1, .25)]

  setkeyv(vtSumm, "employee")
  vtSumm[vtSumm[, sum(ave_spday) > vt_q3, employee][V1 == TRUE, .(employee)],
         perf_group := 1]
  vtSumm[vtSumm[, sum(ave_spday) < vt_q1, employee][V1 == TRUE, .(employee)],
         perf_group := 3]
  vtSumm[is.na(perf_group), perf_group := 2]

  vtSumm[, perf_group := factor(perf_group, 1:3, labels = c("Top", "Middle", "Low"))]

  sby_levs <- vtSumm[, sum(ave_spday), .(employee)][order(-V1), employee]
  vtSumm[, employee := factor(employee, levels = rev(sby_levs))]

  cat_levs <- vtSumm[, mean(ave_spday / sum(ave_spday)), .(category)][order(-V1), category]
  vtSumm[, category := factor(category, levels = rev(cat_levs))]

  p <- ggplot(vtSumm) +
    facet_grid(perf_group ~ ., scales = "free", space = "free", switch = "both") +
    coord_flip() +
    scale_fill_pander() +
    scale_y_continuous(expand = c(0, 0, 0, 0)) +
    theme_bw() +
    theme(
      plot.title = element_text(hjust = 0.5),
      axis.ticks = element_blank(),
      panel.grid = element_blank(),
      panel.border = element_blank(),
      axis.title = element_blank(),
      legend.title = element_blank()
    )

  p1 <- p +
    geom_bar(aes(employee, ave_spday, fill = category), stat = "identity") +
    scale_y_reverse(label = scales::dollar_format(), expand = c(0, .5, 0, 0)) +
    ggtitle("Ave Sales Per Day") +
    theme(
      axis.text.y = element_blank(),
      strip.text.y.left = element_text(angle = 0)
    )

  p2 <- p +
    geom_bar(aes(employee, ave_spday, fill = category),
             stat = "identity",
             position = "fill") +
    scale_y_continuous(labels = scales::percent_format(), expand = c(0, 0, 0, 0)) +
    ggtitle("Share of Dollars") +
    theme(
      axis.text.y = element_text(hjust = .5, vjust = .5),
      strip.text = element_blank()
    )

  figure <- ggarrange(
    p1, p2,
    legend = "top",
    widths = c(1, 1.3),
    align = "h",
    common.legend = TRUE,
    ncol = 2,
    nrow = 1
  )
  list(
    plot = figure,
    data = vtSumm
  )
}

plotSalesPerHour <- function(store_orders, select_cat) {
  store_orders[category != select_cat, category2 := "ALL OTHERS"]
  store_orders[category == select_cat, category2 := select_cat]

  vtPerHour <- store_orders[, sum(sub_total), .(
    employee,
    order_date = lubridate::as_date(order_utc),
    order_hour = lubridate::hour(order_utc),
    category2
  )][, .(
    ave_sales_per_hour = mean(V1)
  ), keyby = .(employee, category2)]

  ## populate rows for budtenders that have 0 sales per hour for a given category
  tmp <- dcast(vtPerHour, employee ~ category2, value.var = "ave_sales_per_hour", fill = 0)
  vtPerHour <- melt(data = tmp,
                    id.vars = "employee",
                    variable.name = "category2",
                    value.name = "ave_sales_per_hour")

  levs <- vtPerHour[category2 == select_cat, employee[order(ave_sales_per_hour)]]
  vtPerHour[, employee := factor(employee, levs)]


  vtPerHour[category2 == select_cat,
            labs := scales::dollar(ave_sales_per_hour, accuracy = 1)]

  setkeyv(vtPerHour, "employee")
  vtPerHour[, tot_sales_per_hour := sum(ave_sales_per_hour), keyby = employee]

  q3 <- vtPerHour[category2 == select_cat, quantile(ave_sales_per_hour, .75)]
  q1 <- vtPerHour[category2 == select_cat, quantile(ave_sales_per_hour, .25)]

  vtPerHour[, group_high := ave_sales_per_hour[category2 == select_cat] > q3, employee]
  vtPerHour[, group_low := ave_sales_per_hour[category2 == select_cat] < q1, employee]

  vtPerHour[(group_high), perf_group := "Top"]
  vtPerHour[(group_low), perf_group := "Low"]
  vtPerHour[is.na(perf_group), perf_group := "Middle"]

  vtPerHour[, perf_group := factor(perf_group, levels = c("Top", "Middle", "Low"))]


  ## for plot labeling
  tmp <- vtPerHour[is.na(labs)]
  tmp[, labs := scales::dollar(tot_sales_per_hour, accuracy = 1)]

  p <- ggplot(vtPerHour, aes(employee, ave_sales_per_hour, fill = category2)) +
    geom_bar(stat = "identity") +
    facet_grid(perf_group ~ ., scales = "free", space = "free") +
    geom_text(aes(label = labs),
              vjust = .5,
              hjust = 0,
              colour = "white") +
    geom_text(data = tmp, aes(employee, tot_sales_per_hour, label = labs),
              vjust = .5,
              hjust = 0,
              colour = "green4") +
    coord_flip() +
    scale_fill_economist() +
    scale_y_continuous(expand = c(0, 0, .07, 0)) +
    theme_bw() +
    theme(
      legend.position = "top",
      strip.text.y = element_text(angle = 0),
      plot.title = element_text(hjust = 0.5),
      axis.ticks = element_blank(),
      axis.text.x = element_blank(),
      panel.grid = element_blank(),
      panel.border = element_blank(),
      axis.title = element_blank(),
      legend.title = element_blank()
    )

  sph_summ <- dcast(
    vtPerHour[, scales::dollar(mean(ave_sales_per_hour), accuracy = 1), .(perf_group, category2)],
    category2 ~ perf_group,
    value.var = "V1"
  )

  target_training_impact <- .3

  pct_sales_per_hour_gain <- vtPerHour[
    category2 == select_cat & perf_group == "Low",
    sum(ave_sales_per_hour * target_training_impact) / sum(tot_sales_per_hour)
  ]

  est_sales_per_day_impact <- vtPerHour[category2 == select_cat & perf_group == "Low",
                                        sum(tot_sales_per_hour) * pct_sales_per_hour_gain * 8]

  est_impact <- list(
    target_training_impact = target_training_impact,
    pct_sales_per_hour_gain = pct_sales_per_hour_gain,
    est_sales_per_day_impact = est_sales_per_day_impact
  )

  OUT <- list(
    plot = p,
    summ = sph_summ,
    impact = est_impact,
    n_low = vtPerHour[perf_group == "Low", .N, employee][, .N]
  )
  return(OUT)
}

plotBdrPerformance <- function(bdrHourlyDT, select_store, select_budtender) {

  ## data for plotting
  pdata <- bdrHourlyDT[
    store == select_store &
      sales < quantile(sales, .8) & sales > quantile(sales, .2)
  ]

  ## find the upper and lower bounds for the error bars in the plot
  pdata[, c("sales_ub", "sales_lb") := .(
    mean(sales) + 1.64 * sqrt(sd(sales)),
    mean(sales) - 1.64 * sqrt(sd(sales))
  ), .(store, category)]

  ## Set category ordering for plot
  levs <- pdata[, mean(sales), category][order(-V1), category]
  pdata[, category := factor(category, levs)]

  ## set new labels and adjust tablets and capsules for readability when rendered
  levs <- pdata[, levels(category)]
  labs <- str_to_title(levs)
  labs[str_detect(labs, "Tablets")] <- "Tabs/Caps"
  pdata[, category := factor(category, levels = levs, labels = labs)]

  ## data for overlaying budtender performance
  pdata2 <- pdata[, .(
    units = mean(units),
    sales = mean(sales),
    sales_per_unit = mean(sales_per_unit)
  ), .(category, employee, sales_ub, sales_lb)]

  ## assign budtenders to performance groups
  pdata2[sales < sales_lb,  perf_group := "Low"]
  pdata2[sales > sales_ub,  perf_group := "High"]
  pdata2[is.na(perf_group), perf_group := "Average"]

  ## set performance groups order for plot legend
  pdata2[, perf_group := factor(perf_group, levels = c("High", "Low", "Average"))]

  ## ensure plot maps colors/shapes to the correct performance groups for selected budtender
  legendLookup <- data.table(
    p = c("High", "Low", "Average"),
    c = c("green4", "red2", "blue3"),
    s = c(17, 25, 10)
  )
  bdr_groups <- pdata2[employee == select_budtender, unique(perf_group)]

  legend_colors <- legendLookup[p %in% bdr_groups, c]
  legend_shapes <- legendLookup[p %in% bdr_groups, s]

  ## set plot title
  ptitle <- str_glue("Sales Per Hour @ {select_store} | {str_to_title(select_budtender)}")

  ## define custom theme
  mytheme <- theme(
    axis.title = element_blank(),
    axis.ticks = element_blank(),
    axis.text.x = element_blank(),
    axis.line.x.bottom = element_line(color = "honeydew3", linewidth = 1),
    legend.justification = c(0, .5),
    legend.position = "top",
    legend.box.spacing = unit(.2, units = "cm"),
    legend.box.background = element_rect(fill = "honeydew", color = "honeydew3"),
    legend.box.margin = margin(t = 0, l = 0),
    panel.grid.major.x = element_blank(),
    panel.grid.minor.y = element_blank(),
    strip.text.x = element_text(size = 10, color = "black", face = "bold"),
    strip.background = element_rect(color = "honeydew3", fill = "honeydew", size = 1)
  )

  ## Build Plot - create base layer
  b0 <- ggplot(pdata, aes(category, sales, group = category)) +
    scale_y_continuous(labels = scales::dollar_format()) +
    facet_grid(. ~ category, space = "free", scales = "free")

  ## Build Plot - add store performance layer
  p1 <- b0 +
    stat_summary(linetype = 1,
                 alpha = .7,
                 show.legend = FALSE,
                 fun = mean,
                 fun.max = function(x) mean(x) + 1.64 * sqrt(sd(x)),
                 fun.min = function(x) mean(x) - 1.64 * sqrt(sd(x)),
                 geom = "errorbar") +
    stat_summary(linetype = 1,
                 show.legend = FALSE,
                 alpha = .8,
                 fun = mean,
                 geom = "crossbar")

  ## Build Plot - add budtender overlay with custom legend config
  p2 <- p1 +
    geom_point(aes(fill = perf_group, color = perf_group, shape = perf_group),
               data = pdata2[employee == select_budtender],
               show.legend = TRUE,
               size = 4) +
    scale_color_manual(values = legend_colors) +
    scale_fill_manual(values = legend_colors) +
    scale_shape_manual(values = legend_shapes) +
    guides(color = guide_legend(title = "Performance:")) +
    guides(shape = guide_legend(title = "Performance:")) +
    guides(fill = guide_legend(title = "Performance:"))

  ## Build Plot - finishing touch
  p3 <- p2 + mytheme
  p3
}

getHighLowStats <- function(DT) {
  ## get stats to display
  tmp <- DT[perf_group != "Middle", .(
    ave_orders_pday = ceiling(mean(ave_orders_per_day)),
    ave_ticket_size = scales::dollar(mean(ave_order_size), accuracy = 1)
  ), keyby = .(perf_group, category)]

  ticketSize <- dcast(tmp, category ~ perf_group, value.var = "ave_ticket_size")
  ordersPerDay <- dcast(tmp, category ~ perf_group, value.var = "ave_orders_pday")

  perfStats <- DT[perf_group != "Middle", .(
    sum(ave_spday),
    sum(ave_upday),
    sum(ave_spday) / sum(ave_upday)
  ), .(perf_group, employee)][, .(
    ave_sales_pday = scales::dollar(mean(V1), accuracy = 1),
    ave_units_pday = ceiling(mean(V2)),
    ave_sales_punit = scales::dollar(mean(V3), accuracy = 1)
  ), keyby = perf_group]

  salesPerDay <- transpose(perfStats, keep.names = "perf_group", make.names = TRUE)

  ## set category order
  levs_cats <- ordersPerDay[order(-Top), category]
  ordersPerDay[, category := factor(category, levels = levs_cats)]
  ticketSize[, category := factor(category, levels = levs_cats)]

  list(
    overall = salesPerDay,
    category = list(ticketSize = ticketSize, ordersPerDay = ordersPerDay)
  )
}
