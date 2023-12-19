getAppData <- function() {
  appdata <- getBlogData("event_impact_kpis")
  setkey(appdata, org)
  appdata[]
}

