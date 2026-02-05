#' @noRd
#' @export
plot <- function(x, ...) {
  graphics::plot(x, ...)
}

as_stars_if_needed <- function(x) {
  if (inherits(x, "stars")) {
    return(x)
  }

  if (!requireNamespace("stars", quietly = TRUE)) {
    cli::cli_abort("The {.pkg stars} package is required to handle raster data.")
  }

  stars::st_as_stars(x)
}

as_raster_if_needed <- function(x) {
  if (inherits(x, "Raster")) {
    return(x)
  }

  if (!requireNamespace("raster", quietly = TRUE)) {
    cli::cli_abort(
      "The {.pkg raster} package is required for cost-distance calculations."
    )
  }

  methods::as(x, "Raster")
}

assert_stars <- function(x, null_ok = FALSE) {
  if (isTRUE(null_ok) && is.null(x)) {
    return(invisible(TRUE))
  }

  checkmate::assert_class(x, "stars")
}

stars_sum <- function(x) {
  sum(stars::st_values(x), na.rm = TRUE)
}

stars_max_cell <- function(x) {
  value_name <- names(x)[1]
  values <- as.vector(stars::st_values(x))
  values_no_na <- ifelse(is.na(values), -Inf, values)
  max_index <- which.max(values_no_na)

  data <- as.data.frame(x, xy = TRUE)
  max_row <- data[which.max(data[[value_name]]), c("x", "y"), drop = FALSE]

  list(index = max_index, xy = max_row)
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
  r_values <- stars::st_values(r)
  r_min <- min(r_values, na.rm = TRUE)
  r_max <- max(r_values, na.rm = TRUE)

  (r - r_min) / (r_max - r_min)
}

get_cache_directory <- function() {
  out <- tools::R_user_dir("locationallocation", which = "cache")

  if (!dir.exists(out)) {
    dir.create(out, recursive = TRUE)
  }

  out
}
