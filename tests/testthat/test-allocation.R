run_allocation <- function(...) {
  args <- list(
    demand = problem$demand,
    bb_area = problem$bb_area,
    facilities = problem$facilities,
    traveltime = problem$traveltime,
    objectiveminutes = 5,
    objectiveshare = 0.8
  )
  args[names(list(...))] <- list(...)

  suppressMessages(do.call(allocation, args))
}

test_that("allocation() reaches the objective share", {
  out <- run_allocation()

  expect_s3_class(out, "allocation")
  expect_s3_class(out$facilities, "sf")
  expect_gt(nrow(out$facilities), 0)
  expect_gte(out$coverage, 0.8)
  expect_equal(out$unmet_demand, 1 - out$coverage)

  # The travel time map is on the grid of `demand` and reproduces the coverage.
  expect_true(raster::compareRaster(out$travel_time, problem$demand))
  expect_equal(
    out$coverage,
    recomputed_coverage(out$travel_time, problem$demand, 5)
  )

  # Each new facility is reached in (almost) no time.
  at_new <- raster::extract(
    out$travel_time,
    sf::st_coordinates(out$facilities)
  )

  expect_true(all(at_new < 1))
})

test_that("allocation() respects n_fac and supports a fixed number", {
  capped <- run_allocation(objectiveshare = 0.99, n_fac = 2)

  expect_equal(nrow(capped$facilities), 2)
  expect_lt(capped$coverage, 0.99)

  fixed <- run_allocation(objectiveshare = NULL, n_fac = 3)

  expect_equal(nrow(fixed$facilities), 3)
  expect_null(fixed$objective_share)

  expect_error(run_allocation(objectiveshare = NULL), "n_fac")
  expect_error(run_allocation(n_fac = 0))
})

test_that("allocation() supports both heuristics and shortlist sizes", {
  for (heur in c("kd", "max")) {
    for (shortlist in c(1, 10)) {
      out <- run_allocation(heur = heur, shortlist = shortlist)

      expect_gte(out$coverage, 0.8)
      expect_equal(
        out$coverage,
        recomputed_coverage(out$travel_time, problem$demand, 5)
      )
    }
  }

  expect_error(run_allocation(shortlist = 0))
})

test_that("refinement never worsens the greedy solution", {
  greedy <- run_allocation(objectiveshare = NULL, n_fac = 4, refine = FALSE)
  refined <- run_allocation(objectiveshare = NULL, n_fac = 4)

  expect_equal(nrow(refined$facilities), 4)
  expect_gte(refined$coverage, greedy$coverage)

  greedy <- run_allocation(refine = FALSE)
  refined <- run_allocation()

  expect_gte(refined$coverage, 0.8)
  expect_lte(nrow(refined$facilities), nrow(greedy$facilities))

  expect_error(run_allocation(refine = NA))
})

test_that("allocation() is close to the optimum over a dense candidate set", {
  # Near-optimal reference: the discrete solver with every other cell of the
  # demand grid as a candidate location.
  cells <- raster::xyFromCell(
    problem$demand,
    seq(1, raster::ncell(problem$demand), by = 2)
  )

  reference <- suppressMessages(
    allocation_discrete(
      problem$demand,
      problem$bb_area,
      candidate = sf::st_as_sf(as.data.frame(cells), coords = 1:2, crs = 4326),
      facilities = problem$facilities,
      traveltime = problem$traveltime,
      n_fac = 3,
      objectiveminutes = 5
    )
  )

  out <- run_allocation(objectiveshare = NULL, n_fac = 3)

  expect_gte(out$coverage, 0.98 * reference$coverage)
})

test_that("allocation() works without existing facilities", {
  out <- run_allocation(facilities = NULL)

  expect_gte(out$coverage, 0.8)
  expect_gt(
    nrow(out$facilities),
    nrow(run_allocation()$facilities)
  )
})

test_that("allocation() handles weights", {
  norm <- run_allocation(weights = problem$weights, approach = "norm")
  abs <- run_allocation(weights = problem$weights, approach = "absweights")

  expect_gte(norm$coverage, 0.8)
  expect_gte(abs$coverage, 0.8)

  negative <- problem$weights - 100

  expect_error(
    run_allocation(weights = negative, approach = "absweights"),
    "non-negative"
  )

  # Weights on another grid are resampled to the demand grid.
  coarse <- raster::aggregate(problem$weights, 2)

  expect_gte(run_allocation(weights = coarse)$coverage, 0.8)
})

test_that("allocation() stops when the target cannot be attained", {
  # People living on the lake can never be covered.
  out <- run_allocation(objectiveshare = 1)

  expect_lt(out$coverage, 1)
  expect_equal(
    out$coverage,
    recomputed_coverage(out$travel_time, problem$demand, 5)
  )
})

test_that("allocation() aborts when the objective is already met", {
  expect_error(run_allocation(objectiveshare = 0.01), "No additional")
})

test_that("allocation() validates its inputs", {
  expect_error(run_allocation(demand = problem$facilities))
  expect_error(run_allocation(heur = "random"))
  expect_error(run_allocation(objectiveshare = 2))
  expect_error(run_allocation(traveltime = list()))
})
