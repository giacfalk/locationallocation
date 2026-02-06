#' Compute the maximal coverage location-allocation for continuous and discrete problems
#'
#' @description
#'
#' `allocation()` allocate facilities in a continuous location problem. It uses
#' the accumulated cost algorithm to find the optimal location for the
#' facilities based on the share of the demand to be covered.
#'
#' #' `allocation_discrete()` allocates facilities in a discrete location problem.
#' It uses the accumulated cost algorithm to identify optimal facility locations
#' based on the share of demand to be covered, given a user-defined set
#' of candidate locations and a maximum number of allocable facilities.
#'
#' In `allocation_discrete()`, if a `objectiveshare` parameter is specified, the algorithm identifies the
#' best set of size of up to `n_fac` facilities to achieve the targeted coverage
#' share. The problem is solved using a statistical heuristic approach that
#' generates samples of the candidate locations (on top of the existing
#' locations) and selects the facilities in the one that minimizes the objective
#' function.
#'
#' @template params-demand
#' @template params-bb-area
#' @template params-facilities
#' @template params-traveltime-b
#' @param weights (optional) A `stars` layer with the weights for the demand (default:
#' `NULL`).
#' @template params-objectiveminutes
#' @template params-objectiveshare-a
#' @param heur (optional) The heuristic approach to be used. Options are `"max"`
#'   and `"kd"` (default: `"max"`).
#' @param approach (optional) The approach to be used for the allocation.
#'   Options are `"norm"` and `"absweights"`. If "norm", the allocation is based
#'   on the normalized demand layer multiplied by the normalized weights
#'   layer. If `"absweights"`, the allocation is based on the normalized demand
#'   layer multiplied by the raw weights layer (default: `"norm"`).
#' @param exp_demand (optional) The exponent for the demand layer. Default is
#'   1. A higher value will give less relative weight to areas with higher
#'   demand - with respect to the weights layer. This is useful in cases where
#'   the users want to increase the allocation in areas with higher values in
#'   the weights layer (default: `1`).
#' @param exp_weights (optional) The exponent for the weights layer. Default is
#'   1. A higher value will give less relative weight to areas with higher
#'   weights - with respect to the demand layer. This is useful in cases where
#'   the users want to increase the allocation in areas with higher values in
#'   the demand layer (default: `1`).
#'
#' When using `allocation_discrete()`:
#'
#' @param candidate A [`sf`][sf::st_as_sf()] object with the candidate
#'   locations for the new facilities.
#' @param n_fac (optional) A positive [integerish][checkmate::test_integerish()]
#'   number indicating the maximum number of facilities that can be allocated
#'   (default: `Inf`).
#' @param n_samples (optional) A positive
#'   [integerish][checkmate::test_integerish()] number indicating the number of
#'   samples to generate in the heuristic approach for identifying the best set
#'   of facilities to be allocated (default: `1000`).
#' @template params-objectiveshare-b
#' @param par (optional) A [`logical`][base::logical()] flag indicating whether
#'   to run the function in [parallel][parallel::parLapply()] or not
#'   (default: `FALSE`).
#'
#' @inheritParams friction
#'
#' @return An [invisible][base::invisible] [`list`][base::list] with the
#'   following elements:
#'   - `coverage`: A [`numeric`][base::numeric()] value indicating the share of
#'   demand covered within the objective travel time after allocating the new
#'   facilities.
#'   - `unmet_demand`: A [`numeric`][base::numeric()] value indicating the share
#'   of demand that remains unmet after allocating the new facilities.
#'   - `objective_minutes`: The value of the `objectiveminutes` parameter used.
#'   - `objective_share`: The value of the `objectiveshare` parameter used.
#'   - `facilities`: A [`sf`][sf::sf()] object with the newly allocated
#'   facilities.
#'   - `travel_time`: A [`stars`][stars::st_as_stars()] object
#'   representing the travel time map with the newly allocated facilities.
#'
#' @family location-allocation functions
#' @keywords location-allocation
#' @export
#'
#' @examples
#' \dontrun{
#'   library(dplyr)
#'
#'   allocation_data <-
#'     naples_population |>
#'     allocation(
#'       bb_area = naples_shape,
#'       facilities = naples_fountains,
#'       weights = naples_hot_days,
#'       objectiveminutes = 15,
#'       objectiveshare = 0.99
#'     )
#'
#'   allocation_data |> glimpse()
#'
#'   allocation_data |> allocation_plot(naples_shape)
#' }
#'
#' \dontrun{
#'   library(dplyr)
#'   library(sf)
#'
#'   allocation_data <-
#'     naples_population |>
#'     allocation_discrete(
#'       traveltime = traveltime,
#'       bb_area = naples_shape,
#'       facilities = naples_fountains,
#'       candidate = naples_shape |> st_sample(20),
#'       n_fac = 2,
#'       weights = naples_hot_days,
#'       objectiveminutes = 15,
#'       objectiveshare = 0.9
#'     )
#'
#'   allocation_data |> glimpse()
#'
#'   allocation_data |> allocation_plot(naples_shape)
#' }
#'
# Helper function: Apply demand transformations based on weights and approach
apply_demand_transformation <- function(demand, weights, approach, exp_demand, exp_weights, bb_area) {
  if (is.null(weights)) {
    return(demand |> magrittr::raise_to_power(exp_demand))
  }

  weights <- weights |> mask_raster_to_polygon(bb_area)
  normalized_demand <- demand |>
    normalize_raster() |>
    magrittr::raise_to_power(exp_demand)

  if (approach == "norm") {
    return(normalized_demand |>
             magrittr::multiply_by(
               weights |>
                 normalize_raster() |>
                 magrittr::raise_to_power(exp_weights)
             ))
  }

  # approach == "absweights"
  normalized_demand |>
    magrittr::multiply_by(
      weights |>
        magrittr::raise_to_power(exp_weights)
    )
}

# Helper function: Find next facility location based on heuristic
find_next_facility <- function(demand, heur, all_prev = NULL) {
  if (heur == "kd") {
    cli::cli_warn(
      "Kernel density heuristic is not available for stars objects; ",
      "falling back to the max-demand heuristic."
    )
  }

  which.max(stars_values(demand))
}

# Helper function: Initialize or accumulate new facilities
accumulate_facility <- function(new_facilities, pos) {
  new_sf <- pos |>
    sf::st_as_sf(coords = c("x", "y"), crs = 4326)

  if (is.null(new_facilities)) {
    return(new_sf)
  }

  rbind(new_facilities, new_sf)
}

# Helper function: Apply travel time mask to demand
mask_demand_by_traveltime <- function(demand, traveltime, objectiveminutes) {
  demand <- as_stars_raster(demand)
  traveltime <- as_stars_raster(traveltime)

  traveltime_values <- stars_values(traveltime)
  demand_values <- stars_values(demand)
  demand_values[traveltime_values <= objectiveminutes] <- NA

  stars_set_values(demand, demand_values)
}

allocation <- function(
    demand,
    bb_area,
    facilities,
    traveltime = NULL,
    mode = "walk",
    dowscaling_model_type = "lm",
    res_output = 100,
    weights = NULL,
    objectiveminutes = 15,
    objectiveshare = 0.99,
    heur = "max",
    approach = "norm",
    exp_demand = 1,
    exp_weights = 1
) {
  checkmate::assert_class(demand, "stars")
  assert_bb_area(bb_area)
  assert_facilities(facilities)
  assert_traveltime(traveltime, null_ok = TRUE)
  checkmate::assert_choice(mode, choices = c("walk", "fastest"))
  checkmate::assert_choice(dowscaling_model_type, choices = c("lm", "rf"))
  checkmate::assert_count(res_output, positive = TRUE)
  checkmate::assert_class(weights, "stars", null.ok = TRUE)
  checkmate::assert_number(objectiveminutes, lower = 0)
  checkmate::assert_number(objectiveshare, lower = 0, upper = 1)
  checkmate::assert_choice(heur, choices = c("max", "kd"))
  checkmate::assert_choice(approach, choices = c("norm", "absweights"))
  checkmate::assert_number(exp_demand, lower = 0)
  checkmate::assert_number(exp_weights, lower = 0)

  sf::sf_use_s2(TRUE)

  if (is.null(traveltime)) {
    cli::cli_alert_info(
      paste0(
        "Travel time layer not detected. ",
        "Running {.strong {cli::col_red('traveltime()')}} function first."
      )
    )

    traveltime <- traveltime(
      facilities = facilities,
      bb_area = bb_area,
      mode = mode,
      dowscaling_model_type = dowscaling_model_type,
      res_output = res_output
    )
  }

  assert_minimal_coverage(
    traveltime = traveltime,
    demand = demand,
    objectiveminutes = objectiveminutes,
    objectiveshare = objectiveshare
  )

  traveltime_raster_outer <- traveltime
  demand <- demand |> mask_raster_to_polygon(bb_area)

  traveltime <-
    traveltime_raster_outer[[1]] |>
    mask_raster_to_polygon(bb_area)

  sf::st_crs(traveltime) <- sf::st_crs(4326)
  traveltime <- stars::st_warp(traveltime, demand)
  sf::st_crs(traveltime) <- sf::st_crs(4326)

  # Apply demand transformation using helper
  demand <- apply_demand_transformation(demand, weights, approach, exp_demand, exp_weights, bb_area)

  totalpopconstant <- stars_cell_stats(demand, stat = "sum")

  demand <- mask_demand_by_traveltime(demand, traveltime, objectiveminutes)

  iter <- 1
  k_save <- 1
  new_facilities <- NULL

  repeat {
    iter <- iter + 1

    all <- find_next_facility(demand, heur, all_prev = NULL)

    pos <- stars_xy_from_index(demand, all)

    new_facilities <- accumulate_facility(new_facilities, pos)

    merged_facilities <-
      facilities |>
      sf::st_geometry() |>
      as.data.frame() |>
      dplyr::bind_rows(as.data.frame(new_facilities))

    points <-
      merged_facilities |>
      magrittr::extract2("geometry") |>
      sf::st_coordinates() |>
      as.data.frame()

    n_points <- points |> dim() |> magrittr::extract(1)
    xy_matrix <- points_to_matrix(points, n_points)

    traveltime_raster_new <-
      traveltime_raster_outer[[2]][[3]] |>
      gdistance::accCost(xy_matrix) |>
      as_stars_raster() |>
      stars::st_crop(sf::st_bbox(demand)) |>
      stars::st_warp(demand) |>
      mask_raster_to_polygon(bb_area)

    sf::st_crs(traveltime_raster_new) <- sf::st_crs(4326)

    demand <- mask_demand_by_traveltime(demand, traveltime_raster_new, objectiveminutes)

    k <-
      demand |>
      stars_cell_stats(stat = "sum") |>
      magrittr::divide_by(totalpopconstant)

    k_save[iter] <- k

    cli::cli_alert_info(
      paste0(
        "Iteration {.strong {cli::col_yellow(iter - 1)}}: ",
        "Share of unmet demand: ",
        "{.strong {cli::col_red(round(k * 100, 5))}}%."
      )
    )

    if (k < (1 - objectiveshare)) {
      break
    } else if (k == k_save[iter - 1]) {
      demand_values <- stars_values(demand)
      demand_values[all] <- NA
      demand <- stars_set_values(demand, demand_values)
    }
  }

  out <-
    list(
      coverage = 1 - k,
      unmet_demand = k,
      objective_minutes = objectiveminutes,
      objective_share = objectiveshare,
      facilities = merged_facilities |> #nolint
        magrittr::extract(-c(seq_len(nrow(facilities))), ),
      travel_time = traveltime_raster_new
    ) |>
    `class<-`(c("allocation", "list"))

  cli::cat_line()

  out |> coverage_message()

  invisible(out)
}

# Helper: Apply demand transformation based on weights and approach
apply_demand_transformation <- function(demand, weights, approach, exp_demand, exp_weights, bb_area) {
  if (is.null(weights)) {
    return(demand |> magrittr::raise_to_power(exp_demand))
  }

  weights <- weights |> mask_raster_to_polygon(bb_area)
  normalized_demand <- demand |>
    normalize_raster() |>
    magrittr::raise_to_power(exp_demand)

  if (approach == "norm") {
    return(normalized_demand |>
             magrittr::multiply_by(
               weights |>
                 normalize_raster() |>
                 magrittr::raise_to_power(exp_weights)
             ))
  }

  normalized_demand |>
    magrittr::multiply_by(
      weights |>
        magrittr::raise_to_power(exp_weights)
    )
}

# Helper: Calculate travel time raster from cost surface
calculate_traveltime_raster <- function(traveltime_raster_outer, xy_matrix, demand, bb_area) {
  out <- traveltime_raster_outer[[2]][[3]] |>
    gdistance::accCost(xy_matrix) |>
    as_stars_raster() |>
    stars::st_crop(sf::st_bbox(demand)) |>
    stars::st_warp(demand) |>
    mask_raster_to_polygon(bb_area)

  sf::st_crs(out) <- sf::st_crs(4326)
  out
}

# Helper: Run sampling iterations with optional parallelization
run_samples <- function(n_samples, runner, par) {
  if (par == TRUE) {
    if (.Platform$OS.type == "unix") {
      return(
        n_samples |>
          seq_len() |>
          parallel::mclapply(
            runner,
            mc.cores = parallel::detectCores() - 1
          )
      )
    } else {
      cl <- parallel::makeCluster(parallel::detectCores() - 1)

      cl |>
        parallel::clusterExport(
          varlist = ls(envir = .GlobalEnv)
        )

      cl |>
        parallel::clusterExport(
          varlist = ls(envir = environment()),
          envir = environment()
        )



      cl |>
        parallel::clusterEvalQ(
          {
            packages <- .packages()
            for (i in packages) {
              suppressMessages(require(i, character.only = TRUE))
            }
          }
        )

      outer <- cl |>
        parallel::parLapply(
          seq_len(n_samples),
          runner
        )

      parallel::stopCluster(cl)
      gc()
      return(outer)
    }
  } else {
    return(
      n_samples |>
        seq_len() |>
        cli::cli_progress_along("Iterating") |>
        lapply(runner)
    )
  }
}

# Helper: Initialize traveltime if not provided
initialize_traveltime <- function(traveltime, demand, bb_area, mode, dowscaling_model_type, res_output, objectiveminutes) {
  if (!is.null(traveltime)) {
    return(list(traveltime_outer = traveltime, is_new = FALSE))
  }

  traveltime_new <- as_stars_raster(demand)
  traveltime_new <- stars_set_values(
    traveltime_new,
    rep(objectiveminutes + 1, length(stars_values(traveltime_new)))
  )
  traveltime_new <- mask_raster_to_polygon(traveltime_new, bb_area)

  friction <- bb_area |>
    friction(
      mode = mode,
      dowscaling_model_type = dowscaling_model_type,
      res_output = res_output
    )

  list(traveltime_outer = list(traveltime_new, friction), is_new = TRUE)
}

allocation_discrete <- function(
    demand,
    bb_area,
    candidate,
    facilities = NULL,
    n_fac = Inf,
    n_samples = 1000,
    traveltime = NULL,
    mode = "walk",
    dowscaling_model_type = "lm",
    res_output = 100,
    weights = NULL,
    objectiveminutes = 15,
    objectiveshare = NULL,
    approach = "norm",
    exp_demand = 1,
    exp_weights = 1,
    par = FALSE
) {
  checkmate::assert_class(demand, "stars")
  assert_bb_area(bb_area)
  checkmate::assert_multi_class(candidate, c("sf", "sfc"))
  assert_facilities(facilities, null_ok = TRUE)
  checkmate::assert_count(n_fac, positive = TRUE)
  checkmate::assert_number(n_fac, lower = 1)
  checkmate::assert_count(n_samples, positive = TRUE)
  assert_traveltime(traveltime, null_ok = TRUE)
  checkmate::assert_choice(mode, choices = c("walk", "fastest"))
  checkmate::assert_choice(dowscaling_model_type, choices = c("lm", "rf"))
  checkmate::assert_count(res_output, positive = TRUE)
  checkmate::assert_class(weights, "stars", null.ok = TRUE)
  checkmate::assert_number(objectiveminutes, lower = 0)
  checkmate::assert_number(objectiveshare, lower = 0, upper = 1, null.ok = TRUE)
  checkmate::assert_choice(approach, choices = c("norm", "absweights"))
  checkmate::assert_number(exp_demand, lower = 0)
  checkmate::assert_number(exp_weights, lower = 0)
  checkmate::assert_flag(par)

  sf::sf_use_s2(TRUE)

  # Handle facilities and traveltime initialization
  if (is.null(facilities)) {
    facilities <- data.frame(x = 0, y = 0) |>
      sf::st_as_sf(coords = c("x", "y"), crs = 4326) |>
      magrittr::extract(-1, )
  } else if (is.null(traveltime)) {
    cli::cli_alert_info(
      paste0(
        "Travel time layer not detected. ",
        "Running {.strong {cli::col_red('traveltime()')}} ",
        "function first."
      )
    )

    traveltime <- facilities |>
      traveltime(
        bb_area = bb_area,
        mode = mode,
        dowscaling_model_type = dowscaling_model_type,
        res_output = res_output
      )

    assert_minimal_coverage(
      traveltime = traveltime,
      demand = demand,
      objectiveminutes = objectiveminutes,
      objectiveshare = objectiveshare,
      null_ok = TRUE
    )
  }

  demand <- demand |> mask_raster_to_polygon(bb_area)

  # Apply demand transformation
  demand <- apply_demand_transformation(demand, weights, approach, exp_demand, exp_weights, bb_area)

  # Initialize traveltime layers
  traveltime_init <- initialize_traveltime(
    traveltime, demand, bb_area, mode, dowscaling_model_type, res_output, objectiveminutes
  )
  traveltime_raster_outer <- traveltime_init$traveltime_outer

  totalpopconstant <- stars_cell_stats(demand, stat = "sum")

  traveltime_raster_outer[[1]] <- traveltime_raster_outer[[1]] |>
    as_stars_raster() |>
    stars::st_warp(demand)

  sf::st_crs(traveltime_raster_outer[[1]]) <- sf::st_crs(4326)

  demand <- mask_demand_by_traveltime(demand, traveltime_raster_outer[[1]], objectiveminutes)
  demand_raster_bk <- demand

  if (is.null(objectiveshare)) {
    # Single iteration: find best n_fac facilities
    samples <- n_samples |>
      replicate(
        candidate |>
          sf::st_as_sf() |>
          nrow() |>
          seq_len() |>
          sample(n_fac, replace = FALSE),
      )

    runner <- function(i) {
      demand_rasterio <- demand_raster_bk

      points <- facilities |>
        sf::st_coordinates() |>
        rbind(
          candidate |>
            sf::st_as_sf() |>
            sf::st_coordinates() |>
            magrittr::extract(samples[, i], )
        )

      points <- data.frame(X = points[, 1], Y = points[, 2])
      n_points <- points |> dim() |> magrittr::extract(1)
      xy_matrix <- points_to_matrix(points, n_points)

      traveltime_raster_new <- calculate_traveltime_raster(
        traveltime_raster_outer, xy_matrix, demand_rasterio, bb_area
      )

      demand_rasterio <- mask_demand_by_traveltime(demand_rasterio, traveltime_raster_new, objectiveminutes)

      demand_rasterio |>
        stars_cell_stats(stat = "sum") |>
        magrittr::divide_by(totalpopconstant)
    }

    outer <- run_samples(n_samples, runner, par)

    demand <- demand_raster_bk

    points <- facilities |>
      sf::st_coordinates() |>
      rbind(
        candidate |>
          sf::st_as_sf() |>
          sf::st_coordinates() |>
          magrittr::extract(
            samples[, which.min(unlist(outer))],
          )
      )

    points <- data.frame(X = points[, 1], Y = points[, 2])
    n_points <- points |> dim() |> magrittr::extract(1)
    xy_matrix <- points_to_matrix(points, n_points)

    traveltime_raster_new <- calculate_traveltime_raster(
      traveltime_raster_outer, xy_matrix, demand, bb_area
    )

    demand <- mask_demand_by_traveltime(demand, traveltime_raster_new, objectiveminutes)

    k <- demand |>
      stars_cell_stats(stat = "sum") |>
      magrittr::divide_by(totalpopconstant)

    out <- list(
      coverage = 1 - k,
      unmet_demand = k,
      objective_minutes = objectiveminutes,
      objective_share = objectiveshare,
      facilities = candidate |>
        sf::st_as_sf() |>
        magrittr::extract(
          samples |>
            magrittr::extract(,
                              outer |>
                                unlist() |>
                                which.min()
            ),
        ),
      travel_time = traveltime_raster_new
    ) |>
      `class<-`(c("allocation_discrete", "list"))

    out |> coverage_message()

    out
  } else {
    # Iterative: increase facilities until objectiveshare is met
    kiter <- 1

    repeat {
      kiter <- kiter + 1

      cli::cli_alert_info(
        "Iteration with {.strong {cli::col_yellow(kiter)}} facilities."
      )

      samples <- n_samples |>
        replicate(
          candidate |>
            sf::st_as_sf() |>
            nrow() |>
            seq_len() |>
            sample(kiter, replace = FALSE),
        )

      runner <- function(i) {
        demand_rasterio <- demand_raster_bk

        points <- facilities |>
          sf::st_coordinates() |>
          rbind(
            candidate |>
              sf::st_as_sf() |>
              sf::st_coordinates() |>
              magrittr::extract(samples[, i], )
          )

        points <- data.frame(X = points[, 1], Y = points[, 2])
        n_points <- points |> dim() |> magrittr::extract(1)
        xy_matrix <- points_to_matrix(points, n_points)

        traveltime_raster_new <- calculate_traveltime_raster(
          traveltime_raster_outer, xy_matrix, demand_rasterio, bb_area
        )

        demand_rasterio <- mask_demand_by_traveltime(demand_rasterio, traveltime_raster_new, objectiveminutes)

        demand_rasterio |>
          stars_cell_stats(stat = "sum") |>
          magrittr::divide_by(totalpopconstant)
      }

      outer <- run_samples(n_samples, runner, par)

      demand <- demand_raster_bk

      points <- facilities |>
        sf::st_coordinates() |>
        rbind(
          candidate |>
            sf::st_as_sf() |>
            sf::st_coordinates() |>
            magrittr::extract(
              samples[, which.min(unlist(outer))],
            )
        )

      points <- data.frame(X = points[, 1], Y = points[, 2])
      n_points <- points |> dim() |> magrittr::extract(1)
      xy_matrix <- points_to_matrix(points, n_points)

      traveltime_raster_new <- calculate_traveltime_raster(
        traveltime_raster_outer, xy_matrix, demand, bb_area
      )

      demand <- mask_demand_by_traveltime(demand, traveltime_raster_new, objectiveminutes)

      k <- demand |>
        stars_cell_stats(stat = "sum") |>
        magrittr::divide_by(totalpopconstant)

      cli::cli_alert_info(
        paste0(
          "Coverage share attained: ",
          "{.strong {cli::col_red(round((1 - k) * 100, 5))}}%."
        )
      )

      if (k < (1 - objectiveshare) || kiter == n_fac) break
    }

    out <- list(
      coverage = 1 - k,
      unmet_demand = k,
      objective_minutes = objectiveminutes,
      objective_share = objectiveshare,
      facilities = candidate |>
        sf::st_as_sf() |>
        magrittr::extract(
          samples[, which.min(unlist(outer))],
        ),
      travel_time = traveltime_raster_new
    ) |>
      `class<-`(c("allocation_discrete", "list"))

    out |> coverage_message()

    invisible(out)
  }
}
