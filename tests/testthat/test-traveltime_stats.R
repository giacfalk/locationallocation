test_that("traveltime_stats() computes coverage correctly", {
  stats <- traveltime_stats(
    problem$traveltime,
    problem$demand,
    objectiveminutes = 5,
    print = FALSE
  )

  aligned <- raster::resample(
    problem$traveltime$travel_time,
    problem$demand,
    method = "ngb"
  )

  expect_equal(
    stats$coverage,
    recomputed_coverage(aligned, problem$demand, 5)
  )
  expect_equal(stats$unmet_demand, 1 - stats$coverage)
  expect_true(stats$coverage > 0 && stats$coverage < 1)
  expect_s3_class(stats$data, "tbl_df")
  expect_false(is.unsorted(stats$data$traveltime_values))
  expect_equal(max(stats$data$cumulative_coverage), 100)
  expect_s3_class(stats$plot, "ggplot")
})

test_that("traveltime_stats() accepts SpatRaster and checks inputs", {
  from_terra <- traveltime_stats(
    problem$traveltime,
    terra::rast(problem$demand),
    objectiveminutes = 5,
    print = FALSE
  )

  from_raster <- traveltime_stats(
    problem$traveltime,
    problem$demand,
    objectiveminutes = 5,
    print = FALSE
  )

  expect_equal(from_terra$coverage, from_raster$coverage)

  expect_error(
    traveltime_stats(problem$traveltime, problem$demand, breaks = c(10, 5))
  )
  expect_error(
    traveltime_stats(
      problem$traveltime,
      raster::projectRaster(problem$demand, crs = "EPSG:32633")
    ),
    "geographic"
  )
})
