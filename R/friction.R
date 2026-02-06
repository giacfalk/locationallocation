#' Download and downscale a friction surface layer
#'
#' @description
#'
#' `friction()` retrieves a
#' [friction surface](https://en.wikipedia.org/wiki/Friction_of_distance) layer
#' from the Malaria Atlas Project ([MAP](https://malariaatlas.org/)) database
#' (Hay et al., 2006; Malaria Atlas Project, 2015, 2019) and optionally
#' resample it to the spatial resolution of the analysis using `stars`.
#'
#' This function requires an active internet connection.
#'
#' @template params-bb-area
#' @param mode (optional) A [`character`][base::character()] string indicating
#'   the mode of transport. Options are `"fastest"` and `"walk"` (default =
#'   `"walk"`).
#'   - For `"fastest"`: The friction layer accounts for multiple modes of
#' transport, including walking, cycling, driving, and public transport, and are
#' based on the Malaria Atlas Project (2019) *Global Travel Speed Friction
#' Surface*.
#'   - For `"walk"`: The friction layer accounts only for walking speeds and is
#'  based on the Malaria Atlas Project (2015) *Global Walking Only Friction
#'  Surface*.
#' @param dowscaling_model_type (optional) A [`character`][base::character()]
#'   string indicating the type of model used for the spatial downscaling of the
#'   friction layer. Options are `"lm"` (linear model) and `"rf"` (random
#'   forest) (default: `"lm"`). This argument is retained for compatibility; the
#'   current implementation resamples the friction layer using `stars`.
#' @param res_output (optional) A positive
#'   [integerish][checkmate::test_integerish()] number indicating the spatial
#'   resolution of the friction layer (and of the analysis), in meters. If the
#'   resolution is less than `1000`, a spatial downscaling approach is used
#'   (default: `100`).
#' @template params-cache
#' @template params-file
#'
#' @return An [invisible][base::invisible] [`list`][base::list] with the
#'   following elements:
#'   - `friction_layer`: A [`stars`][stars::st_as_stars()] object with the
#'   friction surface layer.
#'   - `transition_matrix`: A [`TransitionLayer`][gdistance::transition()] with
#'   the transition matrix for cost-distance calculations.
#'   - `geocorrection_matrix`: A [`TransitionLayer`][gdistance::transition()]
#'   with the geocorrection matrix for accurate distance calculations.
#'
#' @family travel time functions
#' @keywords cats
#' @export
#'
#' @references
#'
#' Hay, S. I., & Snow, R. W. (2006). The Malaria Atlas Project: Developing
#' global maps of malaria risk. *PLOS Medicine*, *3*(12), e473.
#' \doi{10.1371/journal.pmed.0030473}
#'
#' Malaria Atlas Project. (2015). *Friction surface: Global travel speed
#' friction surface* (Version 201501).
#' \url{https://data.malariaatlas.org/maps}
#'
#' Malaria Atlas Project. (2019). *Friction surface: Global walking only
#' friction surface* (Version 202001).
#' \url{https://data.malariaatlas.org/maps}
#'
#' @examples
#' \dontrun{
#'   naples_shape |> friction()
#' }
friction <- function(
  bb_area,
  mode = "walk",
  dowscaling_model_type = "lm",
  res_output = 100,
  cache = FALSE,
  file = NULL
) {
  assert_bb_area(bb_area)
  checkmate::assert_choice(mode, choices = c("walk", "fastest"))
  checkmate::assert_choice(dowscaling_model_type, choices = c("lm", "rf"))
  checkmate::assert_count(res_output)
  checkmate::assert_flag(cache)
  checkmate::assert_string(file, null.ok = TRUE)
  assert_internet()

  handle <- curl::new_handle(timeout = 120)

  if (!is.null(file)) {
    cli::cli_progress_step("Using user-provided friction data file")

    checkmate::assert_file_exists(file)

    friction_layer <- stars::read_stars(file)

    bb_area_transformed <- sf::st_transform(bb_area, sf::st_crs(friction_layer))

    friction_layer <- stars::st_crop(friction_layer, bb_area_transformed)
  } else {
    if (mode == "fastest") {
      dataset <- "Accessibility__201501_Global_Travel_Speed_Friction_Surface"
    } else if (mode == "walk") {
      dataset <- "Accessibility__202001_Global_Walking_Only_Friction_Surface"
    }

    if (isTRUE(cache)) {
      friction_layer <- get_cache_data(dataset, bb_area)
    } else {
      cli::cli_progress_step(
        "Downloading friction data from the Malaria Atlas Project"
      )

      friction_layer <-
        dataset |>
        malariaAtlas::getRaster(
          extent = matrix(sf::st_bbox(bb_area), ncol = 2),
        ) |>
        as_stars_raster()
    }
  }

  if (res_output < 1000) {
    cli::cli_progress_step("Resampling friction layer to target resolution")

    friction_projected <- stars::st_warp(
      friction_layer,
      crs = sf::st_crs(3395)
    )

    friction_projected <- stars::st_warp(
      friction_projected,
      cellsize = res_output
    )

    friction_layer <- stars::st_warp(
      friction_projected,
      crs = sf::st_crs(4326)
    )
  } else {
    friction_layer <- friction_layer
  }

  cli::cli_progress_step("Computing transition matrix and geocorrection")

  transition_matrix <-
    friction_layer |>
    # RAM intensive, can be very slow for large areas.
    gdistance::transition(\(x) 1 / mean(x), 16)

  geocorrection_matrix <- gdistance::geoCorrection(transition_matrix)

  list(
    friction_layer = friction_layer,
    transition_matrix = transition_matrix,
    geocorrection_matrix = geocorrection_matrix
  ) |>
    invisible()
}
