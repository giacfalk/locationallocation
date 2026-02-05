#' Plot results of the `traveltime()` function
#'
#' @description
#'
#' `traveltime_plot()` plot the results of the [`traveltime()`][traveltime()]
#' function, showing the travel time from the facilities to the area of
#' interest.
#'
#' @template params-traveltime-a
#' @template params-bb-area
#' @template params-facilities
#' @param contour_traveltime (optional) A number indicating the contour
#'   thresholds for the travel time (default: `15`).
#' @template params-annotation
#'
#' @return A [`ggplot2`][ggplot2::ggplot()] plot showing the travel time from
#'   the  facilities to the area of interest.
#'
#' @family travel time functions
#' @keywords reporting
#' @export
#'
#' @examples
#' \dontrun{
#'   traveltime_data <-
#'     naples_fountains |>
#'     traveltime(
#'       bb_area = naples_shape,
#'       dowscaling_model_type = "lm",
#'       mode = "walk",
#'       res_output = 100
#'     )
#'
#'   traveltime_data |>
#'     traveltime_plot(
#'       bb_area = naples_shape,
#'       facilities = naples_fountains
#'     )
#' }
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
  assert_facilities(facilities)
  checkmate::assert_numeric(contour_traveltime, lower = 1, null.ok = TRUE)
  checkmate::assert_flag(annotation_scale)
  checkmate::assert_flag(annotation_north_arrow)

  checkmate::assert_choice(
    annotation_location,
    choices = c("bl", "br", "tl", "tr")
  )

  # R CMD Check variable bindings fix
  # nolint start
  x <- y <- layer <- NULL
  # nolint end

  data <-
    traveltime |>
    magrittr::extract2("travel_time") |>
    mask_raster_to_polygon(bb_area) |>
    as.data.frame(xy = TRUE) |>
    stats::na.omit()

  plot <-
    ggplot2::ggplot() +
    ggplot2::geom_raster(
      mapping = ggplot2::aes(x = x, y = y, fill = layer),
      data = data
    ) +
    ggplot2::scale_fill_distiller(
      palette = "Spectral",
      direction = -1
    ) +
    ggplot2::geom_sf(
      data = facilities |> sf::st_filter(bb_area),
      color = ifelse(
        is.null(facilities),
        "transparent",
        "black"
      ),
      size = 0.5
    ) +
    ggplot2::labs(
      x = NULL,
      y = NULL,
      fill = "Minutes"
    ) +
    ggplot2::theme_bw() +
    ggplot2::theme(panel.grid = ggplot2::element_blank())

  if (!is.null(contour_traveltime)) {
    max_travel_time <-
      traveltime |>
      magrittr::extract2("travel_time") |>
      stars::st_values() |>
      max(na.rm = TRUE)

    if (max_travel_time > contour_traveltime) {
      plot <-
        plot +
        ggplot2::geom_contour(
          mapping = ggplot2::aes(x = x, y = y, z = layer),
          data = data,
          color = "black",
          breaks = contour_traveltime
        )
    }
  }

  plot |>
    add_plot_annotation(
      annotation_location = annotation_location,
      annotation_scale = annotation_scale,
      annotation_north_arrow = annotation_north_arrow
    )
}
