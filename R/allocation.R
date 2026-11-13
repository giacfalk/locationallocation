#' Maximal coverage location-allocation
#'
#' @description
#'
#' `allocation()` and `allocation_discrete()` allocate new facilities so as to
#' maximize the share of (optionally weighted) demand that can reach a facility
#' within `objectiveminutes` minutes.
#'
#' - `allocation()` solves a **continuous** problem: new facilities can be
#'   placed anywhere within `bb_area` (any cell of the `demand` grid).
#' - `allocation_discrete()` solves a **discrete** problem: new facilities
#'   are selected from a user-defined set of `candidate` locations.
#'
#' Both functions can either add facilities until a target coverage
#' (`objectiveshare`) is reached, using as few facilities as possible, or
#' allocate a fixed maximum number of facilities (`n_fac`).
#'
#' @details
#'
#' ## Coverage
#'
#' A demand cell is covered when its travel time to the nearest (existing or
#' new) facility is less than or equal to `objectiveminutes`. Coverage is the
#' share of the total (weighted) demand within `bb_area` that is covered.
#' Travel times are computed with the accumulated cost algorithm
#' ([`gdistance::accCost()`][gdistance::accCost()]) over the friction surface
#' and aligned to the grid of `demand`.
#'
#' ## Continuous problem (`allocation()`)
#'
#' Facilities are added one at a time with a (lazy) greedy heuristic. At each
#' iteration:
#'
#' 1. A score of the demand not yet covered proposes a shortlist of promising
#'    locations: the `shortlist` highest local maxima of the score, at least
#'    half a catchment radius apart. The catchment radius is the distance that
#'    can be traveled within `objectiveminutes` at the median friction of the
#'    study area. The score is:
#'    - `heur = "kd"`: the uncovered demand smoothed with a quartic kernel
#'      whose bandwidth is the catchment radius, i.e., an estimate of the
#'      uncovered demand within the catchment of a facility placed at each
#'      cell.
#'    - `heur = "max"`: the uncovered demand of each cell.
#' 2. The catchment of each shortlisted location (the demand cells it can
#'    reach within `objectiveminutes`) is computed with the accumulated cost
#'    algorithm. Catchments do not change as facilities are added, so the
#'    locations evaluated in previous iterations remain candidates at no
#'    extra cost.
#' 3. The new facility is placed at the evaluated location that covers the
#'    largest amount of uncovered demand (greedy step of Church & ReVelle,
#'    1974).
#'
#' The greedy phase stops when `objectiveshare` is reached, when `n_fac` new
#' facilities have been allocated, or when no further location increases the
#' coverage. The solution is then refined (vertex substitution heuristic,
#' Teitz & Bart, 1968): each facility is in turn moved to the evaluated
#' location that covers the most demand left uncovered by the others, if that
#' increases the coverage. New locations are evaluated near each facility at
#' every pass: local maxima of the score, and eight locations around the
#' facility at a distance that starts at half the catchment radius and is
#' halved whenever the facility is not moved (pattern search). With
#' `objectiveshare`, the facility covering the least demand on its own is
#' then dropped and the solution refined again, as long as the target is
#' still met.
#'
#' Larger `shortlist` values evaluate more locations per iteration, which can
#' yield better solutions at the cost of more travel time computations. Set
#' `refine = FALSE` to skip the refinement phase for faster, greedy-only
#' solutions.
#'
#' ## Discrete problem (`allocation_discrete()`)
#'
#' Since the travel time from a set of facilities is the minimum of the travel
#' times from each of them, the set of demand cells covered by each candidate
#' location is computed once (one accumulated cost run per candidate). Then:
#'
#' 1. Candidates are added one at a time, each time selecting the candidate
#'    that covers the largest amount of demand not yet covered (greedy
#'    heuristic, Church & ReVelle, 1974).
#' 2. The selection is refined by swapping selected and non-selected candidates
#'    as long as a swap increases the coverage (vertex substitution heuristic,
#'    Teitz & Bart, 1968).
#'
#' If `objectiveshare` is `NULL`, up to `n_fac` candidates are selected to
#' maximize coverage. Otherwise, candidates are added (and the selection
#' refined) until `objectiveshare` is reached or `n_fac` candidates have been
#' selected. The solution is deterministic and usually optimal or near-optimal.
#'
#' ## Demand weights
#'
#' When `weights` is provided, the demand to be covered is a combination of
#' the `demand` and `weights` layers (e.g., population times exposure to a
#' hazard):
#'
#' - `approach = "norm"`: \eqn{D^{a} \times W^{b}}, where \eqn{D} and \eqn{W}
#'   are the demand and weights layers rescaled to \eqn{[0, 1]} (min-max
#'   normalization). Note that cells with the lowest weight receive zero
#'   priority.
#' - `approach = "absweights"`: \eqn{D^{a} \times w^{b}}, where \eqn{w} are the
#'   raw (non-negative) weights. Priorities are proportional to the weights.
#'
#' with \eqn{a} = `exp_demand` and \eqn{b} = `exp_weights`. Without `weights`,
#' the demand is \eqn{demand^{a}}. Coverage and `objectiveshare` then refer to
#' this weighted demand.
#'
#' @template params-demand
#' @template params-bb-area
#' @param facilities A [`sf`][sf::st_as_sf()] object with the existing
#'   facilities, or `NULL` if there are no existing facilities. Required by
#'   `allocation()` (use `facilities = NULL` explicitly to allocate from
#'   scratch); optional in `allocation_discrete()` (default: `NULL`).
#' @param traveltime (optional) The output of the [`traveltime()`][traveltime()]
#'   function, whose friction surface is reused to avoid downloading and
#'   downscaling it again. The travel times from `facilities` are recomputed
#'   on this surface. If `NULL`, the friction surface is computed with
#'   [`friction()`][friction()] using `mode` and `res_output` (default:
#'   `NULL`).
#' @param weights (optional) A [`RasterLayer`][raster::raster()] or
#'   [`SpatRaster`][terra::rast()] object with the weights for the demand
#'   (e.g., a hazard layer). It is resampled to the grid of `demand` if needed
#'   (default: `NULL`).
#' @template params-objectiveminutes
#' @param objectiveshare (optional) A number between `0` and `1` indicating
#'   the share of the (weighted) demand to be covered. In `allocation()` it can
#'   only be `NULL` if `n_fac` is finite (default: `0.99` for `allocation()`
#'   and `NULL` for `allocation_discrete()`).
#' @param heur (optional) The score used by `allocation()` to shortlist
#'   promising locations for each new facility. Options are `"kd"` and
#'   `"max"`. See *Details* (default: `"kd"`).
#' @param shortlist (optional) A positive
#'   [integerish][checkmate::test_integerish()] number indicating how many
#'   new promising locations `allocation()` evaluates exactly at each
#'   iteration. See *Details* (default: `10`).
#' @param refine (optional) A [`logical`][base::logical()] flag indicating
#'   whether `allocation()` refines the greedy solution by vertex substitution
#'   (see *Details*). Refinement usually reduces the number of facilities
#'   needed for a given coverage, but takes more time (default: `TRUE`).
#' @param approach (optional) The approach used to combine the `demand` and
#'   `weights` layers. Options are `"norm"` and `"absweights"`. See *Details*
#'   (default: `"norm"`).
#' @param exp_demand (optional) The exponent applied to the demand layer.
#'   Values greater than `1` increase the relative priority of high-demand
#'   cells, and the influence of `demand` with respect to `weights`
#'   (default: `1`).
#' @param exp_weights (optional) The exponent applied to the weights layer.
#'   Values greater than `1` increase the relative priority of cells with high
#'   weights, and the influence of `weights` with respect to `demand`
#'   (default: `1`).
#' @param n_fac (optional) A positive [integerish][checkmate::test_integerish()]
#'   number indicating the maximum number of new facilities to allocate. In
#'   `allocation_discrete()`, it is capped at the number of candidate
#'   locations (default: `Inf`).
#' @param candidate A [`sf`][sf::st_as_sf()] object with the candidate
#'   locations (`POINT` geometries) for the new facilities
#'   (`allocation_discrete()` only).
#' @param n_samples Deprecated and ignored. `allocation_discrete()` no longer
#'   relies on random sampling (`allocation_discrete()` only).
#' @param par (optional) A [`logical`][base::logical()] flag indicating whether
#'   to compute the travel times from the candidate locations in
#'   [parallel][parallel::parLapply()] (`allocation_discrete()` only; default:
#'   `FALSE`).
#'
#' @inheritParams friction
#'
#' @return An [invisible][base::invisible] [`list`][base::list] of class
#'   `allocation` (continuous problem) or `allocation_discrete` (discrete
#'   problem) with the following elements:
#'   - `coverage`: A [`numeric`][base::numeric()] value indicating the share of
#'   (weighted) demand covered within the objective travel time after
#'   allocating the new facilities.
#'   - `unmet_demand`: A [`numeric`][base::numeric()] value indicating the share
#'   of (weighted) demand that remains unmet after allocating the new
#'   facilities.
#'   - `objective_minutes`: The value of the `objectiveminutes` parameter used.
#'   - `objective_share`: The value of the `objectiveshare` parameter used.
#'   - `facilities`: A [`sf`][sf::sf()] object with the newly allocated
#'   facilities (for `allocation_discrete()`, the selected rows of
#'   `candidate`).
#'   - `travel_time`: A [`RasterLayer`][raster::raster()] object, on the grid
#'   of `demand`, with the travel time (in minutes) to the nearest facility
#'   after allocating the new facilities.
#'
#' @family location-allocation functions
#' @keywords location-allocation
#' @export
#'
#' @references
#'
#' Church, R., & ReVelle, C. (1974). The maximal covering location problem.
#' *Papers of the Regional Science Association*, *32*(1), 101–118.
#' \doi{10.1007/BF01942293}
#'
#' Teitz, M. B., & Bart, P. (1968). Heuristic methods for estimating the
#' generalized vertex median of a weighted graph. *Operations Research*,
#' *16*(5), 955–961. \doi{10.1287/opre.16.5.955}
#'
#' @examples
#' \dontrun{
#'   library(sf)
#'
#'   traveltime_data <-
#'     naples_fountains |>
#'     traveltime(bb_area = naples_shape)
#'
#'   ## Continuous problem -----
#'
#'   allocation_data <-
#'     naples_population |>
#'     allocation(
#'       bb_area = naples_shape,
#'       facilities = naples_fountains,
#'       traveltime = traveltime_data,
#'       weights = naples_hot_days,
#'       objectiveminutes = 15,
#'       objectiveshare = 0.99
#'     )
#'
#'   allocation_data
#'
#'   allocation_data |> allocation_plot(naples_shape)
#'
#'   ## Discrete problem -----
#'
#'   allocation_data <-
#'     naples_population |>
#'     allocation_discrete(
#'       bb_area = naples_shape,
#'       candidate = naples_shape |> st_sample(20),
#'       facilities = naples_fountains,
#'       traveltime = traveltime_data,
#'       n_fac = 2,
#'       objectiveminutes = 15
#'     )
#'
#'   allocation_data
#'
#'   allocation_data |> allocation_plot(naples_shape)
#' }
allocation <- function(
  demand,
  bb_area,
  facilities,
  traveltime = NULL,
  mode = "walk",
  dowscaling_model_type = NULL,
  res_output = 100,
  weights = NULL,
  objectiveminutes = 15,
  objectiveshare = 0.99,
  heur = "kd",
  approach = "norm",
  exp_demand = 1,
  exp_weights = 1,
  n_fac = Inf,
  shortlist = 10,
  refine = TRUE
) {
  demand <- as_raster_layer(demand)
  assert_bb_area(bb_area)
  assert_facilities(facilities, null_ok = TRUE)
  assert_traveltime(traveltime, null_ok = TRUE)
  checkmate::assert_choice(mode, choices = c("walk", "fastest"))
  warn_dowscaling_model_type(dowscaling_model_type)
  checkmate::assert_count(res_output, positive = TRUE)
  weights <- as_raster_layer(weights, null_ok = TRUE)
  checkmate::assert_number(objectiveminutes, lower = 0, finite = TRUE)
  checkmate::assert_number(objectiveshare, lower = 0, upper = 1, null.ok = TRUE)
  checkmate::assert_choice(heur, choices = c("kd", "max"))
  checkmate::assert_choice(approach, choices = c("norm", "absweights"))
  checkmate::assert_number(exp_demand, lower = 0, finite = TRUE)
  checkmate::assert_number(exp_weights, lower = 0, finite = TRUE)
  assert_n_fac(n_fac)
  checkmate::assert_count(shortlist, positive = TRUE)
  checkmate::assert_flag(refine)

  if (is.null(objectiveshare) && is.infinite(n_fac)) {
    cli::cli_abort(
      "Either {.strong objectiveshare} or {.strong n_fac} must be specified."
    )
  }

  bb_area <- as_wgs84(bb_area)
  facilities <- as_wgs84(facilities)

  setup <- allocation_setup(
    demand = demand,
    bb_area = bb_area,
    facilities = facilities,
    traveltime = traveltime,
    mode = mode,
    res_output = res_output,
    weights = weights,
    approach = approach,
    exp_demand = exp_demand,
    exp_weights = exp_weights
  )

  assert_unmet_objective(setup, objectiveminutes, objectiveshare)

  solution <- allocate_continuous(
    setup = setup,
    objectiveminutes = objectiveminutes,
    objectiveshare = objectiveshare,
    n_fac = n_fac,
    heur = heur,
    shortlist = shortlist,
    refine = refine
  )

  new_facilities <-
    solution$xy |>
    as.data.frame() |>
    sf::st_as_sf(coords = c("x", "y"), crs = 4326)

  out <-
    list(
      coverage = 1 - solution$unmet,
      unmet_demand = solution$unmet,
      objective_minutes = objectiveminutes,
      objective_share = objectiveshare,
      facilities = new_facilities,
      travel_time = values_to_raster(solution$travel_time, setup$template)
    ) |>
    `class<-`(c("allocation", "list"))

  cli::cat_line()
  coverage_message(out)

  invisible(out)
}

#' @rdname allocation
#' @export
allocation_discrete <- function(
  demand,
  bb_area,
  candidate,
  facilities = NULL,
  n_fac = Inf,
  n_samples,
  traveltime = NULL,
  mode = "walk",
  dowscaling_model_type = NULL,
  res_output = 100,
  weights = NULL,
  objectiveminutes = 15,
  objectiveshare = NULL,
  approach = "norm",
  exp_demand = 1,
  exp_weights = 1,
  par = FALSE
) {
  demand <- as_raster_layer(demand)
  assert_bb_area(bb_area)
  assert_facilities(candidate)
  assert_facilities(facilities, null_ok = TRUE)
  assert_n_fac(n_fac)
  assert_traveltime(traveltime, null_ok = TRUE)
  checkmate::assert_choice(mode, choices = c("walk", "fastest"))
  warn_dowscaling_model_type(dowscaling_model_type)
  checkmate::assert_count(res_output, positive = TRUE)
  weights <- as_raster_layer(weights, null_ok = TRUE)
  checkmate::assert_number(objectiveminutes, lower = 0, finite = TRUE)
  checkmate::assert_number(objectiveshare, lower = 0, upper = 1, null.ok = TRUE)
  checkmate::assert_choice(approach, choices = c("norm", "absweights"))
  checkmate::assert_number(exp_demand, lower = 0, finite = TRUE)
  checkmate::assert_number(exp_weights, lower = 0, finite = TRUE)
  checkmate::assert_flag(par)

  if (!missing(n_samples)) {
    cli::cli_warn(
      paste0(
        "{.strong n_samples} is deprecated and ignored: ",
        "{.fn allocation_discrete} now uses a deterministic greedy ",
        "heuristic with interchange refinement."
      )
    )
  }

  bb_area <- as_wgs84(bb_area)
  candidate <- as_wgs84(candidate)
  facilities <- as_wgs84(facilities)

  setup <- allocation_setup(
    demand = demand,
    bb_area = bb_area,
    facilities = facilities,
    traveltime = traveltime,
    mode = mode,
    res_output = res_output,
    weights = weights,
    approach = approach,
    exp_demand = exp_demand,
    exp_weights = exp_weights
  )

  assert_unmet_objective(setup, objectiveminutes, objectiveshare)

  solution <- allocate_discrete(
    setup = setup,
    candidate = candidate,
    objectiveminutes = objectiveminutes,
    objectiveshare = objectiveshare,
    n_fac = n_fac,
    par = par
  )

  out <-
    list(
      coverage = 1 - solution$unmet,
      unmet_demand = solution$unmet,
      objective_minutes = objectiveminutes,
      objective_share = objectiveshare,
      facilities = candidate[solution$selected, ],
      travel_time = values_to_raster(solution$travel_time, setup$template)
    ) |>
    `class<-`(c("allocation_discrete", "list"))

  cli::cat_line()
  coverage_message(out)

  invisible(out)
}

assert_n_fac <- function(n_fac) {
  if (!identical(n_fac, Inf)) {
    checkmate::assert_count(n_fac, positive = TRUE)
  }

  invisible(TRUE)
}
