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

test_that("friction() validates its inputs", {
  expect_error(friction(problem$facilities, file = problem$file))
  expect_error(friction(problem$bb_area, mode = "car", file = problem$file))
  expect_error(friction(problem$bb_area, res_output = 0, file = problem$file))
  expect_error(friction(problem$bb_area, file = "does-not-exist.tif"))
})
