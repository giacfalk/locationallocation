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

  out <- as_spatraster(ras)

  if (inherits(mask, c("sf", "sfc"))) {
    assert_bb_area(mask)

    if (!is.na(sf::st_crs(mask)) && terra::crs(out) != "") {
      mask <- sf::st_transform(mask, terra::crs(out))
    }

    mask <- terra::vect(mask)
    terra::crs(mask) <- terra::crs(out)
    mask <- terra::crop(mask, terra::ext(out))
  } else {
    mask <- as_spatraster(mask)
    terra::crs(mask) <- terra::crs(out)
  }

  out <- terra::mask(
    out,
    mask,
    inverse = inverse,
    updatevalue = updatevalue
  )

  if (inherits(ras, "RasterLayer")) raster::raster(out) else out
}
