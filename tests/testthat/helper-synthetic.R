# A small synthetic location-allocation problem that runs offline.
#
# - Friction: walking at 5 km/h (0.012 min/m) on a ~210 x 280 m grid, with a
#   "lake" without friction data (unreachable).
# - Demand: three clusters of people on a finer (~105 x 140 m) grid, plus some
#   people living on the lake (who can never be covered).
synthetic_problem <- function() {
  friction_layer <- terra::rast(
    xmin = 13.99, xmax = 14.06, ymin = 40.79, ymax = 40.84,
    resolution = 0.0025, crs = "EPSG:4326"
  )

  xy <- terra::xyFromCell(friction_layer, seq_len(terra::ncell(friction_layer)))
  lake <- xy[, 1] > 14.035 & xy[, 1] < 14.045 & xy[, 2] > 40.81 &
    xy[, 2] < 40.815
  terra::values(friction_layer) <- ifelse(lake, NA, 0.012)

  file <- tempfile(fileext = ".tif")
  terra::writeRaster(friction_layer, file, overwrite = TRUE)

  bb_area <-
    sf::st_polygon(list(rbind(
      c(14.00, 40.80), c(14.05, 40.80), c(14.05, 40.83), c(14.00, 40.83),
      c(14.00, 40.80)
    ))) |>
    sf::st_sfc(crs = 4326) |>
    sf::st_as_sf()

  demand <- terra::rast(
    xmin = 14.00, xmax = 14.05, ymin = 40.80, ymax = 40.83,
    resolution = 0.00125, crs = "EPSG:4326"
  )

  dxy <- terra::xyFromCell(demand, seq_len(terra::ncell(demand)))
  bump <- function(x0, y0, size, sd = 0.004) {
    size * exp(-((dxy[, 1] - x0)^2 + (dxy[, 2] - y0)^2) / (2 * sd^2))
  }
  values <- 1 + bump(14.012, 40.808, 100) + bump(14.03, 40.822, 80) +
    bump(14.045, 40.805, 60)
  on_lake <- dxy[, 1] > 14.0375 & dxy[, 1] < 14.0425 &
    dxy[, 2] > 40.8115 & dxy[, 2] < 40.8135
  values[on_lake] <- 50
  terra::values(demand) <- values
  demand <- raster::raster(demand)

  weights <- raster::setValues(demand, 10 + (dxy[, 1] - 14) * 1000)

  facilities <-
    # Not on cell edges, so that CRS round trips do not change the cell.
    data.frame(x = c(14.0062, 14.0113), y = c(40.8063, 40.8238)) |>
    sf::st_as_sf(coords = c("x", "y"), crs = 4326)

  candidate <-
    data.frame(
      x = c(14.012, 14.030, 14.045, 14.020, 14.040, 14.025, 14.003, 14.048),
      y = c(40.808, 40.822, 40.805, 40.815, 40.825, 40.802, 40.828, 40.828)
    ) |>
    sf::st_as_sf(coords = c("x", "y"), crs = 4326)

  traveltime <-
    facilities |>
    traveltime(bb_area, res_output = 1000, file = file) |>
    suppressMessages()

  list(
    file = file,
    bb_area = bb_area,
    demand = demand,
    weights = weights,
    facilities = facilities,
    candidate = candidate,
    traveltime = traveltime
  )
}

problem <- synthetic_problem()

# Coverage recomputed independently from a travel time raster.
recomputed_coverage <- function(travel_time, demand, objectiveminutes) {
  tt <- raster::values(travel_time)
  d <- raster::values(demand)
  ok <- !is.na(tt) & !is.na(d)

  sum(d[ok & tt <= objectiveminutes]) / sum(d[ok])
}
