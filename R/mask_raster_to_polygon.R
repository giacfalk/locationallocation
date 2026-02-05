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
  ras <- as_stars_if_needed(ras)
  if (inherits(mask, "Raster")) {
    mask <- as_stars_if_needed(mask)
  }

  checkmate::assert_class(ras, "stars")
  checkmate::assert_multi_class(mask, c("stars", "sf"))
  checkmate::assert_flag(inverse)
  checkmate::assert_atomic(updatevalue, len = 1)

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

  if (inverse) {
    stars::st_mask(ras, mask, invert = TRUE, update = updatevalue)
  } else {
    stars::st_mask(ras, mask, update = updatevalue)
  }
}
