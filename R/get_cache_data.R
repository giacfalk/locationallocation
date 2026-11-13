get_cache_data <- function(dataset, bb_area, download = TRUE) {
  urls <- c(
    "Accessibility__201501_Global_Travel_Speed_Friction_Surface" =
      "https://osf.io/za4cv/download",
    "Accessibility__202001_Global_Walking_Only_Friction_Surface" =
      "https://osf.io/yn78e/download"
  )

  checkmate::assert_choice(dataset, names(urls))
  assert_bb_area(bb_area)
  checkmate::assert_flag(download)

  cache_dir <- get_cache_directory()

  file <-
    list.files(
      path = cache_dir,
      pattern = paste0(substring(dataset, 16), ".*\\.tif$"),
      full.names = TRUE,
      recursive = TRUE
    ) |>
    dplyr::first()

  if (!is.na(file)) {
    cli::cli_progress_step("Using cached surface friction data")

    return(
      file |>
        terra::rast() |>
        crop_to_area(bb_area) |>
        raster::raster()
    )
  }

  if (isFALSE(download)) {
    cli::cli_abort(
      paste0(
        "The cached friction surface could not be found in ",
        "{.path {cache_dir}} after downloading it. ",
        "Try again with {.code cache = FALSE}."
      )
    )
  }

  cli::cli_progress_step("Downloading and caching surface friction data")

  zip_file <- tempfile(fileext = ".zip")
  on.exit(unlink(zip_file), add = TRUE)

  curl::curl_download(urls[[dataset]], zip_file, quiet = TRUE)
  zip::unzip(zip_file, exdir = cache_dir)

  get_cache_data(dataset, bb_area, download = FALSE)
}
