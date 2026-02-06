get_cache_data <- function(dataset, bb_area) {
  choices <- c(
    "Accessibility__201501_Global_Travel_Speed_Friction_Surface",
    "Accessibility__202001_Global_Walking_Only_Friction_Surface"
  )

  checkmate::assert_choice(dataset, choices)
  assert_bb_area(bb_area)

  cache_dir <- tools::R_user_dir("locationallocation", which = "cache")

  if (!dir.exists(cache_dir)) {
    dir.create(cache_dir, recursive = TRUE)
  }

  file <-
    list.files(
      path = cache_dir,
      pattern = paste0(substring(dataset, 16), ".*\\.tif$"),
      full.names = TRUE,
      include.dirs = FALSE
    ) |>
    dplyr::first()

  if (!is.na(file)) {
    cli::cli_progress_step("Using cached surface friction data")

    out <- stars::read_stars(file)

    bb_area_transformed <- sf::st_transform(bb_area, sf::st_crs(out))

    out |>
      stars::st_crop(bb_area_transformed)
  } else {
    cli::cli_progress_step("Downloading and caching surface friction data")

    if (
      dataset == "Accessibility__201501_Global_Travel_Speed_Friction_Surface"
    ) {
      "https://osf.io/za4cv/download" |>
        curl::curl_download(tempfile()) |>
        zip::unzip(exdir = cache_dir)

      get_cache_data(dataset, bb_area)
    } else {
      "https://osf.io/yn78e/download" |>
        curl::curl_download(tempfile()) |>
        zip::unzip(exdir = cache_dir)

      get_cache_data(dataset, bb_area)
    }
  }
}
