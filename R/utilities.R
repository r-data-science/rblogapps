#' Utilities to Run Package Apps
#'
#' Helper functions used to faciliate launching package apps or running
#' unit tests included in this package
#'
#' @param name Name of app bundled in package
#' @param path path to description file
#' @param nf_pkgs vector of not found package dependencies
#'
#' @importFrom fs path_package dir_ls path_file
#' @importFrom remotes local_package_deps
#' @importFrom stringr str_flatten_comma str_split str_extract
#'
#' @name utilities
NULL

#' @describeIn utilities returns a mapping between apps names and ids
#' @export
#'
#' @examples
#' lookupAppIds()
#'
lookupAppIds <- function() {
  return(.appids[])
}


#' @describeIn utilities List the names of all apps in this package
#' @export
#'
#' @examples
#' listBlogApps()
#'
listBlogApps <- function() {
  fs::path_package("rblogapps", "apps") |>
    fs::dir_ls(type = "directory") |>
    fs::path_file() |>
    sort()
}


#' @describeIn utilities List the names of all app datasets in this package
#' @export
#'
#' @examples
#' listBlogData()
#'
listBlogData <- function() {
  dpath <- fs::path_package("rblogapps", "data")
  if (!is_testing())
    return(sort(names(readRDS(fs::dir_ls(dpath, glob = "*.rds")))))
  return(sort(utils::data(package = "rblogapps")$results[, 3]))
}



#' @describeIn utilities Reads dependencies declared in description files
read_desc_deps <- function(path) {
  read.dcf(path, c("Imports", "Suggests")) |>
    stringr::str_split("\\,\\n?") |>
    unlist() |>
    stringr::str_extract("[A-Za-z0-9\\.]+")
}


#' @describeIn utilities List all dependencies for an app in this package
list_app_deps <- function(name) {
  x <- is_app_valid(name) |>
    get_app_dir() |>
    fs::path("DESCRIPTION") |>
    read_desc_deps()
  x[!is.na(x)]
}


#' @describeIn utilities List all dependencies declared in this package
list_pkg_deps <- function() {
  fs::path_package("rblogapps", "DESCRIPTION") |>
    read_desc_deps()
}


#' @describeIn utilities Show error if app dependencies not found
has_app_deps <- function(name) {
  message("*---- Checking Required Packages ----*")
  nf_pkgs <- nf_package_deps(name)
  if (length(nf_pkgs) > 0) stop_nf_depends(nf_pkgs)
  message(".........SUCCESS!")
  invisible(name)
}


#' @describeIn utilities Get list of app's R package depends that are not found
nf_package_deps <- function(name) {
  unlist(lapply(list_app_deps(name), function(x) {
    if (requireNamespace(x, quietly = TRUE))
      return(NULL)
    return(x)
  }))
}


#' @describeIn utilities Show 'package dependencies not found' error
stop_nf_depends <- function(nf_pkgs) {
  stop(
    "\nDependencies missing: ",
    stringr::str_flatten_comma(nf_pkgs),
    call. = FALSE
  )
}


#' @describeIn utilities Show error if given name is not a valid package app
is_app_valid <- function(name) {

  # locate all the shiny app examples that exist
  valid_apps <- listBlogApps()

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


#' @describeIn utilities Get directory of an app included in this package
get_app_dir <- function(name) {
  fs::path_package("rblogapps", "apps", name)
}


#' @describeIn utilities returns TRUE if called on CI
is_ci <- function() {
  isTRUE(as.logical(Sys.getenv("CI", "false")))
}


#' @describeIn utilities returns TRUE if called while unit testing
is_testing <- function() {
  identical(Sys.getenv("TESTTHAT"), "true")
}
