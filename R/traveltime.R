#' Generate a travel time map
#'
#' @description
#'
#' `traveltime()` generates a travel time map based on the input facilities,
#' bounding box area, and travel mode.
#'
#' See the [`friction()`][friction] function for details on how the friction
#' layer is generated.
#'
#' @template params-facilities
#' @inheritParams friction
#'
#' @return An [invisible][base::invisible] [`list`][base::list] with the
#'   following elements:
#'   - `travel_time`: A [`stars`][stars::st_as_stars()] object with the travel
#'     time map.
#'   - `friction`: A [`list`][base::list] with the outputs of the
#'     [`friction()`][friction] function.
#'
#' @family travel time functions
#' @keywords cats
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
#'       dowscaling_model_type = "lm",
#'       mode = "walk",
#'       res_output = 100
#'     )
#'
#'   traveltime_data |> glimpse()
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
  dowscaling_model_type = "lm",
  res_output = 100,
  cache = FALSE,
  file = NULL
) {
  assert_facilities(facilities)
  assert_bb_area(bb_area)
  checkmate::assert_choice(dowscaling_model_type, choices = c("lm", "rf"))
  checkmate::assert_choice(mode, choices = c("walk", "fastest"))
  checkmate::assert_count(res_output)
  checkmate::assert_string(file, null.ok = TRUE)

  sf::sf_use_s2(TRUE)

  friction_data <-
    bb_area |>
    friction(
      mode = mode,
      res_output = res_output,
      dowscaling_model_type = dowscaling_model_type,
      cache = cache,
      file = file
    )

  points <-
    facilities |>
    facilities_coordinates(bb_area) |>
    as.matrix()

  cli::cli_progress_step("Computing travel time map")

  # Run the accumulated cost algorithm to make the final output map.
  # This can be quite slow (potentially hours).
  travel_time <-
    friction_data[[3]] |>
    gdistance::accCost(points) |>
    as_stars_raster() |>
    mask_raster_to_polygon(bb_area)

  sf::st_crs(travel_time) <- sf::st_crs(4326)

  list(
    travel_time = travel_time,
    friction = friction_data
  ) |>
    `class<-`(c("traveltime", "list")) |>
    invisible()
}
