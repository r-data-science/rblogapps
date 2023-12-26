formatPercent <- function(x) {
  tagList(round(x*100, 1), tags$sup(style="font-size: 20px", "%"))
}
formatDollers <- function(x) {
  tagList(tags$sup(style="font-size: 20px", "$"), round(x, 1))
}
formatBoxTitle <- function(x) {
  span(tags$em(x), style = 'font-size:16px;color:white;')
}
