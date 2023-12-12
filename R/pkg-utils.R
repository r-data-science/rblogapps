#' Utilities to Run Package Apps
#'
#' @param name Name of app bundled in package
#'
#' @importFrom fs path_package dir_ls path_file
#' @importFrom remotes local_package_deps
#' @importFrom stringr str_flatten_comma
#'
#' @name pkg-utils
NULL


#' @describeIn pkg-utils List the names of all apps in the package
#' @export
#'
#' @examples
#' list_app_names()
list_app_names <- function() {
  fs::path_package("rblogapps", "shiny-apps") |>
    fs::dir_ls(type = "directory") |>
    fs::path_file()
}



#' @describeIn pkg-utils List all dependencies for a package shiny app
#' @export
#'
#' @examples
#' list_app_deps("employee_sales_kpis")
list_app_deps <- function(name) {
  is_app_valid(name) |>
    get_app_dir() |>
    remotes::local_package_deps()
}


#' @describeIn pkg-utils Get list of app dependencies that are not found
has_app_deps <- function(name) {
  message("*---- Checking Required Packages ----*")
  nf_pkgs <- list_app_deps(name) |>
    lapply(function(x) {
      ck <- requireNamespace(x, quietly = TRUE)
      if (ck)
        return(NULL)
      return(x)
    }) |>
    unlist()
  if (length(nf_pkgs) > 0) {
    stop(
      "\nDependencies missing: ",
      stringr::str_flatten_comma(nf_pkgs),
      call. = FALSE
    )
  }
  message(".........SUCCESS!")
  invisible(name)
}


#' @describeIn pkg-utils Validates the name of package app
is_app_valid <- function(name) {

  # locate all the shiny app examples that exist
  valid_apps <- list_app_names()

  valid_apps_msg <- paste0(
    "Valid apps are: '",
    paste(valid_apps, collapse = "', '"),
    "'")

  # if an invalid example is given, throw an error
  if (missing(name) || !nzchar(name) || !name %in% valid_apps) {
    stop(
      'Please run `runBlogApp()` with a valid app name.\n',
      valid_apps_msg,
      call. = FALSE
    )
  }
  invisible(name)
}


#' @describeIn pkg-utils Get directory of package app
get_app_dir <- function(name) {
  fs::path_package("rblogapps", "shiny-apps", name)
}
