#' Helpers to Anonymize Data
#'
#' @param n Count of anonymized samples to retrieve
#' @param us_state defaults to California
#'
#' @import data.table
#' @importFrom randomNames randomNames
#' @importFrom httr2 request req_perform resp_body_string
#' @importFrom fs path
#' @importFrom jsonlite fromJSON
#' @importFrom stringr str_flatten
#'
#' @name anonymize-data
NULL

#' @describeIn anonymize-data Function to anonymize store employee names
#' @export
gen_random_name <- function(n = 1) {
  randomNames::randomNames(
    n = n,
    name.order = "first.last",
    name.sep = " ",
    ethnicity = 1:5,
    sample.with.replacement = FALSE
  )
}

#' @describeIn anonymize-data Function to anonymize retail store locations
#' @export
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
