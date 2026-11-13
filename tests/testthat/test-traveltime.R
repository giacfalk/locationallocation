test_that("traveltime() returns a travel time map", {
  tt <- problem$traveltime

  expect_s3_class(tt, "traveltime")
  expect_s4_class(tt$travel_time, "RasterLayer")
  expect_named(tt$travel_time, "travel_time")

  values <- raster::values(tt$travel_time)
  at_facilities <- raster::extract(
    tt$travel_time,
    sf::st_coordinates(problem$facilities)
  )

  expect_true(all(at_facilities < 1))
  expect_true(all(values >= 0, na.rm = TRUE))

  # Cells without friction data (the lake) cannot be reached.
  expect_true(any(is.infinite(values)))
})

test_that("traveltime() is consistent with walking at 5 km/h", {
  tt <- problem$traveltime$travel_time
  point <- cbind(14.025, 40.815)
  travel_time <- raster::extract(tt, point)

  distance <- min(
    sf::st_distance(
      sf::st_as_sf(
        data.frame(x = 14.025, y = 40.815),
        coords = 1:2,
        crs = 4326
      ),
      problem$facilities
    )
  ) |>
    as.numeric()

  # Straight-line distance at 5 km/h is a lower bound; the 16-direction
  # raster path can only be slightly longer.
  expect_gt(travel_time, distance * 0.012 * 0.95)
  expect_lt(travel_time, distance * 0.012 * 1.15)
})

test_that("traveltime() handles projected inputs and missing facilities", {
  projected <- traveltime(
    sf::st_transform(problem$facilities, 32633),
    sf::st_transform(problem$bb_area, 32633),
    res_output = 1000,
    file = problem$file
  ) |>
    suppressMessages()

  expect_equal(
    raster::values(projected$travel_time),
    raster::values(problem$traveltime$travel_time)
  )

  far_away <- sf::st_as_sf(
    data.frame(x = 10, y = 45),
    coords = c("x", "y"),
    crs = 4326
  )

  expect_error(
    traveltime(far_away, problem$bb_area, res_output = 1000,
               file = problem$file) |>
      suppressMessages(),
    "None of the"
  )
})

test_that("print.traveltime() works", {
  expect_no_error(utils::capture.output(print(problem$traveltime)))
})
