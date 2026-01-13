#' This function is a workaround to ensure that the `raster` package
#' is loaded when plotting `RasterLayer` objects from within the
#' `locationallocation` package (e.g., `plot(naples_population)`).
#'
#' Simply importing `plot` with `importFrom()` does not work because
#' S4 method dispatch requires the `raster` package to be loaded for
#' RasterLayer objects to be plotted correctly.
#'
#' @noRd
plot <- function(x, ...) {
  if (inherits(x, "RasterLayer")) {
    raster::plot(x, ...)
  } else {
    graphics::plot(x, ...)
  }
}

facilities_coordinates <- function(facilities, bb_area = NULL) {
  assert_facilities(facilities)
  assert_bb_area(bb_area, null_ok = TRUE)

  if (!is.null(bb_area)) {
    facilities <-
      facilities |>
      sf::st_filter(bb_area)
  }

  facilities |>
    sf::st_coordinates() |>
    dplyr::as_tibble()
}

points_to_matrix <- function(points, n = NULL) {
  checkmate::assert_data_frame(points, ncols = 2)
  checkmate::assert_set_equal(colnames(points), c("X", "Y"))
  checkmate::assert_int(n, null.ok = TRUE)

  if (checkmate::test_data_frame(points)) {
    n <- nrow(points)
  }

  data.frame() |>
    magrittr::inset(seq_len(n), 1, points["X"]) |>
    magrittr::inset(seq_len(n), 2, points["Y"]) |>
    as.matrix()
}

normalize_raster <- function(r) {
  r_min <- raster::cellStats(r, stat = "min")
  r_max <- raster::cellStats(r, stat = "max")

  (r - r_min) / (r_max - r_min)
}

get_cache_directory <- function() {
  out <- tools::R_user_dir("locationallocation", which = "cache")

  if (!dir.exists(out)) {
    dir.create(out, recursive = TRUE)
  }

  out
}
