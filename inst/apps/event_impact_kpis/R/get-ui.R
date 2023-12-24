get_orgs <- function() {
  getAppData()[, sort(unique(org))]
}


get_kpi_vars <- function() {
  list(
    `Sales Per Order` = "sales_per_order",
    `Total Sales` = "total_sales",
    `Total Units` = "total_units",
    `Total Orders` = "total_orders",
    `Percent Retail Units` = "pct_retail_units",
    `Percent Retail Sales` = "pct_retail_sales",
    `Count Unique Customers` = "n_uniq_customers",
    `Count Unique Brands` = "n_uniq_brands",
    `Count Unique Products` = "n_uniq_products",
    `Average Discount Rate` = "ave_disc_rate"
  )
}

get_kpi_label <- function(x) {
  get_kpi_vars() |>
    sapply(`==`, x) |>
    which() |>
    names()
}

get_bx_header <- function() {
  list(
    fluidRow(
      column(3),
      column(3, descriptionBlock(header = "Pre-Event", rightBorder = FALSE)),
      column(3, descriptionBlock(header = "Post-Event", rightBorder = FALSE)),
      column(3, descriptionBlock(header = "% Change", rightBorder = FALSE))
    )
  )
}

get_store_stat_summary_ui <- function(stat_ll, y) {
  index <- seq_along(stat_ll)

  c(get_bx_header(),

    lapply(index, function(iter) {
      i <- stat_ll[[iter]]

      if (length(i$hca_start) == 0)
        return(NULL)

      ## if this iteration is the last store (i.e. row) then add a margin to the bottom
      margin_bottom <- iter == max(index)

      ## value used in a description block below
      val_delta <- (i$post_value - i$prior_value) / i$prior_value

      ## if prior_value was 0, then pct_delta will be inf, therefore adjust the calculation
      pct_delta <- scales::percent(ifelse(is.infinite(val_delta), i$post_value, val_delta))

      ## if value of kpi after < before then set appropriate colors, else set the reverse
      prior_number_color <- "success"
      after_number_color <- "danger"
      delta_number_color <- "danger"
      delta_number_icon <- "caret-down"

      if (i$post_value > i$prior_value) {
        prior_number_color <- "danger"
        after_number_color <- "success"
        delta_number_color <- "success"
        delta_number_icon <- "caret-up"
      }

      ## Format dates for showing on UI
      post_start <- format(i$hca_start, "%b'%y")
      prior_stop <- format(i$hca_start - month(1), "%b'%y")
      prior_start <- format(i$prior_start, "%b'%y")

      fluidRow(
        column(
          width = 3,
          descriptionBlock(
            numberIcon = icon("store"),
            header = i$store,
            rightBorder = FALSE,
            marginBottom = margin_bottom
          )
        ),
        column(
          width = 3,
          descriptionBlock(
            number = f_label(y)(i$prior_value),
            numberColor = prior_number_color,
            text = paste0(prior_start, " - ", prior_stop),
            rightBorder = FALSE,
            marginBottom = margin_bottom
          )
        ),
        column(
          width = 3,
          descriptionBlock(
            number = f_label(y)(i$post_value),
            numberColor = after_number_color,
            text = paste0(post_start, " - Present"),
            rightBorder = FALSE,
            marginBottom = margin_bottom
          )
        ),
        column(
          width = 3,
          descriptionBlock(
            number = pct_delta,
            numberColor = delta_number_color,
            numberIcon = icon(delta_number_icon),
            text = "pre vs post",
            rightBorder = FALSE,
            marginBottom = margin_bottom
          )
        )
      )
    }))
}

get_org_stat_summary_ui <- function(stat_ll, y) {
  prior_val <- stat_ll$prior_value
  after_val <- stat_ll$post_value

  ## Format dates for showing on UI
  post_start <- format(stat_ll$hca_start, "%b'%y")
  prior_stop <- format(stat_ll$hca_start - month(1), "%b'%y")
  prior_start <- format(stat_ll$prior_start, "%b'%y")

  ## value used in a description block below
  val_delta <- (after_val - prior_val) / prior_val

  ## if prior_value was 0, then pct_delta will be inf, therefore adjust the calculation
  pct_delta <- scales::percent(ifelse(is.infinite(val_delta), after_val, val_delta))

  ## if value of kpi after < before then set appropriate colors, else set the reverse
  prior_number_color <- "success"
  after_number_color <- "danger"
  delta_number_color <- "danger"
  delta_number_icon <- "caret-down"
  if (after_val > prior_val) {
    prior_number_color <- "danger"
    after_number_color <- "success"
    delta_number_color <- "success"
    delta_number_icon <- "caret-up"
  }

  tagList(
    get_bx_header(),
    fluidRow(
      column(
        width = 3,
        descriptionBlock(
          numberIcon = icon("store"),
          header = "All Stores",
          rightBorder = FALSE,
          marginBottom = TRUE
        )
      ),
      column(
        width = 3,
        descriptionBlock(
          number = f_label(y)(prior_val),
          numberColor = prior_number_color,
          text = paste0(prior_start, " - ", prior_stop),
          rightBorder = FALSE,
          marginBottom = TRUE
        )
      ),
      column(
        width = 3,
        descriptionBlock(
          number = f_label(y)(after_val),
          numberColor = after_number_color,
          text = paste0(post_start, " - Present"),
          rightBorder = FALSE,
          marginBottom = TRUE
        )
      ),
      column(
        width = 3,
        descriptionBlock(
          number = pct_delta,
          numberColor = delta_number_color,
          numberIcon = icon(delta_number_icon),
          text = "pre vs post",
          rightBorder = FALSE,
          marginBottom = TRUE
        )
      )
    )
  )
}

