test_that("mask_raster_to_polygon() masks to a polygon", {
  inner <- sf::st_buffer(sf::st_centroid(problem$bb_area), 1000)
  masked <- mask_raster_to_polygon(problem$demand, inner)

  expect_s4_class(masked, "RasterLayer")
  expect_true(anyNA(raster::values(masked)))
  expect_false(all(is.na(raster::values(masked))))

  inverse <- mask_raster_to_polygon(problem$demand, inner, inverse = TRUE)

  expect_equal(
    is.na(raster::values(inverse)),
    !is.na(raster::values(masked))
  )

  updated <- mask_raster_to_polygon(problem$demand, inner, updatevalue = -1)

  expect_true(any(raster::values(updated) == -1))
})

test_that("mask_raster_to_polygon() handles CRSs, rasters and SpatRasters", {
  inner <- sf::st_buffer(sf::st_centroid(problem$bb_area), 1000)
  masked <- mask_raster_to_polygon(problem$demand, inner)

  expect_equal(
    raster::values(
      mask_raster_to_polygon(problem$demand, sf::st_transform(inner, 3857))
    ),
    raster::values(masked)
  )

  expect_equal(
    raster::values(mask_raster_to_polygon(problem$demand, masked)),
    raster::values(masked)
  )

  out <- mask_raster_to_polygon(terra::rast(problem$demand), inner)

  expect_s4_class(out, "SpatRaster")
  expect_equal(terra::values(out, mat = FALSE), raster::values(masked))

  expect_error(mask_raster_to_polygon(problem$demand, problem$facilities))
})
