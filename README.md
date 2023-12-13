# rblogapps

<!-- badges: start -->

[![R-CMD-check](https://github.com/r-data-science/rblogapps/actions/workflows/R-CMD-check.yaml/badge.svg?branch=main)](https://github.com/r-data-science/rblogapps/actions/workflows/R-CMD-check.yaml)
[![test-coverage](https://github.com/r-data-science/rblogapps/actions/workflows/test-coverage.yaml/badge.svg?branch=main)](https://github.com/r-data-science/rblogapps/actions/workflows/test-coverage.yaml)
[![codecov](https://codecov.io/gh/r-data-science/rblogapps/graph/badge.svg?token=4gg0ETS2w5)](https://codecov.io/gh/r-data-science/rblogapps)
[![shiny-apps](https://github.com/r-data-science/rblogapps/actions/workflows/shiny-apps.yaml/badge.svg?branch=main)](https://github.com/r-data-science/rblogapps/actions/workflows/shiny-apps.yaml)
<!-- badges: end -->

------------------------------------------------------------------------

## About

This package includes all apps assiocated with the r-data-science blog. Additionally, package includes the primary app datasets.

The three functions exported by this package are as follows:

`listBlogApps()`: Retrieves names of all apps included in this package

`runBlogApp(name)`: Run an app included in this package given it's name

`getBlogData(name)`: Returns an apps primary dataset given it's name

------------------------------------------------------------------------

## Examples

#### Install Package

```
remotes::install_github("r-data-science/rblogapps")
```

#### List Package Apps

```
rblogapps::listBlogApps()
```

#### Launch Package App

``` r
rblogapps::runBlogApps("employee_sales_kpis")
```

#### View App Dataset

``` r
rblogapps::getBlogData("employee_sales_kpis")
```

## Deployment

To run this as a docker container, perform the following bash commands:

```{bash}

```

------------------------------------------------------------------------

Proprietary - Do Not Distribute
