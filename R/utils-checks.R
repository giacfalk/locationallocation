assert_bb_area <- function(x, null_ok = FALSE) {
  checkmate::assert_flag(null_ok)

  if (is.null(x) && isTRUE(null_ok)) {
    return(invisible(TRUE))
  }

  name <- deparse(substitute(x)) #nolint

  if (
    !inherits(x, c("sf", "sfc")) ||
      length(sf::st_geometry(x)) == 0 ||
      !all(
        as.character(sf::st_geometry_type(x)) %in%
          c("POLYGON", "MULTIPOLYGON")
      )
  ) {
    cli::cli_abort(
      paste0(
        "{.strong {cli::col_red(name)}} ",
        "must be a non-empty {.strong sf} object with ",
        "{.strong POLYGON} or {.strong MULTIPOLYGON} geometries."
      )
    )
  }

  invisible(TRUE)
}

assert_facilities <- function(x, null_ok = FALSE) {
  checkmate::assert_flag(null_ok)

  if (is.null(x) && isTRUE(null_ok)) {
    return(invisible(TRUE))
  }

  name <- deparse(substitute(x)) #nolint

  if (
    !inherits(x, c("sf", "sfc")) ||
      length(sf::st_geometry(x)) == 0 ||
      !all(as.character(sf::st_geometry_type(x)) == "POINT")
  ) {
    cli::cli_abort(
      paste0(
        "{.strong {cli::col_red(name)}} ",
        "must be a non-empty {.strong sf} object with ",
        "{.strong POINT} geometries."
      )
    )
  }

  invisible(TRUE)
}

assert_traveltime <- function(x, null_ok = FALSE) {
  checkmate::assert_flag(null_ok)

  if (is.null(x) && isTRUE(null_ok)) {
    return(invisible(TRUE))
  }

  name <- deparse(substitute(x)) #nolint

  if (!inherits(x, "traveltime")) {
    cli::cli_abort(
      paste0(
        "{.strong {cli::col_red(name)}} ",
        "must be an output object from the ",
        "{.strong {cli::col_blue('traveltime()')}} ",
        "function."
      )
    )
  }

  invisible(TRUE)
}

assert_allocation <- function(x) {
  name <- deparse(substitute(x)) #nolint

  if (!inherits(x, c("allocation", "allocation_discrete"))) {
    cli::cli_abort(
      paste0(
        "{.strong {cli::col_red(name)}} ",
        "must be an output object from either the ",
        "{.strong allocation()} or ",
        "{.strong allocation_discrete()} function."
      )
    )
  }

  invisible(TRUE)
}

assert_internet <- function() {
  if (!curl::has_internet()) {
    cli::cli_abort(
      paste0(
        "An {.strong {cli::col_red('internet connection')}} ",
        "is required to run this function."
      )
    )
  }

  invisible(TRUE)
}

# Coerce a `RasterLayer` or single-layer `SpatRaster` to a `RasterLayer` in
# geographic coordinates (the CRS of the friction surfaces).
as_raster_layer <- function(x, name = deparse(substitute(x)), null_ok = FALSE) {
  if (is.null(x) && isTRUE(null_ok)) {
    return(NULL)
  }

  if (inherits(x, "SpatRaster")) {
    if (terra::nlyr(x) != 1) {
      cli::cli_abort(
        "{.strong {cli::col_red(name)}} must have a single layer."
      )
    }

    x <- raster::raster(x)
  }

  if (!inherits(x, "RasterLayer")) {
    cli::cli_abort(
      paste0(
        "{.strong {cli::col_red(name)}} must be a ",
        "{.strong RasterLayer} or a single-layer {.strong SpatRaster}."
      )
    )
  }

  if (!is.na(raster::crs(x)) && !raster::isLonLat(x)) {
    cli::cli_abort(
      paste0(
        "{.strong {cli::col_red(name)}} must be in geographic ",
        "coordinates (longitude/latitude, WGS 84 / EPSG:4326), the CRS ",
        "of the friction surfaces. Reproject it first, e.g. with ",
        "{.code terra::project(x, \"EPSG:4326\", method = \"sum\")} ",
        "for counts."
      ),
      wrap = TRUE
    )
  }

  x
}

# Transform `sf`/`sfc` objects to WGS 84 (EPSG:4326), the CRS of the friction
# surfaces, and return an `sf` object.
as_wgs84 <- function(x, name = deparse(substitute(x))) {
  if (is.null(x)) {
    return(NULL)
  }

  if (is.na(sf::st_crs(x))) {
    cli::cli_abort(
      "{.strong {cli::col_red(name)}} must have a defined CRS."
    )
  }

  if (inherits(x, "sfc")) x <- sf::st_as_sf(x)

  if (!isTRUE(sf::st_crs(x) == sf::st_crs(4326))) {
    x <- sf::st_transform(x, 4326)
  }

  x
}
