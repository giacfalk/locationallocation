test_that("friction() works offline with a local file", {
  out <- friction(problem$bb_area, res_output = 1000, file = problem$file) |>
    suppressMessages()

  expect_named(
    out,
    c("friction_layer", "transition_matrix", "geocorrection_matrix")
  )
  expect_s4_class(out$friction_layer, "RasterLayer")
  expect_s4_class(out$geocorrection_matrix, "TransitionLayer")
  expect_equal(
    unique(stats::na.omit(raster::values(out$friction_layer))),
    0.012
  )
})

synthetic_roads <- function(speed = NULL) {
  roads <- sf::st_sf(
    highway = c("primary", "footway"),
    geometry = sf::st_sfc(
      sf::st_linestring(rbind(c(14.001, 40.8215), c(14.049, 40.8215))),
      sf::st_linestring(rbind(c(14.025, 40.801), c(14.025, 40.829))),
      crs = 4326
    )
  )

  if (!is.null(speed)) roads$speed <- speed

  roads
}

test_that("friction() resamples the walking surface at finer resolution", {
  coarse <- friction(problem$bb_area, res_output = 1000, file = problem$file) |>
    suppressMessages()
  fine <- friction(problem$bb_area, res_output = 100, file = problem$file) |>
    suppressMessages()

  layer <- fine$friction_layer
  meters <- raster::res(layer) * c(111320 * cos(40.815 * pi / 180), 110574)

  # About `res_output` meters (cells are adjusted to fit the extent).
  expect_equal(meters, c(100, 100), tolerance = 0.05)

  # Values are those of the coarse surface at the same locations.
  xy <- raster::xyFromCell(layer, seq_len(raster::ncell(layer)))
  expect_equal(
    raster::values(layer),
    raster::extract(coarse$friction_layer, xy)
  )
})

test_that("friction() uses road speeds in fastest mode", {
  fine <- friction(
    problem$bb_area,
    mode = "fastest",
    res_output = 100,
    file = problem$file,
    roads = synthetic_roads()
  ) |>
    suppressMessages()

  layer <- fine$friction_layer
  values <- raster::values(layer)
  on_primary <- raster::extract(layer, cbind(c(14.01, 14.04), 40.8215))
  off_road <- raster::extract(layer, cbind(14.01, 40.805))

  # Primary roads at 65 km/h; footways are not in the speed table.
  expect_equal(on_primary, rep(0.06 / 65, 2))
  expect_equal(off_road, 0.012)
  # The synthetic surface is stored in single precision.
  expect_setequal(
    unique(signif(stats::na.omit(values), 6)),
    signif(c(0.012, 0.06 / 65), 6)
  )

  # Explicit speeds; roads slower than walking do not slow it down.
  slow <- friction(
    problem$bb_area,
    mode = "fastest",
    res_output = 100,
    file = problem$file,
    roads = synthetic_roads(speed = c(2, 30))
  ) |>
    suppressMessages()

  slow_values <- raster::values(slow$friction_layer)

  expect_equal(
    raster::extract(slow$friction_layer, cbind(14.01, 40.8215)),
    0.012
  )
  expect_true(any(slow_values == 0.06 / 30, na.rm = TRUE))

  # Without roads, only walking speeds are used.
  expect_warning(
    friction(
      problem$bb_area,
      mode = "fastest",
      res_output = 100,
      file = problem$file,
      roads = synthetic_roads()[2, ]
    ) |>
      suppressMessages(),
    "No roads"
  )
})

test_that("roads speed up travel in fastest mode", {
  start <- sf::st_as_sf(
    data.frame(x = 14.005, y = 40.8215),
    coords = c("x", "y"),
    crs = 4326
  )

  walk <- traveltime(start, problem$bb_area, res_output = 100,
                     file = problem$file) |>
    suppressMessages()
  fastest <- traveltime(start, problem$bb_area, mode = "fastest",
                        res_output = 100, file = problem$file,
                        roads = synthetic_roads()) |>
    suppressMessages()

  end <- cbind(14.045, 40.8215)
  walk_time <- raster::extract(walk$travel_time, end)
  fastest_time <- raster::extract(fastest$travel_time, end)

  expect_lt(fastest_time, walk_time / 5)
})

test_that("friction() deprecates dowscaling_model_type", {
  expect_warning(
    friction(
      problem$bb_area,
      dowscaling_model_type = "lm",
      res_output = 1000,
      file = problem$file
    ) |>
      suppressMessages(),
    "deprecated"
  )
})

test_that("default_road_speeds() returns named speeds", {
  speeds <- default_road_speeds()

  expect_named(speeds)
  expect_true(all(speeds > 0))
  expect_equal(speeds[["motorway"]], 90)
})

test_that("friction() validates its inputs", {
  expect_error(
    friction(
      problem$bb_area,
      mode = "fastest",
      res_output = 100,
      file = problem$file,
      roads = problem$facilities
    ),
    "LINESTRING"
  )
  expect_error(friction(problem$facilities, file = problem$file))
  expect_error(friction(problem$bb_area, mode = "car", file = problem$file))
  expect_error(friction(problem$bb_area, res_output = 0, file = problem$file))
  expect_error(friction(problem$bb_area, file = "does-not-exist.tif"))
})
