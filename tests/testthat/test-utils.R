test_that("mclp_solve() finds the optimum of a toy problem", {
  # Greedy picks candidate 1 (4 units), then can only add 1 more unit (5);
  # the optimum is {2, 3}, covering all 6 units. Interchange recovers it.
  cover <- list(1:4, c(1, 2, 5), c(3, 4, 6))
  w <- c(1, 1, 1, 1, 1, 1)

  out <- suppressMessages(mclp_solve(cover, w, n_max = 2))

  expect_setequal(out$selected, c(2, 3))
  expect_equal(out$value, 6)

  # With a target, stop as soon as it is reached.
  one <- suppressMessages(mclp_solve(cover, w, n_max = 3, target = 4))

  expect_equal(one$selected, 1)

  two <- suppressMessages(mclp_solve(cover, w, n_max = 3, target = 6))

  expect_setequal(two$selected, c(2, 3))
})

test_that("normalize_raster() handles constant layers", {
  constant <- raster::setValues(problem$demand, 5)

  expect_equal(unique(raster::values(normalize_raster(constant))), 1)

  normalized <- normalize_raster(problem$demand)

  expect_equal(range(raster::values(normalized)), c(0, 1))
})

test_that("input checks work", {
  expect_error(assert_bb_area(problem$facilities))
  expect_error(assert_facilities(problem$bb_area))
  expect_error(assert_traveltime(list()))
  expect_error(as_raster_layer(c(1, 2)))
  expect_s4_class(as_raster_layer(terra::rast(problem$demand)), "RasterLayer")
  expect_equal(
    sf::st_crs(as_wgs84(sf::st_transform(problem$bb_area, 3857))),
    sf::st_crs(4326)
  )
})
