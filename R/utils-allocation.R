# Internal engine shared by `allocation()` and `allocation_discrete()`.
#
# All computations are carried out on the grid of the `demand` raster, using
# plain numeric vectors of cell values:
#
# - `domain`: cells inside `bb_area` and within the friction surface extent.
# - `w`: (weighted) demand, `NA` outside the domain.
# - `tt0`: baseline travel time to the existing facilities (`Inf` when there
#   are none), `NA` outside the domain.
# - `reachable`: domain cells with friction data (facilities placed elsewhere
#   cannot reach any other cell).

allocation_setup <- function(
  demand,
  bb_area,
  facilities,
  traveltime,
  mode,
  res_output,
  weights,
  approach,
  exp_demand,
  exp_weights
) {
  if (is.null(traveltime)) {
    cli::cli_alert_info(
      paste0(
        "Travel time layer not detected. ",
        "Running {.strong {cli::col_red('friction()')}} function first."
      )
    )

    friction_data <- friction(
      bb_area = bb_area,
      mode = mode,
      res_output = res_output
    )
  } else {
    friction_data <- traveltime$friction
  }

  friction_layer <- friction_data$friction_layer
  template <- raster::raster(demand)
  router <- routing_graph(friction_data$geocorrection_matrix, template)

  inside_area <- inside_polygon(template, bb_area)

  inside_extent <-
    template |>
    raster::xyFromCell(seq_len(raster::ncell(template))) |>
    in_extent(friction_layer)

  domain <- inside_area & inside_extent

  demand_values <- raster::values(demand)
  demand_values[!inside_area] <- NA

  w <- weighted_demand(
    demand_values,
    template = template,
    weights = weights,
    approach = approach,
    exp_demand = exp_demand,
    exp_weights = exp_weights
  )

  w[!domain] <- NA

  if (any(w < 0, na.rm = TRUE)) {
    cli::cli_abort("{.strong demand} must be non-negative.")
  }

  total <- sum(w, na.rm = TRUE)

  if (!is.finite(total) || total <= 0) {
    cli::cli_abort(
      paste0(
        "The total (weighted) demand within {.strong bb_area} must be ",
        "greater than zero."
      )
    )
  }

  # Baseline travel time, computed from the existing facilities exactly as for
  # new facilities (from the unmasked surface, then aligned to the demand grid).
  # Aligning the masked output of `traveltime()` instead would leave demand
  # cells near the boundary of `bb_area` without a travel time.
  tt0 <- rep(Inf, length(w))

  if (!is.null(facilities)) {
    xy <- points_xy(facilities, within = friction_layer)

    if (nrow(xy) == 0) {
      cli::cli_alert_warning(
        paste0(
          "None of the {.strong facilities} fall within the extent of ",
          "{.strong bb_area}. Allocating facilities from scratch."
        )
      )
    } else {
      tt0 <- travel_time_values(router, xy, demand)
    }
  }

  tt0[!domain] <- NA

  friction_values <- grid_values(friction_layer, demand)

  list(
    template = template,
    w = w,
    total = total,
    tt0 = tt0,
    domain = domain,
    reachable = domain & !is.na(friction_values),
    friction_values = friction_values,
    friction_layer = friction_layer,
    router = router
  )
}

unmet_share <- function(setup, travel_time, objectiveminutes) {
  sum(setup$w[which(travel_time > objectiveminutes)], na.rm = TRUE) /
    setup$total
}

# Abort when the existing facilities already meet the coverage objective.
assert_unmet_objective <- function(
  setup,
  objectiveminutes,
  objectiveshare
) {
  if (is.null(objectiveshare)) {
    return(invisible(TRUE))
  }

  coverage <- 1 - unmet_share(setup, setup$tt0, objectiveminutes)

  if (coverage >= objectiveshare) {
    cli::cli_abort(
      paste0(
        "The initial coverage within ",
        "{.strong {cli::col_yellow(objectiveminutes)}} minutes is ",
        "{.strong {cli::col_red(round(coverage * 100, 5))}}%, ",
        "which meets the ",
        "{.strong {cli::col_blue(objectiveshare * 100)}}% objective share. ",
        "No additional facilities are required. ",
        "Use {.strong traveltime_stats()} ",
        "to review travel time statistics."
      ),
      wrap = TRUE
    )
  }

  invisible(TRUE)
}

# Continuous problem -----

# Lazy greedy heuristic with interchange refinement.
#
# Greedy phase. At each iteration:
#
# 1. A score of the uncovered demand (`heur`) proposes a shortlist of
#    promising locations: the `shortlist` highest local maxima of the score,
#    at least half a catchment radius apart.
# 2. The catchment of each shortlisted location (the demand cells within
#    `objectiveminutes`) is computed with the accumulated cost algorithm and
#    cached. Catchments do not change as facilities are added, so every
#    location evaluated so far remains a candidate at no extra cost.
# 3. The evaluated location that covers the most uncovered demand is added
#    (greedy step of Church & ReVelle, 1974).
#
# Refinement phase (vertex substitution, Teitz & Bart, 1968, with a pattern
# search for new locations). Each facility is in turn removed, new locations
# are evaluated near it given the demand left uncovered, and it is replaced by
# the evaluated location that covers the most uncovered demand if that
# increases the coverage. With a coverage target, the facility covering the
# least demand on its own is then dropped and the solution refined again, as
# long as the target is still met.
allocate_continuous <- function(
  setup,
  objectiveminutes,
  objectiveshare,
  n_fac,
  heur,
  shortlist,
  refine = TRUE,
  max_passes = 8
) {
  total <- setup$total
  tol <- sqrt(.Machine$double.eps) * total

  w <- setup$w
  w[is.na(w)] <- 0
  positive <- which(w > 0)
  baseline <- !is.na(setup$tt0) & setup$tt0 <= objectiveminutes
  base_unmet <- sum(w[!baseline])

  # Demand to be newly covered to reach the target.
  target <- if (is.null(objectiveshare)) {
    Inf
  } else {
    base_unmet - (1 - objectiveshare) * total
  }

  windows <- catchment_windows(setup, objectiveminutes)
  template <- terra::rast(setup$template)

  # State: evaluated locations (cells and catchments), selected locations
  # (indices of evaluated locations), number of selected locations covering
  # each cell, and demand newly covered by the selected locations.
  pool_cells <- integer(0)
  pool_sets <- list()
  pool_steps <- numeric(0)
  selected <- integer(0)
  count <- integer(length(w))
  value <- 0

  uncovered <- function() !baseline & count == 0L

  gain <- function(j, unc) {
    i <- pool_sets[[j]]
    sum(w[i[unc[i]]])
  }

  select <- function(j) {
    i <- pool_sets[[j]]
    count[i] <<- count[i] + 1L
    selected <<- c(selected, j)
  }

  deselect <- function(j) {
    i <- pool_sets[[j]]
    count[i] <<- count[i] - 1L
    selected <<- selected[selected != j]
  }

  # Evaluate new locations: compute and cache their catchments. `step` is the
  # pattern search step used when refining them (see `interchange()`).
  evaluate <- function(cells, step = windows$radius / 2) {
    cells <- setdiff(unique(cells), pool_cells)

    for (cell in cells) {
      travel_time <- travel_time_values(
        setup$router,
        raster::xyFromCell(setup$template, cell),
        setup$template
      )

      pool_cells <<- c(pool_cells, cell)
      pool_steps <<- c(pool_steps, step)
      pool_sets[[length(pool_sets) + 1]] <<-
        positive[which(travel_time[positive] <= objectiveminutes)]
    }

    length(cells)
  }

  # Promising new locations: the highest local maxima of the score of the
  # uncovered demand, optionally within two catchment radii of `near` (x, y).
  shortlist_cells <- function(unc, near = NULL) {
    score <- terra::rast(values_to_raster(ifelse(unc, w, 0), setup$template))

    if (!is.null(near)) {
      half <- 3 * windows$radius
      score <- terra::crop(
        score,
        terra::ext(
          near[1] - half / windows$mx, near[1] + half / windows$mx,
          near[2] - half / windows$my, near[2] + half / windows$my
        ),
        snap = "out"
      )
    }

    if (heur == "kd") {
      score <- terra::focal(
        score,
        w = windows$kernel,
        fun = "sum",
        na.rm = TRUE
      )
    }

    xy <- terra::xyFromCell(score, seq_len(terra::ncell(score)))
    cells <- terra::cellFromXY(template, xy)
    values <- terra::values(score, mat = FALSE)
    values[!setup$reachable[cells]] <- NA
    score <- terra::setValues(score, values)

    local_max <-
      score |>
      terra::focal(w = windows$suppression, fun = "max", na.rm = TRUE) |>
      terra::values(mat = FALSE)

    keep <- which(values > 0 & values >= local_max & !cells %in% pool_cells)

    if (!is.null(near)) {
      distance <- sqrt(
        ((xy[keep, 1] - near[1]) * windows$mx)^2 +
          ((xy[keep, 2] - near[2]) * windows$my)^2
      )

      keep <- keep[distance <= 2 * windows$radius]
    }

    keep <- keep[order(values[keep], decreasing = TRUE)]

    utils::head(cells[keep], shortlist)
  }

  # Pattern search: eight locations at distance `step` (meters) around
  # `near` (x, y).
  ring_cells <- function(near, step) {
    angle <- seq(0, 2 * pi, length.out = 9)[-9]

    cells <- terra::cellFromXY(
      template,
      cbind(
        near[1] + step * cos(angle) / windows$mx,
        near[2] + step * sin(angle) / windows$my
      )
    )

    cells[!is.na(cells) & setup$reachable[cells]]
  }

  # Vertex substitution with pattern search. Each facility is in turn
  # removed and replaced by the evaluated location that covers the most
  # uncovered demand if that increases the coverage. Candidate locations are
  # all the locations evaluated so far, plus new local maxima of the score
  # near the facility and eight locations around it at its pattern search
  # step, which is halved whenever the facility is not moved. Returns whether
  # the solution changed.
  interchange <- function() {
    changed <- FALSE

    for (pass in seq_len(max_passes)) {
      swapped <- FALSE

      for (s in selected) {
        deselect(s)
        unc <- uncovered()
        loss <- gain(s, unc)
        near <- raster::xyFromCell(setup$template, pool_cells[s])

        new_cells <- shortlist_cells(unc, near)

        if (pool_steps[s] >= windows$min_step) {
          new_cells <- c(new_cells, ring_cells(near, pool_steps[s]))
        }

        evaluate(new_cells, step = pool_steps[s])

        candidates <- setdiff(seq_along(pool_sets), c(selected, s))
        gains <- vapply(candidates, gain, numeric(1), unc = unc)

        if (length(gains) > 0 && max(gains) > loss + tol) {
          select(candidates[which.max(gains)])
          value <<- value - loss + max(gains)
          swapped <- TRUE
        } else {
          select(s)
          pool_steps[s] <<- pool_steps[s] / 2
        }
      }

      if (swapped) {
        changed <- TRUE
      } else if (all(pool_steps[selected] < windows$min_step)) {
        break
      }
    }

    changed
  }

  report <- function(prefix) {
    n_selected <- length(selected) #nolint

    cli::cli_alert_info(
      paste0(
        prefix,
        "share of unmet demand: ",
        "{.strong {cli::col_red(round(",
        "(base_unmet - value) / total * 100, 5))}}%."
      )
    )
  }

  # Greedy phase -----

  repeat {
    if (value >= target - tol || length(selected) >= n_fac) break

    unc <- uncovered()
    n_new <- evaluate(shortlist_cells(unc))

    candidates <- setdiff(seq_along(pool_sets), selected)
    gains <- vapply(candidates, gain, numeric(1), unc = unc)

    if (length(gains) == 0 || max(gains) <= tol) {
      if (n_new > 0) next

      cli::cli_alert_warning(
        paste0(
          "No further location can increase the coverage. ",
          "Stopping the allocation."
        )
      )

      break
    }

    select(candidates[which.max(gains)])
    value <- value + max(gains)
    report("Facility {.strong {cli::col_yellow(n_selected)}}: ")
  }

  # Refinement phase -----

  if (isTRUE(refine) && length(selected) > 0) {
    reached <- value >= target - tol
    changed <- interchange()

    if (is.finite(target) && reached) {
      while (length(selected) > 1) {
        unique_cover <- vapply(
          selected,
          function(s) {
            i <- pool_sets[[s]]
            sum(w[i[count[i] == 1L & !baseline[i]]])
          },
          numeric(1)
        )

        saved <- list(selected = selected, count = count, value = value)
        drop <- which.min(unique_cover)
        deselect(selected[drop])
        value <- value - unique_cover[drop]
        interchange()

        if (value >= target - tol) {
          changed <- TRUE
        } else {
          selected <- saved$selected
          count <- saved$count
          value <- saved$value

          break
        }
      }
    }

    if (isTRUE(changed)) {
      report(
        paste0(
          "Interchange refinement: ",
          "{.strong {cli::col_yellow(n_selected)}} ",
          "{cli::qty(n_selected)}facilit{?y/ies}, "
        )
      )
    }
  }

  new_cells <- pool_cells[selected]
  new_xy <- raster::xyFromCell(setup$template, new_cells)
  colnames(new_xy) <- c("x", "y")
  travel_time <- setup$tt0

  if (length(new_cells) > 0) {
    travel_time <- pmin(
      travel_time,
      travel_time_values(setup$router, new_xy, setup$template)
    )
  }

  list(
    xy = new_xy,
    travel_time = travel_time,
    unmet = unmet_share(setup, travel_time, objectiveminutes)
  )
}

# Moving windows sized on the catchment radius: the distance that can be
# traveled within `objectiveminutes` at the median friction of the study
# area.
#
# - `kernel`: quartic kernel with a bandwidth equal to the catchment radius.
#   The focal sum of the uncovered demand with this kernel approximates the
#   uncovered demand within the catchment of a facility placed at each cell.
# - `suppression`: disc of half the catchment radius, used to find local
#   maxima of the score.
# - `radius`: the catchment radius (meters); `min_step`: the size of a cell
#   (meters); `mx`, `my`: meters per degree of longitude and latitude.
catchment_windows <- function(setup, objectiveminutes) {
  friction <- setup$friction_values[setup$domain]
  friction <- friction[is.finite(friction) & friction > 0]
  radius <- objectiveminutes / stats::median(friction) # meters

  res <- raster::res(setup$template)
  lat <- mean(c(raster::ymin(setup$template), raster::ymax(setup$template)))
  dx <- res[1] * 111320 * cos(lat * pi / 180)
  dy <- res[2] * 110574

  window <- function(r) {
    nx <- max(1, floor(r / dx))
    ny <- max(1, floor(r / dy))

    d2 <-
      outer((-ny:ny) * dy, rep(1, 2 * nx + 1))^2 +
      outer(rep(1, 2 * ny + 1), (-nx:nx) * dx)^2

    d2 / r^2
  }

  kernel <- window(radius)
  suppression <- window(radius / 2)

  list(
    kernel = ifelse(kernel < 1, (1 - kernel)^2, 0),
    suppression = ifelse(suppression <= 1, 1, NA),
    radius = radius,
    min_step = min(dx, dy),
    mx = dx / res[1],
    my = dy / res[2]
  )
}

# Discrete problem -----

allocate_discrete <- function(
  setup,
  candidate,
  objectiveminutes,
  objectiveshare,
  n_fac,
  par
) {
  candidate_xy <- points_xy(candidate)
  usable <- in_extent(candidate_xy, setup$friction_layer)

  if (!any(usable)) {
    cli::cli_abort(
      paste0(
        "None of the {.strong candidate} locations fall within the extent ",
        "of {.strong bb_area}."
      )
    )
  } else if (!all(usable)) {
    cli::cli_alert_warning(
      paste0(
        "{.strong {sum(!usable)}} candidate location{?s} outside the extent ",
        "of {.strong bb_area} {?was/were} discarded."
      )
    )
  }

  usable <- which(usable)
  n_fac <- min(n_fac, length(usable))

  # Cells with positive demand not covered by the existing facilities.
  uncovered <- which(setup$w > 0 & setup$tt0 > objectiveminutes)

  cover <- coverage_sets(
    setup = setup,
    xy = candidate_xy[usable, , drop = FALSE],
    cells = uncovered,
    objectiveminutes = objectiveminutes,
    par = par
  )

  base_unmet <- unmet_share(setup, setup$tt0, objectiveminutes)

  target <- if (is.null(objectiveshare)) {
    Inf
  } else {
    (base_unmet - (1 - objectiveshare)) * setup$total
  }

  solution <- mclp_solve(
    cover = cover,
    w = setup$w[uncovered],
    n_max = n_fac,
    target = target,
    total = setup$total,
    base_unmet = base_unmet
  )

  selected <- usable[solution$selected]
  travel_time <- setup$tt0

  if (length(selected) > 0) {
    travel_time <- pmin(
      travel_time,
      travel_time_values(
        setup$router,
        candidate_xy[selected, , drop = FALSE],
        setup$template
      )
    )
  }

  list(
    selected = selected,
    travel_time = travel_time,
    unmet = unmet_share(setup, travel_time, objectiveminutes)
  )
}

# For each candidate location, the indices (in `cells`) of the cells it covers
# within `objectiveminutes`. Since the travel time from a set of locations is
# the minimum of the travel times from each location, these sets fully
# determine the coverage of any combination of candidates.
coverage_sets <- function(setup, xy, cells, objectiveminutes, par = FALSE) {
  n <- nrow(xy)
  cores <- min(n, max(1, parallel::detectCores() - 1, na.rm = TRUE))

  args <- list(
    router = setup$router,
    template = setup$template,
    xy = xy,
    cells = cells,
    objectiveminutes = objectiveminutes
  )

  if (isTRUE(par) && cores > 1) {
    cli::cli_progress_step(
      "Computing travel times from {n} candidate locations ({cores} cores)"
    )

    if (.Platform$OS.type == "unix") {
      out <- do.call(
        parallel::mclapply,
        c(list(seq_len(n), coverage_set, mc.cores = cores), args)
      )
    } else {
      cl <- parallel::makeCluster(cores)
      on.exit(parallel::stopCluster(cl), add = TRUE)

      parallel::clusterEvalQ(cl, {
        loadNamespace("raster")
        loadNamespace("gdistance")
        loadNamespace("terra")
        loadNamespace("locationallocation")
      })

      out <- do.call(
        parallel::parLapply,
        c(list(cl, seq_len(n), coverage_set), args)
      )
    }

    cli::cli_progress_done()
  } else {
    out <- do.call(
      lapply,
      c(
        list(
          cli::cli_progress_along(
            seq_len(n),
            "Computing travel times from candidate locations"
          ),
          coverage_set
        ),
        args
      )
    )
  }

  out
}

coverage_set <- function(j, router, template, xy, cells, objectiveminutes) {
  travel_time <- travel_time_values(
    router,
    xy[j, , drop = FALSE],
    template
  )

  which(travel_time[cells] <= objectiveminutes)
}

# Greedy heuristic (Church & ReVelle, 1974) with vertex substitution
# (interchange) refinement (Teitz & Bart, 1968) for the maximal covering
# location problem.
#
# - `cover`: list with, for each candidate, the indices of the cells it covers.
# - `w`: demand of each cell.
# - `n_max`: maximum number of candidates to select.
# - `target`: demand to be covered; selection stops as soon as it is reached
#   (`Inf` to select exactly `n_max` candidates, if they increase coverage).
mclp_solve <- function(
  cover,
  w,
  n_max,
  target = Inf,
  total = sum(w),
  base_unmet = 1
) {
  n_cand <- length(cover)
  tol <- sqrt(.Machine$double.eps) * max(sum(w), 1)
  count <- integer(length(w))
  mark <- numeric(length(w))
  selected <- integer(0)
  value <- 0

  gain <- function(j) {
    i <- cover[[j]]
    sum(w[i[count[i] == 0L]])
  }

  add <- function(j) {
    i <- cover[[j]]
    count[i] <<- count[i] + 1L
  }

  remove <- function(j) {
    i <- cover[[j]]
    count[i] <<- count[i] - 1L
  }

  report <- function(prefix) {
    cli::cli_alert_info(
      paste0(
        prefix,
        "share of unmet demand: ",
        "{.strong {cli::col_red(round(",
        "(base_unmet - value / total) * 100, 5))}}%."
      ),
      .envir = environment()
    )
  }

  interchange <- function() {
    improved <- FALSE

    repeat {
      pool <- setdiff(seq_len(n_cand), selected)
      if (length(pool) == 0 || length(selected) == 0) break

      pool_gain <- vapply(pool, gain, numeric(1))
      best <- list(delta = tol, out = NA_integer_, into = NA_integer_)

      for (s in selected) {
        i <- cover[[s]]
        lost <- i[count[i] == 1L]
        loss <- sum(w[lost])

        # Demand that becomes available again if `s` is removed.
        mark[lost] <<- w[lost]
        extra <- vapply(pool, \(j) sum(mark[cover[[j]]]), numeric(1))
        mark[lost] <<- 0

        delta <- pool_gain + extra - loss
        k <- which.max(delta)

        if (delta[k] > best$delta) {
          best <- list(delta = delta[k], out = s, into = pool[k])
        }
      }

      if (is.na(best$out)) break

      remove(best$out)
      add(best$into)
      selected[selected == best$out] <<- best$into
      value <<- value + best$delta
      improved <- TRUE
    }

    if (isTRUE(improved)) report("Interchange refinement: ")
  }

  repeat {
    if (length(selected) >= n_max || value >= target - tol) break

    pool <- setdiff(seq_len(n_cand), selected)
    if (length(pool) == 0) break

    pool_gain <- vapply(pool, gain, numeric(1))

    if (max(pool_gain) <= tol) {
      cli::cli_alert_warning(
        paste0(
          "No further candidate location can increase the coverage. ",
          "Stopping the allocation."
        )
      )

      break
    }

    best <- pool[which.max(pool_gain)]
    add(best)
    selected <- c(selected, best)
    value <- value + max(pool_gain)

    report(
      paste0(
        "Facility {.strong {cli::col_yellow(length(selected))}}: "
      )
    )

    if (is.finite(target) && value < target - tol) interchange()
  }

  if (!is.finite(target)) interchange()

  list(selected = selected, value = sum(w[count > 0L]))
}
