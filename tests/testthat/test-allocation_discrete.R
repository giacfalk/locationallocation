run_discrete <- function(...) {
  args <- list(
    demand = problem$demand,
    bb_area = problem$bb_area,
    candidate = problem$candidate,
    facilities = problem$facilities,
    traveltime = problem$traveltime,
    objectiveminutes = 5
  )
  args[names(list(...))] <- list(...)

  suppressMessages(do.call(allocation_discrete, args))
}

# Coverage of every combination of `k` candidates, computed independently
# with one accumulated cost run per combination.
brute_force <- function(k) {
  transition <- problem$traveltime$friction$geocorrection_matrix
  xy <- sf::st_coordinates(problem$candidate)
  existing <- sf::st_coordinates(problem$facilities)

  combos <- utils::combn(nrow(xy), k, simplify = FALSE)

  vapply(
    combos,
    function(i) {
      gdistance::accCost(transition, rbind(existing, xy[i, , drop = FALSE])) |>
        mask_raster_to_polygon(problem$bb_area) |>
        raster::resample(problem$demand, method = "ngb") |>
        recomputed_coverage(problem$demand, 5)
    },
    numeric(1)
  )
}

test_that("allocation_discrete() is exported", {
  expect_true(
    "allocation_discrete" %in% getNamespaceExports("locationallocation")
  )
})

test_that("allocation_discrete() finds the optimal set on a small problem", {
  for (k in 1:3) {
    out <- run_discrete(n_fac = k)

    expect_s3_class(out, "allocation_discrete")
    expect_equal(nrow(out$facilities), k)
    expect_equal(out$coverage, max(brute_force(k)), tolerance = 1e-10)
    expect_equal(
      out$coverage,
      recomputed_coverage(out$travel_time, problem$demand, 5)
    )
  }
})

test_that("allocation_discrete() returns rows of `candidate`", {
  candidate <- problem$candidate
  candidate$id <- letters[seq_len(nrow(candidate))]

  out <- run_discrete(candidate = candidate, n_fac = 2)

  expect_true(all(out$facilities$id %in% candidate$id))
  expect_equal(anyDuplicated(out$facilities$id), 0)
})

test_that("allocation_discrete() handles the objective share", {
  out <- run_discrete(objectiveshare = 0.4)

  expect_gte(out$coverage, 0.4)

  # The target cannot be reached with fewer facilities.
  fewer <- nrow(out$facilities) - 1

  if (fewer > 0) {
    expect_lt(max(brute_force(fewer)), 0.4)
  }

  # Unattainable target: all useful candidates are selected.
  unattainable <- run_discrete(objectiveshare = 0.9)

  expect_lt(unattainable$coverage, 0.9)
  expect_equal(unattainable$coverage, run_discrete()$coverage)

  capped <- run_discrete(objectiveshare = 0.99, n_fac = 2)

  expect_equal(nrow(capped$facilities), 2)
  expect_lt(capped$coverage, 0.99)
})

test_that("allocation_discrete() works with default and large n_fac", {
  all <- run_discrete()
  many <- run_discrete(n_fac = 100)

  expect_lte(nrow(all$facilities), nrow(problem$candidate))
  expect_equal(all$coverage, many$coverage)
})

test_that("allocation_discrete() works without existing facilities", {
  out <- run_discrete(facilities = NULL, n_fac = 3)

  expect_equal(nrow(out$facilities), 3)
  expect_lt(out$coverage, run_discrete(n_fac = 3)$coverage)
})

test_that("allocation_discrete() accepts sfc candidates", {
  out <- run_discrete(
    candidate = sf::st_geometry(problem$candidate),
    n_fac = 2
  )

  expect_equal(nrow(out$facilities), 2)
})

test_that("allocation_discrete() deprecates n_samples", {
  expect_warning(run_discrete(n_fac = 1, n_samples = 10), "deprecated")
})

test_that("allocation_discrete() discards candidates outside the area", {
  far <- rbind(
    problem$candidate,
    sf::st_as_sf(data.frame(x = 10, y = 45), coords = 1:2, crs = 4326)
  )

  expect_message(
    allocation_discrete(
      problem$demand,
      problem$bb_area,
      candidate = far,
      facilities = problem$facilities,
      traveltime = problem$traveltime,
      n_fac = 1,
      objectiveminutes = 5
    ),
    "discarded"
  )
})
