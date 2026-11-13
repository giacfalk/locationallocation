#' Mask a raster to a polygon or to another raster
#'
#' @description
#'
#' `mask_raster_to_polygon()` sets to `updatevalue` (default: `NA`) all cells
#' of a raster that fall outside a [`sf`][sf::st_as_sf()] polygon (or that are
#' `NA` in another raster).
#'
#' @param ras A [`RasterLayer`][raster::raster()] or
#'   [`SpatRaster`][terra::rast()] object.
#' @param mask A [`sf`][sf::st_as_sf()] object with `POLYGON` or
#'   `MULTIPOLYGON` geometries, or a [`RasterLayer`][raster::raster()] or
#'   [`SpatRaster`][terra::rast()] object with the same geometry as `ras`.
#' @param inverse (optional) A [`logical`][base::logical()] flag. If `TRUE`,
#'   the mask is inverted, i.e., cells *inside* the polygon are masked
#'   (default: `FALSE`).
#' @param updatevalue (optional) The value assigned to the masked cells
#'   (default: `NA`).
#'
#' @return A masked raster of the same class as `ras`.
#'
#' @family utility functions
#' @keywords masking
#' @export
#'
#' @examples
#' naples_population |> mask_raster_to_polygon(naples_shape)
mask_raster_to_polygon <- function(
  ras,
  mask,
  inverse = FALSE,
  updatevalue = NA
) {
  checkmate::assert_multi_class(ras, c("RasterLayer", "SpatRaster"))
  checkmate::assert_multi_class(mask, c("Raster", "SpatRaster", "sf", "sfc"))
  checkmate::assert_flag(inverse)
  checkmate::assert_atomic(updatevalue, len = 1)

  if (inherits(mask, c("sf", "sfc"))) {
    assert_bb_area(mask)
    keep <- inside_polygon(ras, mask)
  } else {
    keep <- !is.na(cell_values(mask))
  }

  if (isTRUE(inverse)) keep <- !keep

  values <- cell_values(ras)
  values[!keep] <- updatevalue

  if (inherits(ras, "RasterLayer")) {
    raster::setValues(ras, values)
  } else {
    terra::setValues(ras, values)
  }
}

# Values of the cells of a `RasterLayer` or single-layer `SpatRaster`.
cell_values <- function(x) {
  if (inherits(x, "SpatRaster")) {
    terra::values(x, mat = FALSE)
  } else {
    raster::values(x)
  }
}

# A `SpatRaster` with the geometry (but not the values) of `x`.
raster_template <- function(x) {
  if (inherits(x, "SpatRaster")) {
    return(terra::rast(x))
  }

  crs <- raster::crs(x)

  terra::rast(
    nrows = raster::nrow(x),
    ncols = raster::ncol(x),
    xmin = raster::xmin(x),
    xmax = raster::xmax(x),
    ymin = raster::ymin(x),
    ymax = raster::ymax(x),
    crs = if (is.na(crs)) "" else raster::wkt(x)
  )
}

# Whether each cell of `x` is inside or touched by `polygon` (the rule used by
# `terra::mask()` with a polygon, whose `touches` argument defaults to `TRUE`).
inside_polygon <- function(x, polygon) {
  template <- raster_template(x)

  if (!is.na(sf::st_crs(polygon)) && terra::crs(template) != "") {
    polygon <- sf::st_transform(polygon, terra::crs(template))
  }

  vector <- terra::vect(polygon)
  terra::crs(vector) <- terra::crs(template)

  vector |>
    terra::rasterize(template, touches = TRUE) |>
    terra::values(mat = FALSE) |>
    is.na() |>
    magrittr::not()
}
