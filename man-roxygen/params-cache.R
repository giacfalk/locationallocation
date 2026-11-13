#' @param cache (optional) A [`logical`][base::logical] flag indicating
#'   whether to cache downloaded data (friction surface of the area, road
#'   network) on disk and reuse it in later calls. It also enables a fallback
#'   to a one-time download of the global friction surface (~730 MB) when the
#'   Malaria Atlas Project service is unavailable. See *Details* of
#'   [`friction()`][friction()] (default: `FALSE`).
