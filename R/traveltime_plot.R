#' Plot results of the `traveltime()` function
#'
#' @description
#'
#' `traveltime_plot()` plots the results of the [`traveltime()`][traveltime()]
#' function, showing the travel time to the nearest facility across the area
#' of interest.
#'
#' @template params-traveltime-a
#' @template params-bb-area
#' @param facilities (optional) A [`sf`][sf::st_as_sf()] object with the
#'   facilities to plot (default: `NULL`).
#' @param contour_traveltime (optional) A [`numeric`][base::numeric()] vector
#'   indicating the travel time thresholds (in minutes) at which to draw
#'   contour lines, or `NULL` for no contours (default: `15`).
#' @template params-annotation
#'
#' @return A [`ggplot2`][ggplot2::ggplot()] plot showing the travel time to
#'   the nearest facility.
#'
#' @family travel time functions
#' @keywords reporting
#' @export
#'
#' @examples
#' friction_file <- system.file(
#'   "extdata", "naples-friction-walk.tif",
#'   package = "locationallocation"
#' )
#'
#' traveltime_data <-
#'   naples_fountains |>
#'   traveltime(
#'     bb_area = naples_shape,
#'     res_output = 1000,
#'     file = friction_file
#'   )
#'
#' traveltime_data |>
#'   traveltime_plot(
#'     bb_area = naples_shape,
#'     facilities = naples_fountains
#'   )
traveltime_plot <- function(
  traveltime,
  bb_area,
  facilities = NULL,
  contour_traveltime = 15,
  annotation_location = "br",
  annotation_scale = TRUE,
  annotation_north_arrow = TRUE
) {
  assert_traveltime(traveltime)
  assert_bb_area(bb_area)
  assert_facilities(facilities, null_ok = TRUE)
  checkmate::assert_numeric(
    contour_traveltime,
    lower = 0,
    finite = TRUE,
    any.missing = FALSE,
    null.ok = TRUE
  )
  checkmate::assert_flag(annotation_scale)
  checkmate::assert_flag(annotation_north_arrow)

  checkmate::assert_choice(
    annotation_location,
    choices = c("bl", "br", "tl", "tr")
  )

  # R CMD Check variable bindings fix
  # nolint start
  x <- y <- value <- NULL
  # nolint end

  bb_area <- as_wgs84(bb_area)
  data <- raster_to_plot_data(traveltime$travel_time, bb_area)

  plot <-
    ggplot2::ggplot() +
    ggplot2::geom_raster(
      mapping = ggplot2::aes(x = x, y = y, fill = value),
      data = data
    ) +
    ggplot2::geom_sf(data = bb_area, fill = NA, color = "black") +
    ggplot2::scale_fill_distiller(
      palette = "Spectral",
      direction = -1,
      na.value = "grey50"
    ) +
    ggplot2::labs(
      x = NULL,
      y = NULL,
      fill = "Minutes"
    ) +
    ggplot2::theme_bw() +
    ggplot2::theme(panel.grid = ggplot2::element_blank())

  if (!is.null(contour_traveltime)) {
    max_travel_time <- max(data$value, na.rm = TRUE)
    contour_traveltime <- contour_traveltime[
      contour_traveltime < max_travel_time
    ]

    if (length(contour_traveltime) > 0) {
      plot <-
        plot +
        ggplot2::geom_contour(
          mapping = ggplot2::aes(x = x, y = y, z = value),
          data = data |> dplyr::filter(!is.na(value)),
          color = "black",
          breaks = contour_traveltime
        )
    }
  }

  if (!is.null(facilities)) {
    plot <-
      plot +
      ggplot2::geom_sf(
        data = facilities |> as_wgs84() |> points_in_area(bb_area),
        color = "black",
        size = 0.5
      )
  }

  plot |>
    add_plot_annotation(
      annotation_location = annotation_location,
      annotation_scale = annotation_scale,
      annotation_north_arrow = annotation_north_arrow
    )
}

# Data frame (x, y, value) of a raster masked to an area, for `geom_raster()`.
# Infinite values (unreachable cells) are converted to `NA`.
raster_to_plot_data <- function(x, bb_area) {
  out <-
    x |>
    mask_raster_to_polygon(bb_area) |>
    raster::as.data.frame(xy = TRUE)

  names(out) <- c("x", "y", "value")
  out <- out[!is.na(out$value), ]
  out$value[is.infinite(out$value)] <- NA

  out
}

# Points intersecting the area (planar test in geographic coordinates).
points_in_area <- function(x, bb_area) {
  x <- sf::st_as_sf(x)

  inside <- terra::is.related(
    terra::vect(x),
    terra::vect(bb_area),
    "intersects"
  )

  x[inside, ]
}
