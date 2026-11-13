#' Download and downscale a friction surface layer
#'
#' @description
#'
#' `friction()` retrieves a
#' [friction surface](https://en.wikipedia.org/wiki/Friction_of_distance) layer
#' from the Malaria Atlas Project ([MAP](https://malariaatlas.org/)) database
#' (Hay et al., 2006; Weiss et al., 2020) and optionally downscales it to the
#' spatial resolution of the analysis using road network data from
#' OpenStreetMap ([OSM](https://www.openstreetmap.org/)).
#'
#' Friction values are expressed in minutes required to travel one meter.
#'
#' An internet connection is required, unless a local friction surface is
#' supplied via `file` and no downscaling is requested (`res_output >= 1000`).
#'
#' @details
#'
#' ## Downscaling
#'
#' When `res_output < 1000`, the ~1 km MAP friction surface is downscaled with
#' [`dissever`][dissever::dissever()], using the density of the OSM road
#' network (computed on a grid of `res_output` meters in the local UTM zone)
#' as a covariate. Because the downscaling is mass-preserving, it can push the
#' friction of road cells below the fastest speed present in the original
#' surface (e.g., faster than walking in `"walk"` mode). The downscaled values
#' are therefore bounded below by the minimum friction of the original surface
#' within the area of interest.
#'
#' When `res_output >= 1000`, the friction surface is used at its native
#' resolution (30 arc-seconds, ~1 km).
#'
#' @template params-bb-area
#' @param mode (optional) A [`character`][base::character()] string indicating
#'   the mode of transport. Options are `"fastest"` and `"walk"` (default:
#'   `"walk"`).
#'   - For `"fastest"`: The friction layer accounts for multiple modes of
#'   transport, including walking, cycling, driving, and public transport, and
#'   is based on the Malaria Atlas Project (2015) *Global Travel Speed Friction
#'   Surface*.
#'   - For `"walk"`: The friction layer accounts only for walking speeds and is
#'   based on the Malaria Atlas Project (2020) *Global Walking Only Friction
#'   Surface*.
#' @param dowscaling_model_type (optional) A [`character`][base::character()]
#'   string indicating the type of model used for the spatial downscaling of the
#'   friction layer. Options are `"lm"` (linear model) and `"rf"` (random
#'   forest) (default: `"lm"`).
#' @param res_output (optional) A positive
#'   [integerish][checkmate::test_integerish()] number indicating the spatial
#'   resolution of the friction raster (and of the analysis), in meters. If the
#'   resolution is less than `1000`, a spatial downscaling approach is used
#'   (default: `100`).
#' @template params-cache
#' @template params-file
#'
#' @return An [invisible][base::invisible] [`list`][base::list] with the
#'   following elements:
#'   - `friction_layer`: A [`RasterLayer`][raster::raster()] object with the
#'   friction surface layer (minutes per meter).
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
#' Weiss, D. J., Nelson, A., Vargas-Ruiz, C. A., Gligorić, K., Bavadekar, S.,
#' Gabrilovich, E., Bertozzi-Villa, A., Rozier, J., Gibson, H. S., Shekel, T.,
#' Kamath, C., Lieber, A., Schulman, K., Shao, Y., Qarkaxhija, V., Nandi, A.
#' K., Keddie, S. H., Rumisha, S., Amratia, P., ... Gething, P. W. (2020).
#' Global maps of travel time to healthcare facilities. *Nature Medicine*,
#' *26*(12), 1835–1838. \doi{10.1038/s41591-020-1059-1}
#'
#' Malaria Atlas Project. (2015). *Friction surface: Global travel speed
#' friction surface* (Version 201501).
#' \url{https://data.malariaatlas.org/maps}
#'
#' Malaria Atlas Project. (2020). *Friction surface: Global walking only
#' friction surface* (Version 202001).
#' \url{https://data.malariaatlas.org/maps}
#'
#' OpenStreetMap Foundation. (n.d.). *OpenStreetMap* \[Computer software\].
#' \url{https://www.openstreetmap.org}
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
  checkmate::assert_count(res_output, positive = TRUE)
  checkmate::assert_flag(cache)
  checkmate::assert_string(file, null.ok = TRUE)
  if (!is.null(file)) checkmate::assert_file_exists(file)

  if (is.null(file) || res_output < 1000) assert_internet()

  bb_area <- as_wgs84(bb_area)

  if (!is.null(file)) {
    cli::cli_progress_step("Using user-provided friction data file")

    friction_layer <- terra::rast(file)

    friction_layer <-
      friction_layer |>
      crop_to_area(bb_area) |>
      raster::raster() |>
      as_raster_layer(name = "file")
  } else {
    dataset <- switch(
      mode,
      fastest = "Accessibility__201501_Global_Travel_Speed_Friction_Surface",
      walk = "Accessibility__202001_Global_Walking_Only_Friction_Surface"
    )

    if (isTRUE(cache)) {
      friction_layer <- get_cache_data(dataset, bb_area)
    } else {
      cli::cli_progress_step(
        "Downloading friction data from the Malaria Atlas Project"
      )

      friction_layer <-
        dataset |>
        malariaAtlas::getRaster(
          extent = matrix(sf::st_bbox(bb_area), ncol = 2)
        ) |>
        quietly() |>
        raster::raster()
    }
  }

  names(friction_layer) <- "friction"

  if (res_output < 1000) {
    friction_layer <-
      friction_layer |>
      downscale_friction(
        bb_area = bb_area,
        res_output = res_output,
        dowscaling_model_type = dowscaling_model_type
      )
  }

  cli::cli_progress_step("Computing transition matrix and geocorrection")

  transition_matrix <-
    friction_layer |>
    # RAM intensive, can be very slow for large areas.
    gdistance::transition(\(x) 1 / mean(x), 16)

  geocorrection_matrix <- gdistance::geoCorrection(transition_matrix)

  cli::cli_progress_done()

  list(
    friction_layer = friction_layer,
    transition_matrix = transition_matrix,
    geocorrection_matrix = geocorrection_matrix
  ) |>
    invisible()
}

downscale_friction <- function(
  friction_layer,
  bb_area,
  res_output,
  dowscaling_model_type
) {
  cli::cli_progress_step("Downloading road network data from OpenStreetMap")

  roads <-
    bb_area |>
    sf::st_bbox() |>
    osmdata::opq(timeout = 300) |>
    osmdata::add_osm_feature(key = "highway") |>
    osmdata::osmdata_sf() |>
    magrittr::extract2("osm_lines")

  if (is.null(roads) || nrow(roads) == 0) {
    cli::cli_warn(
      paste0(
        "No OpenStreetMap roads found within {.strong bb_area}. ",
        "The friction surface is used at its native resolution."
      )
    )

    return(friction_layer)
  }

  cli::cli_progress_step("Downscaling the friction surface")

  utm <- sf::st_crs(utm_epsg(bb_area))

  # Road density (sum of overlapping road buffers) on a grid of `res_output`
  # meters in the local UTM zone.
  grid_utm <-
    friction_layer |>
    terra::rast() |>
    terra::ext() |>
    terra::vect(crs = "EPSG:4326") |>
    terra::project(utm$wkt) |>
    terra::rast(resolution = res_output)

  road_density <-
    roads |>
    sf::st_transform(utm) |>
    sf::st_buffer(res_output) |>
    terra::vect() |>
    terra::rasterize(grid_utm, background = 0, fun = "sum") |>
    terra::project("EPSG:4326")

  road_density <- terra::ifel(
    is.na(road_density) | road_density < 0,
    0,
    road_density
  )

  road_density <-
    road_density |>
    raster::raster() |>
    raster::crop(friction_layer)

  # `dissever()` needs at least two covariates (a single covariate is
  # silently dropped to a vector inside `caret`), hence the duplicated layer.
  covariates <- raster::stack(road_density, road_density)
  names(covariates) <- c("l1", "l2")

  coarse_values <- raster::values(friction_layer)
  min_friction <- min(coarse_values, na.rm = TRUE)

  if (length(unique(stats::na.omit(coarse_values))) == 1) {
    # `dissever()` cannot fit a model to a constant layer.
    raster::values(friction_layer) <- stats::runif(
      n = length(coarse_values),
      min = min_friction * 0.9,
      max = min_friction * 1.1
    )
  }

  map <- dissever::dissever(
    coarse = friction_layer,
    fine = covariates,
    method = dowscaling_model_type,
    p = 0.5,
    min_iter = 2,
    max_iter = 10,
    verbose = FALSE
  ) |>
    magrittr::extract2("map")

  # Mass-preserving downscaling can produce friction values below the fastest
  # speed observed in the original surface (e.g., faster than walking in
  # `"walk"` mode). Bound them by the original minimum.
  raster::values(map) <- pmax(raster::values(map), min_friction)
  names(map) <- "friction"

  map
}
