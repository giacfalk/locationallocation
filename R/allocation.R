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
#' @param weights (optional) A raster with the weights for the demand (default:
#' `NULL`).
#' @template params-objectiveminutes
#' @template params-objectiveshare-a
#' @param heur (optional) The heuristic approach to be used. Options are `"max"`
#'   and `"kd"` (default: `"max"`).
#' @param approach (optional) The approach to be used for the allocation.
#'   Options are `"norm"` and `"absweights"`. If "norm", the allocation is based
#'   on the normalized demand raster multiplied by the normalized weights
#'   raster. If `"absweights"`, the allocation is based on the normalized demand
#'   raster multiplied by the raw weights raster (default: `"norm"`).
#' @param exp_demand (optional) The exponent for the demand raster. Default is
#'   1. A higher value will give less relative weight to areas with higher
#'   demand - with respect to the weights layer. This is useful in cases where
#'   the users want to increase the allocation in areas with higher values in
#'   the weights layer (default: `1`).
#' @param exp_weights (optional) The exponent for the weights raster. Default is
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
#'   - `travel_time`: A [`raster`][raster::raster()] RasterLayer object
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
  checkmate::assert_class(demand, "RasterLayer")
  assert_bb_area(bb_area)
  assert_facilities(facilities)
  assert_traveltime(traveltime, null_ok = TRUE)
  checkmate::assert_choice(mode, choices = c("walk", "fastest"))
  checkmate::assert_choice(dowscaling_model_type, choices = c("lm", "rf"))
  checkmate::assert_count(res_output, positive = TRUE)
  checkmate::assert_class(weights, "RasterLayer", null.ok = TRUE)
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

  raster::crs(traveltime) <-
    "+proj=longlat +datum=WGS84 +no_defs +type=crs"

  traveltime <- raster::projectRaster(traveltime, demand)

  raster::crs(traveltime) <- "+proj=longlat +datum=WGS84 +no_defs +type=crs"

  if (!is.null(weights) && approach == "norm") {
    weights <- weights |> mask_raster_to_polygon(bb_area)

    demand <-
      demand |>
      normalize_raster() |>
      magrittr::raise_to_power(exp_demand) |>
      magrittr::multiply_by(
        weights |>
          normalize_raster() |>
          magrittr::raise_to_power(exp_weights)
      )
  } else if (!is.null(weights) && approach == "absweights") {
    weights <- weights |> mask_raster_to_polygon(bb_area)

    demand <-
      demand |>
      normalize_raster() |>
      magrittr::raise_to_power(exp_demand) |>
      magrittr::multiply_by(
        weights |>
          magrittr::raise_to_power(exp_weights)
      )
  } else if (is.null(weights)) {
    demand <- demand |> magrittr::raise_to_power(exp_demand)
  }

  totalpopconstant <- demand |> raster::cellStats("sum", na.rm = TRUE)

  demand <-
    demand |>
    raster::overlay(
      traveltime,
      fun = function(x, y) {
        x[y <= objectiveminutes] <- NA

        x
      }
    )

  iter <- 1
  k_save <- 1

  repeat {
    iter <- iter + 1

    if (heur == "kd") {
      all <- spatialEco::sp.kde(
        x = sf::st_as_sf(raster::rasterToPoints(demand, spatial = TRUE)),
        y = all$layer,
        bw = 0.0083333,
        ref = terra::rast(demand),
        res = 0.0008333333,
        standardize = TRUE,
        scale.factor = 10000
      )
    } else if (heur == "max") {
      all <- raster::which.max(demand)
    }

    pos <-
      demand |>
      raster::xyFromCell(all) |>
      as.data.frame()

    if (exists("new_facilities")) {
      new_facilities <-
        new_facilities |>
        rbind(
          pos |>
            sf::st_as_sf(
              coords = c("x", "y"),
              crs = 4326
            )
        )
    } else {
      new_facilities <-
        pos |>
        sf::st_as_sf(
          coords = c("x", "y"),
          crs = 4326
        )
    }

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
      raster::crop(raster::extent(demand)) |>
      raster::`crs<-`(
        value = "+proj=longlat +datum=WGS84 +no_defs +type=crs"
      ) |>
      raster::projectRaster(demand) |>
      raster::`crs<-`(
        value = "+proj=longlat +datum=WGS84 +no_defs +type=crs"
      ) |>
      mask_raster_to_polygon(bb_area)

    demand <-
      demand |>
      raster::overlay(
        traveltime_raster_new,
        fun = function(x, y) {
          x[y <= objectiveminutes] <- NA

          x
        }
      )

    k <-
      demand |>
      raster::cellStats("sum", na.rm = TRUE) |>
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
      raster::values(demand)[all] <- NA
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
  checkmate::assert_class(demand, "RasterLayer")
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
  checkmate::assert_class(weights, "RasterLayer", null.ok = TRUE)
  checkmate::assert_number(objectiveminutes, lower = 0)
  checkmate::assert_number(objectiveshare, lower = 0, upper = 1, null.ok = TRUE)
  checkmate::assert_choice(approach, choices = c("norm", "absweights"))
  checkmate::assert_number(exp_demand, lower = 0)
  checkmate::assert_number(exp_weights, lower = 0)
  checkmate::assert_flag(par)

  sf::sf_use_s2(TRUE)

  if (!is.null(facilities)) {
    if (is.null(traveltime)) {
      cli::cli_alert_info(
        paste0(
          "Travel time layer not detected. ",
          "Running {.strong {cli::col_red('traveltime()')}} ",
          "function first."
        )
      )

      traveltime <-
        facilities |>
        traveltime(
          bb_area = bb_area,
          mode = mode,
          dowscaling_model_type = dowscaling_model_type,
          res_output = res_output
        )
    } else {
      traveltime_raster_outer <- traveltime
    }

    assert_minimal_coverage(
      traveltime = traveltime,
      demand = demand,
      objectiveminutes = objectiveminutes,
      objectiveshare = objectiveshare,
      null_ok = TRUE
    )
  } else {
    facilities <-
      data.frame(x = 0, y = 0) |>
      sf::st_as_sf(coords = c("x", "y"), crs = 4326) |>
      magrittr::extract(-1, )
  }

  demand <- demand |> mask_raster_to_polygon(bb_area)

  if (!is.null(weights) && approach == "norm") {
    weights <- weights |> mask_raster_to_polygon(bb_area)

    demand <-
      demand |>
      normalize_raster() |>
      magrittr::raise_to_power(exp_demand) |>
      magrittr::multiply_by(
        weights |>
          normalize_raster() |>
          magrittr::raise_to_power(exp_weights)
      )
  } else if (!is.null(weights) && approach == "absweights") {
    weights <- weights |> mask_raster_to_polygon(bb_area)

    demand <-
      demand |>
      normalize_raster() |>
      magrittr::raise_to_power(exp_demand) |>
      magrittr::multiply_by(
        weights |>
          magrittr::raise_to_power(exp_weights)
      )
  } else if (is.null(weights)) {
    demand <- demand |> magrittr::raise_to_power(exp_demand)
  }

  if (!exists("traveltime_raster_outer")) {
    traveltime <-
      demand |>
      raster::`values<-`(objectiveminutes + 1) |>
      mask_raster_to_polygon(bb_area)

    friction <-
      bb_area |>
      friction(
        mode = mode,
        dowscaling_model_type = dowscaling_model_type,
        res_output = res_output
      )

    traveltime_raster_outer <- list(traveltime, friction)
  }

  totalpopconstant <- demand |> raster::cellStats("sum", na.rm = TRUE)

  traveltime_raster_outer[[1]] <-
    traveltime_raster_outer[[1]] |>
    raster::`crs<-`(
      value = "+proj=longlat +datum=WGS84 +no_defs +type=crs"
    ) |>
    raster::projectRaster(demand) |>
    raster::`crs<-`(
      value = "+proj=longlat +datum=WGS84 +no_defs +type=crs"
    )

  demand <-
    demand |>
    raster::overlay(
      traveltime_raster_outer[[1]],
      fun = function(x, y) {
        x[y <= objectiveminutes] <- NA

        x
      }
    )

  demand_raster_bk <- demand

  if (is.null(objectiveshare)) {
    samples <-
      n_samples |>
      replicate(
        candidate |>
          sf::st_as_sf() |>
          nrow() |>
          seq_len() |>
          sample(n_fac, replace = FALSE),
      )

    runner <- function(i) {
      demand_rasterio <- demand_raster_bk

      points <-
        facilities |>
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

      traveltime_raster_new <-
        traveltime_raster_outer[[2]][[3]] |>
        gdistance::accCost(xy_matrix) |>
        raster::crop(raster::extent(demand_rasterio)) |>
        raster::`crs<-`(
          value = "+proj=longlat +datum=WGS84 +no_defs +type=crs"
        ) |>
        raster::projectRaster(demand_rasterio) |>
        raster::`crs<-`(
          value = "+proj=longlat +datum=WGS84 +no_defs +type=crs"
        ) |>
        mask_raster_to_polygon(bb_area)

      demand_rasterio <-
        demand_rasterio |>
        raster::overlay(
          traveltime_raster_new,
          fun = function(x, y) {
            x[y <= objectiveminutes] <- NA

            x
          }
        )

      demand_rasterio |>
        raster::cellStats("sum", na.rm = TRUE) |>
        magrittr::divide_by(totalpopconstant)
    }

    if (par == TRUE) {
      if (.Platform$OS.type == "unix") {
        outer <-
          n_samples |>
          seq_len() |>
          parallel::mclapply(
            runner,
            mc.cores = parallel::detectCores() - 1
          )
      } else {
        # Use `parLapply` for Windows.
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

        # Get all currently loaded packages (names only).
        # Load each package on every cluster worker.
        cl |>
          parallel::clusterEvalQ(
            {
              # Loop through the package names and load them.
              packages <- .packages()

              for (i in packages) {
                suppressMessages(require(i, character.only = TRUE))
              }
            }
          )

        outer <-
          cl |>
          parallel::parLapply(
            seq_len(n_samples),
            runner
          )

        parallel::stopCluster(cl)
        gc()
      }
    } else {
      outer <-
        n_samples |>
        seq_len() |>
        cli::cli_progress_along("Iterating") |>
        lapply(runner)
    }

    demand <- demand_raster_bk

    points <-
      facilities |>
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

    traveltime_raster_new <-
      traveltime_raster_outer[[2]][[3]] |>
      gdistance::accCost(xy_matrix) |>
      raster::crop(raster::extent(demand)) |>
      raster::`crs<-`(
        value = "+proj=longlat +datum=WGS84 +no_defs +type=crs"
      ) |>
      raster::projectRaster(demand) |>
      raster::`crs<-`(
        value = "+proj=longlat +datum=WGS84 +no_defs +type=crs"
      ) |>
      mask_raster_to_polygon(bb_area)

    demand <-
      demand |>
      raster::overlay(
        traveltime_raster_new,
        fun = function(x, y) {
          x[y <= objectiveminutes] <- NA

          x
        }
      )

    k <-
      demand |>
      raster::cellStats("sum", na.rm = TRUE) |>
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
            ), # Do not remove the comma!
        ),
      travel_time = traveltime_raster_new
    ) |>
      `class<-`(c("allocation_discrete", "list"))

    out |> coverage_message()

    out
  } else {
    kiters <- seq(2, n_fac)
    kiter <- kiters[1] - 1

    repeat {
      kiter <- kiter + 1

      cli::cli_alert_info(
        "Iteration with {.strong {cli::col_yellow(kiter)}} facilities."
      )

      samples <-
        n_samples |>
        replicate(
          candidate |>
            sf::st_as_sf() |>
            nrow() |>
            seq_len() |>
            sample(kiter, replace = FALSE),
        )

      runner <- function(i) {
        demand_rasterio <- demand_raster_bk

        points <-
          facilities |>
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

        traveltime_raster_new <-
          traveltime_raster_outer[[2]][[3]] |>
          gdistance::accCost(xy_matrix) |>
          raster::crop(raster::extent(demand_rasterio)) |>
          raster::`crs<-`(
            value = "+proj=longlat +datum=WGS84 +no_defs +type=crs"
          ) |>
          raster::projectRaster(demand_rasterio) |>
          raster::`crs<-`(
            value = "+proj=longlat +datum=WGS84 +no_defs +type=crs"
          ) |>
          mask_raster_to_polygon(bb_area)

        demand_rasterio <-
          demand_rasterio |>
          raster::overlay(
            traveltime_raster_new,
            fun = function(x, y) {
              x[y <= objectiveminutes] <- NA

              x
            }
          )

        demand_rasterio |>
          raster::cellStats("sum", na.rm = TRUE) |>
          magrittr::divide_by(totalpopconstant)
      }

      if (par == TRUE) {
        if (.Platform$OS.type == "unix") {
          outer <-
            n_samples |>
            seq_len() |>
            parallel::mclapply(
              runner,
              mc.cores = parallel::detectCores() - 1
            )
        } else {
          # Use `parLapply` for Windows.
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

          # Get all currently loaded packages (names only).
          # Load each package on every cluster worker.
          cl |>
            parallel::clusterEvalQ(
              {
                # Loop through the package names and load them.
                packages <- .packages()

                for (i in packages) {
                  suppressMessages(require(i, character.only = TRUE))
                }
              }
            )

          outer <-
            cl |>
            parallel::parLapply(
              seq_len(n_samples),
              runner
            )

          parallel::stopCluster(cl)
          gc()
        }
      } else {
        outer <-
          n_samples |>
          seq_len() |>
          cli::cli_progress_along("Iterating") |>
          lapply(runner)
      }

      demand <- demand_raster_bk

      points <-
        facilities |>
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

      traveltime_raster_new <-
        traveltime_raster_outer[[2]][[3]] |>
        gdistance::accCost(xy_matrix) |>
        raster::crop(raster::extent(demand)) |>
        raster::`crs<-`(
          value = "+proj=longlat +datum=WGS84 +no_defs +type=crs"
        ) |>
        raster::projectRaster(demand) |>
        raster::`crs<-`(
          value = "+proj=longlat +datum=WGS84 +no_defs +type=crs"
        ) |>
        mask_raster_to_polygon(bb_area)

      demand <-
        demand |>
        raster::overlay(
          traveltime_raster_new,
          fun = function(x, y) {
            x[y <= objectiveminutes] <- NA
            x
          }
        )

      k <-
        demand |>
        raster::cellStats("sum", na.rm = TRUE) |>
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
