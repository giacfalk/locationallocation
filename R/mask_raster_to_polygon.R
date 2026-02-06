#' Mask a `stars` object to a `sf` object
#'
#' @description
#'
#' This function rapidly masks a [`stars`][stars::st_as_stars()] object to
#' a [`sf`][sf::st_as_sf()] object.
#'
#' @param ras A [`stars`][stars::st_as_stars()] object.
#' @param mask A [`stars`][stars::st_as_stars()] or [`sf`][sf::st_as_sf()]
#'   object.
#' @param inverse A [`logical`][base::logical()] flag. If `TRUE`, the mask
#'   is inverted (default: `FALSE`).
#' @param updatevalue The value to update the [`stars`][stars::st_as_stars()]
#'   object with (default: `NA`).
#'
#' @return A masked [`stars`][stars::st_as_stars()] object.
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
  checkmate::assert_class(ras, "stars")
  checkmate::assert_multi_class(mask, c("stars", "sf"))
  checkmate::assert_flag(inverse)
  checkmate::assert_atomic(updatevalue, len = 1)

  ras <- as_stars_raster(ras)

  if (inherits(mask, "stars")) {
    mask <- stars::st_as_sf(mask)
  }

  if (inherits(mask, "sf")) {
    test <-
      mask |>
      sf::st_geometry_type() |>
      as.character() |>
      magrittr::is_in(c("POLYGON", "MULTIPOLYGON"))

    if (isFALSE(test)) {
      cli::cli_abort(
        paste0(
          "The {.strong {cli::col_red('mask')}} parameter ",
          "must be a {.strong sf} object of type ",
          "{.strong POLYGON} or {.strong MULTIPOLYGON}."
        )
      )
    }

    mask <-
      mask |>
      sf::st_crop(sf::st_bbox(ras)) |>
      sf::st_cast()
  }

  mask <- sf::st_transform(mask, sf::st_crs(ras))

  out <- stars::st_crop(ras, mask)
  out <- stars::st_mask(out, mask, inverse = inverse)

  if (!is.na(updatevalue)) {
    values <- stars_values(out)
    values[is.na(values)] <- updatevalue
    out <- stars_set_values(out, values)
  }

  out
}
