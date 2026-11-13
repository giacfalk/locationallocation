#' Plot results of the `allocation()` and `allocation_discrete()` functions
#'
#' @description
#'
#' `allocation_plot()` plots the results of the [`allocation()`][allocation()]
#' and [`allocation_discrete()`][allocation_discrete()] functions, showing the
#' travel time to the nearest facility after the allocation and the location
#' of the new facilities.
#'
#' @param allocation The output of the [`allocation()`][allocation()] or
#'   [`allocation_discrete()`][allocation_discrete()] function.
#' @template params-bb-area
#' @param facilities (optional) A [`sf`][sf::st_as_sf()] object with the
#'   existing facilities, plotted as hollow circles (default: `NULL`).
#' @template params-annotation
#'
#' @return A [`ggplot2`][ggplot2::ggplot()] plot showing the travel time to
#'   the nearest facility and the location of the new facilities.
#'
#' @family plot functions
#' @keywords reporting
#' @export
#'
#' @examples
#' \dontrun{
#'   library(sf)
#'
#'   traveltime_data <-
#'     naples_fountains |>
#'     traveltime(bb_area = naples_shape)
#'
#'   ## Plotting Results of the `allocation()` Function -----
#'
#'   allocation_data <-
#'     naples_population |>
#'     allocation(
#'       bb_area = naples_shape,
#'       facilities = naples_fountains,
#'       traveltime = traveltime_data,
#'       objectiveminutes = 15,
#'       objectiveshare = 0.99
#'     )
#'
#'   allocation_data |> allocation_plot(naples_shape)
#'
#'   ## Plotting Results of the `allocation_discrete()` Function -----
#'
#'   allocation_data <-
#'     naples_population |>
#'     allocation_discrete(
#'       bb_area = naples_shape,
#'       candidate = naples_shape |> st_sample(20),
#'       facilities = naples_fountains,
#'       traveltime = traveltime_data,
#'       n_fac = 2,
#'       objectiveminutes = 15
#'     )
#'
#'   allocation_data |>
#'     allocation_plot(naples_shape, facilities = naples_fountains)
#' }
allocation_plot <- function(
  allocation,
  bb_area,
  facilities = NULL,
  annotation_location = "br",
  annotation_scale = TRUE,
  annotation_north_arrow = TRUE
) {
  assert_allocation(allocation)
  assert_bb_area(bb_area)
  assert_facilities(facilities, null_ok = TRUE)
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
  data <- raster_to_plot_data(allocation$travel_time, bb_area)

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
      limits = c(0, max(data$value, na.rm = TRUE)),
      na.value = "grey50"
    ) +
    ggplot2::labs(
      x = NULL,
      y = NULL,
      fill = "Minutes"
    ) +
    ggplot2::theme_bw() +
    ggplot2::theme(panel.grid = ggplot2::element_blank())

  if (!is.null(facilities)) {
    plot <-
      plot +
      ggplot2::geom_sf(
        data = facilities |> as_wgs84() |> points_in_area(bb_area),
        color = "black",
        shape = 1,
        size = 1
      )
  }

  if (nrow(allocation$facilities) > 0) {
    plot <-
      plot +
      ggplot2::geom_sf(
        data = sf::st_as_sf(allocation$facilities),
        fill = "black",
        color = "white",
        shape = 21,
        size = 2.5
      )
  }

  plot |>
    add_plot_annotation(
      annotation_location = annotation_location,
      annotation_scale = annotation_scale,
      annotation_north_arrow = annotation_north_arrow
    )
}
