# Get index of all orgs and locations to run logging for
getAppData <- function() {
  index_full <- hcaconfig::orgIndexFull(internal = TRUE)[
    str_detect(org_short, "demo", negate = TRUE),
    .(org_uuid, store_uuid, org_short, store_short, store_pos)
  ]
  index_full[, org_short := paste0("Org_", .GRP), org_uuid]
  index_full[, store_short := paste0("Location_", .GRP), store_uuid]
  index_full[, store_pos := paste0("POS_", .GRP), store_pos]
  return(index_full[])
}
