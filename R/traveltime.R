#' Generate a travel time map
#'
#' @description
#'
#' `traveltime()` generates a map of the travel time (in minutes) to the
#' nearest facility, based on the input facilities, area of interest, and
#' travel mode.
#'
#' See the [`friction()`][friction] function for details on how the friction
#' layer is generated.
#'
#' @details
#'
#' All facilities within the extent of the friction surface (i.e., the
#' bounding box of `bb_area`) are used as sources, including those located
#' just outside the boundary of `bb_area`, since they can still serve demand
#' within it. The resulting travel time map is masked to `bb_area`. Cells that
#' cannot be reached from any facility (e.g., cells with no friction data, such
#' as open water) have an infinite travel time.
#'
#' @template params-facilities
#' @inheritParams friction
#'
#' @return An [invisible][base::invisible] [`list`][base::list] of class
#'   `traveltime` with the following elements:
#'   - `travel_time`: A [`RasterLayer`][raster::raster()] object with the travel
#'     time (in minutes) to the nearest facility.
#'   - `friction`: A [`list`][base::list] with the outputs of the
#'     [`friction()`][friction] function.
#'
#' @family travel time functions
#' @keywords spatial
#' @export
#'
#' @examples
#' \dontrun{
#'   library(dplyr)
#'
#'   traveltime_data <-
#'     naples_fountains |>
#'     traveltime(
#'       bb_area = naples_shape,
#'       mode = "walk",
#'       res_output = 100
#'     )
#'
#'   traveltime_data
#'
#'   traveltime_data |>
#'     traveltime_plot(
#'       bb_area = naples_shape,
#'       facilities = naples_fountains
#'   )
#' }
traveltime <- function(
  facilities,
  bb_area,
  mode = "walk",
  dowscaling_model_type = NULL,
  res_output = 100,
  cache = FALSE,
  file = NULL,
  roads = NULL,
  road_speeds = default_road_speeds()
) {
  assert_facilities(facilities)
  assert_bb_area(bb_area)
  checkmate::assert_choice(mode, choices = c("walk", "fastest"))
  warn_dowscaling_model_type(dowscaling_model_type)
  checkmate::assert_count(res_output, positive = TRUE)
  checkmate::assert_flag(cache)
  checkmate::assert_string(file, null.ok = TRUE)

  facilities <- as_wgs84(facilities)
  bb_area <- as_wgs84(bb_area)

  friction_data <-
    bb_area |>
    friction(
      mode = mode,
      res_output = res_output,
      cache = cache,
      file = file,
      roads = roads,
      road_speeds = road_speeds
    )

  points <- points_xy(facilities, within = friction_data$friction_layer)

  if (nrow(points) == 0) {
    cli::cli_abort(
      paste0(
        "None of the {.strong facilities} fall within the extent of ",
        "{.strong bb_area}."
      )
    )
  }

  cli::cli_progress_step("Computing travel time map")

  # Run the accumulated cost algorithm to make the final output map.
  # This can be quite slow (potentially hours) for large areas.
  travel_time <-
    friction_data$geocorrection_matrix |>
    gdistance::accCost(points) |>
    mask_raster_to_polygon(bb_area)

  names(travel_time) <- "travel_time"

  cli::cli_progress_done()

  list(
    travel_time = travel_time,
    friction = friction_data
  ) |>
    `class<-`(c("traveltime", "list")) |>
    invisible()
}
