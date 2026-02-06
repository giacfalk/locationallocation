as_stars_raster <- function(x) {
  if (inherits(x, "stars")) {
    return(x)
  }

  stars::st_as_stars(x)
}

stars_values <- function(x) {
  values <- stars::st_values(x)

  if (is.list(values)) {
    values <- values[[1]]
  }

  as.vector(values)
}

stars_set_values <- function(x, values) {
  existing <- stars::st_values(x)

  if (is.list(existing)) {
    dim_values <- dim(existing[[1]])
    existing[[1]] <- array(values, dim = dim_values)
    stars::st_values(x) <- existing
  } else {
    dim_values <- dim(existing)
    stars::st_values(x) <- array(values, dim = dim_values)
  }

  x
}

stars_cell_stats <- function(x, stat = "sum") {
  values <- stars_values(x)

  switch(
    stat,
    sum = sum(values, na.rm = TRUE),
    min = min(values, na.rm = TRUE),
    max = max(values, na.rm = TRUE),
    cli::cli_abort("Unsupported stat value.")
  )
}

stars_resolution <- function(x) {
  dims <- stars::st_dimensions(x)
  c(abs(dims$x$delta), abs(dims$y$delta))
}

stars_to_dataframe <- function(x) {
  sf_points <- stars::st_as_sf(x, as_points = TRUE, merge = FALSE)
  coords <- sf::st_coordinates(sf_points)
  values <- sf::st_drop_geometry(sf_points)

  data.frame(
    x = coords[, 1],
    y = coords[, 2],
    layer = values[[1]]
  )
}

stars_xy_from_index <- function(x, index) {
  sf_points <- stars::st_as_sf(x, as_points = TRUE, merge = FALSE)
  coords <- sf::st_coordinates(sf_points[index, , drop = FALSE])

  data.frame(x = coords[, 1], y = coords[, 2])
}

normalize_raster <- function(r) {
  r_min <- stars_cell_stats(r, stat = "min")
  r_max <- stars_cell_stats(r, stat = "max")

  (r - r_min) / (r_max - r_min)
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

get_cache_directory <- function() {
  out <- tools::R_user_dir("locationallocation", which = "cache")

  if (!dir.exists(out)) {
    dir.create(out, recursive = TRUE)
  }

  out
}
