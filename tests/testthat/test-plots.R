test_that("traveltime_plot() returns a ggplot", {
  plot <- traveltime_plot(
    problem$traveltime,
    problem$bb_area,
    facilities = problem$facilities,
    contour_traveltime = c(5, 10, 1000)
  )

  expect_s3_class(plot, "ggplot")
  expect_no_error(ggplot2::ggplot_build(plot))

  without <- traveltime_plot(
    problem$traveltime,
    problem$bb_area,
    contour_traveltime = NULL,
    annotation_scale = FALSE,
    annotation_north_arrow = FALSE
  )

  expect_s3_class(without, "ggplot")
  expect_no_error(ggplot2::ggplot_build(without))
})

test_that("allocation_plot() returns a ggplot", {
  out <- suppressMessages(
    allocation_discrete(
      problem$demand,
      problem$bb_area,
      candidate = problem$candidate,
      facilities = problem$facilities,
      traveltime = problem$traveltime,
      n_fac = 2,
      objectiveminutes = 5
    )
  )

  plot <- allocation_plot(
    out,
    problem$bb_area,
    facilities = problem$facilities
  )

  expect_s3_class(plot, "ggplot")
  expect_no_error(ggplot2::ggplot_build(plot))
  expect_error(allocation_plot(problem$traveltime, problem$bb_area))
})

test_that("print methods work", {
  out <- suppressMessages(
    allocation_discrete(
      problem$demand,
      problem$bb_area,
      candidate = problem$candidate,
      n_fac = 1,
      traveltime = problem$traveltime,
      objectiveminutes = 5
    )
  )

  expect_no_error(utils::capture.output(print(out), type = "message"))
})
