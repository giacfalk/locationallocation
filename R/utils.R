# Return a two-column (x, y) coordinate matrix of point geometries, optionally
# keeping only the points that fall within the extent of a raster.
points_xy <- function(x, within = NULL) {
  xy <- sf::st_coordinates(sf::st_geometry(x))[, c("X", "Y"), drop = FALSE]
  colnames(xy) <- c("x", "y")

  if (!is.null(within)) {
    xy <- xy[in_extent(xy, within), , drop = FALSE]
  }

  xy
}

in_extent <- function(xy, within) {
  e <- raster::extent(within)

  xy[, 1] >= e@xmin & xy[, 1] <= e@xmax &
    xy[, 2] >= e@ymin & xy[, 2] <= e@ymax
}

# Values of `x` on the grid of `template` (nearest-neighbor resampling).
#
# Nearest-neighbor resampling commutes with the pointwise minimum, so the
# travel time from a set of points is exactly the minimum of the travel times
# from each point. This keeps the coverage computed by the optimisation
# routines consistent with the returned travel time maps.
#
# The value of each cell of `template` is the value of the cell of `x` that
# contains its centre. Unlike `terra::resample()`, which goes through GDAL in
# single precision, this keeps values in double precision.
grid_values <- function(x, template) {
  if (!inherits(x, "SpatRaster") && !inherits(template, "SpatRaster")) {
    if (same_grid(x, template)) return(raster::values(x))

    index <- raster::cellFromXY(
      x,
      raster::xyFromCell(template, seq_len(raster::ncell(template)))
    )

    return(raster::values(x)[index])
  }

  x <- as_spatraster(x)
  template <- as_spatraster(template)

  index <- terra::cellFromXY(
    x,
    terra::xyFromCell(template, seq_len(terra::ncell(template)))
  )

  terra::values(x, mat = FALSE)[index]
}

# Whether two `Raster*` objects have the same grid (dimensions and extent).
same_grid <- function(a, b) {
  identical(dim(a)[1:2], dim(b)[1:2]) &&
    isTRUE(all.equal(
      as.vector(raster::extent(a)),
      as.vector(raster::extent(b))
    ))
}

# Note: `terra::rast()` applied to a `SpatRaster` returns an empty template, so
# only convert `Raster*` objects.
as_spatraster <- function(x) {
  if (inherits(x, "SpatRaster")) x else terra::rast(x)
}

# Shortest-path graph of a `TransitionLayer`, with edge costs equal to the
# inverse of the conductances, as built by `gdistance::accCost()`. Building
# the graph is the most expensive part of `accCost()`, so it is built once
# and reused for all the travel time computations of a problem.
#
# With a `template`, the cell of the transition grid that contains the centre
# of each cell of `template` is also precomputed (nearest-neighbor
# alignment).
routing_graph <- function(transition, template = NULL) {
  matrix <- methods::as(
    gdistance::transitionMatrix(transition),
    "generalMatrix"
  )

  graph <- igraph::graph_from_adjacency_matrix(
    matrix,
    mode = "directed",
    weighted = TRUE
  )

  igraph::E(graph)$weight <- 1 / igraph::E(graph)$weight
  grid <- methods::as(transition, "RasterLayer")

  index <- if (!is.null(template)) {
    raster::cellFromXY(
      grid,
      raster::xyFromCell(template, seq_len(raster::ncell(template)))
    )
  }

  list(graph = graph, grid = grid, template = template, index = index)
}

# Travel time (minutes) from the nearest of one or more points, on the grid
# of `template`. Equivalent to `gdistance::accCost()` followed by
# nearest-neighbor alignment to `template`. `router` is the output of
# `routing_graph()` (or a `TransitionLayer`).
travel_time_values <- function(router, xy, template) {
  if (inherits(router, "TransitionLayer")) router <- routing_graph(router)

  cells <- raster::cellFromXY(router$grid, as.matrix(xy)[, 1:2, drop = FALSE])
  cells <- unique(cells[!is.na(cells)])
  out <- rep(Inf, raster::ncell(router$grid))

  for (chunk in split(cells, ceiling(seq_along(cells) / 50))) {
    distances <- igraph::distances(
      router$graph,
      v = chunk,
      mode = "out",
      algorithm = "dijkstra"
    )

    for (i in seq_len(nrow(distances))) out <- pmin(out, distances[i, ])
  }

  if (!is.null(router$index) && same_grid(router$template, template)) {
    return(out[router$index])
  }

  router$grid |>
    raster::setValues(out) |>
    grid_values(template)
}

values_to_raster <- function(values, template, name = "travel_time") {
  out <- raster::setValues(raster::raster(template), values)
  names(out) <- name

  out
}

# Min-max normalization of a vector of cell values to [0, 1], ignoring `NA`.
normalize_values <- function(x) {
  range <- suppressWarnings(range(x, na.rm = TRUE))

  if (!all(is.finite(range)) || isTRUE(all.equal(range[1], range[2]))) {
    # A constant layer carries no relative information.
    return(ifelse(is.na(x), NA, 1))
  }

  (x - range[1]) / (range[2] - range[1])
}

# Combine the demand values (cells of `template`) and the weights layer into
# the (weighted) demand that the allocation routines try to cover.
weighted_demand <- function(
  demand,
  template,
  weights = NULL,
  approach = "norm",
  exp_demand = 1,
  exp_weights = 1
) {
  if (is.null(weights)) {
    return(demand^exp_demand)
  }

  if (same_grid(weights, template)) {
    weights <- raster::values(weights)
  } else {
    cli::cli_alert_info(
      "Resampling {.strong weights} to the grid of {.strong demand}."
    )

    raster::crs(weights) <- raster::crs(template)

    weights <-
      weights |>
      raster::resample(template, method = "bilinear") |>
      raster::values()
  }

  weights[is.na(demand)] <- NA

  if (approach == "norm") {
    normalize_values(demand)^exp_demand * normalize_values(weights)^exp_weights
  } else {
    if (isTRUE(min(weights, na.rm = TRUE) < 0)) {
      cli::cli_abort(
        paste0(
          "{.strong weights} must be non-negative when ",
          "{.code approach = \"absweights\"}."
        )
      )
    }

    normalize_values(demand)^exp_demand * weights^exp_weights
  }
}

# Crop a `SpatRaster` to the extent of `bb_area`, keeping all cells that
# overlap it. The extent is shrunk by a negligible amount so that floating
# point error does not add a row or column of cells when the boundary of
# `bb_area` coincides with cell edges.
crop_to_area <- function(x, bb_area) {
  e <-
    bb_area |>
    sf::st_transform(sf::st_crs(terra::crs(x))) |>
    sf::st_bbox()

  eps <- 1e-6 * min(terra::res(x))

  terra::crop(
    x,
    terra::ext(e[["xmin"]] + eps, e[["xmax"]] - eps, e[["ymin"]] + eps,
               e[["ymax"]] - eps),
    snap = "out"
  )
}

# The cache directory is only created when data are written to it.
get_cache_directory <- function(create = FALSE) {
  out <- getOption(
    "locationallocation.cache_dir",
    tools::R_user_dir("locationallocation", which = "cache")
  )

  if (isTRUE(create) && !dir.exists(out)) {
    dir.create(out, recursive = TRUE)
  }

  out
}

# Run an expression silencing printed output and messages from third-party
# functions (e.g., `malariaAtlas::getRaster()`).
quietly <- function(expr) {
  out <- NULL
  utils::capture.output(out <- suppressMessages(expr))

  out
}

# Escape braces so that text is not interpreted by `cli`.
cli_escape <- function(x) {
  gsub("}", "}}", gsub("{", "{{", x, fixed = TRUE), fixed = TRUE)
}
