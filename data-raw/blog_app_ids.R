## This script generates a table of apps published in package and ids
##
## Notes: This needs to run after a new app is added to the package
##

library(data.table)

devtools::load_all()

# Get current mapping
lookupAppIds()

.appids <- data.table(app = listBlogApps())[, id := .I] |>
  setcolorder("id") |>
  setkeyv("app")

usethis::use_data(.appids, internal = TRUE, overwrite = TRUE)

