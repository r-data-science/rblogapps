# rblogapps

<!-- badges: start -->

[![R-CMD-check](https://github.com/r-data-science/rblogapps/actions/workflows/R-CMD-check.yaml/badge.svg?branch=main)](https://github.com/r-data-science/rblogapps/actions/workflows/R-CMD-check.yaml)
[![test-coverage](https://github.com/r-data-science/rblogapps/actions/workflows/test-coverage.yaml/badge.svg?branch=main)](https://github.com/r-data-science/rblogapps/actions/workflows/test-coverage.yaml)

<!-- badges: end -->


## Package Structure

```         

```

------------------------------------------------------------------------

## Install & Run App

#### In R Session

This package exports a single R function that launches the packaged
shiny app:

``` r
# remotes::install_github("r-data-science/rblogapps")

rblogapps::list_blog_apps()[1] |> 
  rblogapps::rdsRunApp()
```

#### In Docker Container

To run this as a docker container, perform the following bash commands:

```{bash}

```

------------------------------------------------------------------------

Proprietary - Do Not Distribute
