#' Download a friction surface at the resolution of the analysis
#'
#' @description
#'
#' `friction()` retrieves a
#' [friction surface](https://en.wikipedia.org/wiki/Friction_of_distance) layer
#' from the Malaria Atlas Project ([MAP](https://malariaatlas.org/)) database
#' (Hay et al., 2006; Weiss et al., 2018, 2020) and produces it at the spatial
#' resolution of the analysis, following the rules used to build the MAP
#' surfaces.
#'
#' Friction values are expressed in minutes required to travel one meter.
#'
#' An internet connection is required, unless the data are supplied via
#' `file` and `roads`, or were cached by a previous call with `cache = TRUE`.
#'
#' @details
#'
#' ## Spatial resolution
#'
#' The MAP surfaces have a resolution of 30 arc-seconds (~1 km). When
#' `res_output >= 1000`, the surface of the chosen `mode` is used at its
#' native resolution.
#'
#' When `res_output < 1000`, the surface is produced on a grid of about
#' `res_output` meters following the rule used to build the MAP surfaces:
#' within each cell, the fastest mode of transport takes precedence (Weiss et
#' al., 2018).
#'
#' - `mode = "walk"`: MAP assigns the same walking speed (5 km/h) to roads and
#'   to urban land, so the road network adds no information at a finer
#'   resolution. The walking-only surface is resampled to the finer grid
#'   (nearest neighbor) without changing its values.
#' - `mode = "fastest"`: cells crossed by a road get the speed of the fastest
#'   road crossing them (see `road_speeds`). All other cells get the friction
#'   of the MAP walking-only surface, which accounts for land cover and slope.
#'   Railways, ferries and congestion are not modeled.
#'
#' The road network is downloaded from OpenStreetMap
#' ([OSM](https://www.openstreetmap.org/)) through the Overpass API, unless it
#' is supplied via `roads`.
#'
#' ## Example data
#'
#' The package includes a copy of the MAP walking-only friction surface for
#' the area of [`naples_shape`] (`naples-friction-walk.tif`, see the
#' examples), used to run the examples offline. Source: Malaria Atlas
#' Project (2020); see <https://data.malariaatlas.org> for the terms of use.
#'
#' ## Online data and fallbacks
#'
#' Online services can be unavailable or overloaded. The friction surface is
#' obtained from the first available of these sources:
#'
#' 1. With `cache = TRUE`, the surface of the area cached by a previous call,
#'    or a cached copy of the global surface.
#' 2. The MAP data service (retried once).
#' 3. With `cache = TRUE`, a one-time download of the global surface (~730 MB)
#'    from a mirror on the Open Science Framework ([OSF](https://osf.io/)),
#'    which is then cached.
#'
#' If none is available, the error message suggests downloading the global
#' surface manually and supplying it via `file`.
#'
#' The road network is obtained from the cache (with `cache = TRUE`) or from
#' several public Overpass API servers in turn (each with a single attempt of
#' at most ~2.5 minutes), skipping those that are unreachable or at capacity.
#' If none responds, a warning is issued and the MAP travel speed surface
#' (~1 km) is used on the finer grid instead.
#'
#' Cached data are stored in [`tools::R_user_dir("locationallocation",
#' "cache")`][tools::R_user_dir()]. The following options change the default
#' behavior:
#'
#' - `locationallocation.cache_dir`: the cache directory.
#' - `locationallocation.overpass_urls`: the Overpass API servers to try, in
#'   order.
#' - `locationallocation.retry_wait`: the number of seconds to wait before
#'   retrying a failed download (default: `30`).
#'
#' @template params-bb-area
#' @param mode (optional) A [`character`][base::character()] string indicating
#'   the mode of transport. Options are `"fastest"` and `"walk"` (default:
#'   `"walk"`).
#'   - For `"fastest"`: The friction layer accounts for multiple modes of
#'   transport, including walking and driving. At the native resolution, it
#'   is the Malaria Atlas Project (2015) *Global Travel Speed Friction
#'   Surface*.
#'   - For `"walk"`: The friction layer accounts only for walking speeds and is
#'   based on the Malaria Atlas Project (2020) *Global Walking Only Friction
#'   Surface*.
#' @param dowscaling_model_type Deprecated and ignored. The friction surface
#'   is no longer downscaled with a statistical model (see *Details*).
#' @param res_output (optional) A positive
#'   [integerish][checkmate::test_integerish()] number indicating the spatial
#'   resolution of the friction raster (and of the analysis), in meters. See
#'   *Details* (default: `100`).
#' @template params-cache
#' @template params-file
#' @param roads (optional) A [`sf`][sf::st_as_sf()] object with the road
#'   network (`LINESTRING` or `MULTILINESTRING` geometries), used when
#'   `mode = "fastest"` and `res_output < 1000`. It must have either a
#'   `speed` column with speeds in km/h, or a `highway` column with
#'   OpenStreetMap road classes, which are converted to speeds with
#'   `road_speeds`. If `NULL`, the road network is downloaded from
#'   OpenStreetMap (default: `NULL`).
#' @param road_speeds (optional) A named [`numeric`][base::numeric()] vector
#'   with the speed (km/h) of each OpenStreetMap road class (`highway` tag).
#'   Road classes not in `road_speeds` are ignored (default:
#'   [`default_road_speeds()`][default_road_speeds()]).
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
#' @keywords spatial
#' @export
#'
#' @references
#'
#' Hay, S. I., & Snow, R. W. (2006). The Malaria Atlas Project: Developing
#' global maps of malaria risk. *PLOS Medicine*, *3*(12), e473.
#' \doi{10.1371/journal.pmed.0030473}
#'
#' Weiss, D. J., Nelson, A., Gibson, H. S., Temperley, W., Peedell, S., Lieber,
#' A., Hancher, M., Poyart, E., Belchior, S., Fullman, N., Mappin, B.,
#' Dalrymple, U., Rozier, J., Lucas, T. C. D., Howes, R. E., Tusting, L. S.,
#' Kang, S. Y., Cameron, E., Bisanzio, D., ... Gething, P. W. (2018). A global
#' map of travel time to cities to assess inequalities in accessibility in
#' 2015. *Nature*, *553*(7688), 333–336. \doi{10.1038/nature25181}
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
#' # Offline example with a bundled copy of the walking surface for Naples
#' friction_file <- system.file(
#'   "extdata", "naples-friction-walk.tif",
#'   package = "locationallocation"
#' )
#'
#' friction_data <-
#'   naples_shape |>
#'   friction(res_output = 1000, file = friction_file)
#'
#' friction_data$friction_layer
#'
#' \dontrun{
#' # Download the surfaces (requires an internet connection)
#' naples_shape |> friction()
#'
#' naples_shape |> friction(mode = "fastest", cache = TRUE)
#' }
friction <- function(
  bb_area,
  mode = "walk",
  dowscaling_model_type = NULL,
  res_output = 100,
  cache = FALSE,
  file = NULL,
  roads = NULL,
  road_speeds = default_road_speeds()
) {
  assert_bb_area(bb_area)
  checkmate::assert_choice(mode, choices = c("walk", "fastest"))
  checkmate::assert_count(res_output, positive = TRUE)
  checkmate::assert_flag(cache)
  checkmate::assert_string(file, null.ok = TRUE)
  if (!is.null(file)) checkmate::assert_file_exists(file)
  assert_roads(roads, null_ok = TRUE)
  checkmate::assert_numeric(
    road_speeds,
    lower = 0,
    finite = TRUE,
    any.missing = FALSE,
    min.len = 1,
    names = "unique"
  )
  warn_dowscaling_model_type(dowscaling_model_type)

  bb_area <- as_wgs84(bb_area)

  if (res_output >= 1000) {
    friction_layer <- map_friction(mode, bb_area, cache, file)
  } else if (mode == "walk") {
    friction_layer <-
      map_friction("walk", bb_area, cache, file) |>
      fine_friction(bb_area, res_output)
  } else {
    if (is.null(roads)) {
      roads <- tryCatch(
        osm_roads(bb_area, names(road_speeds), cache),
        error = function(e) e
      )
    }

    if (inherits(roads, "error")) {
      cli::cli_warn(
        c(
          "The OpenStreetMap road network could not be downloaded.",
          "x" = cli_escape(conditionMessage(roads)),
          "i" = paste0(
            "Using the Malaria Atlas Project travel speed surface (~1 km) ",
            "on the {res_output} m grid instead."
          ),
          "i" = paste0(
            "Supply the road network via {.arg roads}, or try again later ",
            "(with {.code cache = TRUE}, a successful download is cached)."
          )
        )
      )

      friction_layer <-
        map_friction("fastest", bb_area, cache) |>
        fine_friction(bb_area, res_output)
    } else {
      friction_layer <-
        map_friction("walk", bb_area, cache, file) |>
        fine_friction(bb_area, res_output, roads, road_speeds)
    }
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

#' Default speeds of OpenStreetMap road classes
#'
#' @description
#'
#' `default_road_speeds()` returns the default speed (km/h) of each
#' OpenStreetMap road class (`highway` tag), used by
#' [`friction()`][friction()] with `mode = "fastest"` to build friction
#' surfaces finer than the native resolution of the Malaria Atlas Project
#' surfaces.
#'
#' The values are the free-flow speeds of the car profile of the Open Source
#' Routing Machine ([OSRM](https://project-osrm.org/)). They do not account
#' for congestion, and can be modified and passed to the `road_speeds`
#' argument of [`friction()`][friction()] and [`traveltime()`][traveltime()].
#'
#' @return A named [`numeric`][base::numeric()] vector of speeds in km/h.
#'
#' @family travel time functions
#' @keywords spatial
#' @export
#'
#' @examples
#' default_road_speeds()
#'
#' # Slower urban speeds
#' speeds <- default_road_speeds()
#' speeds[c("primary", "secondary")] <- c(40, 30)
default_road_speeds <- function() {
  c(
    motorway = 90,
    motorway_link = 45,
    trunk = 85,
    trunk_link = 40,
    primary = 65,
    primary_link = 30,
    secondary = 55,
    secondary_link = 25,
    tertiary = 40,
    tertiary_link = 20,
    unclassified = 25,
    residential = 25,
    living_street = 10,
    service = 15
  )
}

# Friction surface on a grid of about `res_output` meters. The coarse surface
# is resampled to the grid; with `roads`, cells crossed by a road get the speed
# of the fastest road crossing them, unless it is slower than the surface.
fine_friction <- function(
  coarse,
  bb_area,
  res_output,
  roads = NULL,
  road_speeds = default_road_speeds()
) {
  cli::cli_progress_step(
    "Resampling the friction surface to {res_output} meters"
  )

  lat <- mean(c(raster::ymin(coarse), raster::ymax(coarse)))

  grid <- terra::rast(
    terra::ext(terra::rast(coarse)),
    resolution = c(
      res_output / (111320 * cos(lat * pi / 180)),
      res_output / 110574
    ),
    crs = "EPSG:4326"
  )

  values <- grid_values(coarse, grid)

  if (!is.null(roads)) {
    road_speed <- rasterize_road_speeds(roads, grid, road_speeds)

    if (all(is.na(road_speed))) {
      cli::cli_warn(
        paste0(
          "No roads with a known speed were found within ",
          "{.strong bb_area}. Only walking speeds are used."
        )
      )
    }

    # The fastest mode of transport takes precedence.
    values <- pmin(values, 0.06 / road_speed, na.rm = TRUE)
  }

  out <- raster::raster(terra::setValues(grid, values))
  names(out) <- "friction"

  out
}

# Speed (km/h) of the fastest road crossing each cell of `grid` (`NA` where
# there are no roads).
rasterize_road_speeds <- function(roads, grid, road_speeds) {
  roads <- sf::st_transform(sf::st_as_sf(roads), 4326)

  if ("speed" %in% names(roads)) {
    speed <- as.numeric(roads$speed)
  } else {
    speed <- unname(road_speeds[as.character(roads$highway)])
  }

  roads <- roads[!is.na(speed) & speed > 0, ]
  speed <- speed[!is.na(speed) & speed > 0]
  out <- rep(NA_real_, terra::ncell(grid))

  for (value in sort(unique(speed))) {
    crossed <-
      roads[speed == value, ] |>
      terra::vect() |>
      terra::rasterize(grid, touches = TRUE) |>
      terra::values(mat = FALSE) |>
      is.na()

    out[!crossed] <- value
  }

  out
}

warn_dowscaling_model_type <- function(dowscaling_model_type) {
  if (!is.null(dowscaling_model_type)) {
    cli::cli_warn(
      paste0(
        "{.strong dowscaling_model_type} is deprecated and ignored: the ",
        "friction surface is no longer downscaled with a statistical model. ",
        "See {.code ?friction}."
      ),
      .frequency = "regularly",
      .frequency_id = "dowscaling_model_type"
    )
  }

  invisible(TRUE)
}
