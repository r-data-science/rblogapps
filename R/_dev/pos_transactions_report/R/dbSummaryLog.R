
## Function called as background job on shiny session start
dbSummaryLog <- function(cfg = NULL, rep_date = NULL, indx = NULL) {
  data.table::setDT(indx)

  if (is.null(indx))
    stop("Org index table is NULL")

  if (is.null(rep_date))
    rep_date <- lubridate::today() - lubridate::days(90)

  # This ensures logs are printed to one line during background job
  old_width <- getOption("width", 40)
  options(width = 1000)
  on.exit(options(width = old_width))

  # Set cfg to NULL manually for now since we only have a single server host
  cn <- rpgconn::dbc(db = "integrated")
  on.exit(rpgconn::dbd(cn), add = TRUE)

  .env <- rlang::current_env()

  # Get and print population report log entry for each location
  for (i in 1:nrow(indx)) {
    oid <- indx[i, org_uuid]
    sid <- indx[i, store_uuid]

    qry <- stringr::str_glue(
      "SELECT COUNT(DISTINCT order_id) AS count,
        SUM(order_line_total) AS sales
       FROM population
       WHERE org_uuid = '{oid}'
        AND store_id = '{sid}'
        AND date(order_time_local) = '{rep_date}';",
      .envir = .env
    )
    res <- data.table::setDT(DBI::dbGetQuery(cn, qry))

    res$sales[is.na(res$sales)] <- 0 # no orders = no sales, set to 0

    # Create row for log entry to print out
    r <- indx[i, .(
      org_short,
      store_short,
      rep_date,
      as.character(res$count),
      scales::dollar(res$sales, accuracy = 1),
      cfg,
      store_pos
    )]

    # This prints in the background job for shiny observer to fetch
    print(r, row.names = FALSE, col.names = "none")
  }
  invisible(TRUE)
}

