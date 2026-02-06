#' Plot results of the `allocation()` and `allocation_discrete()` functions
#'
#' @description
#'
#' `allocation_plot()` plot the results of the [`allocation`][allocation()] and
#' `allocation_discrete()` functions, showing the potential locations for new
#' facilities and the coverage attained.
#'
#' @param allocation The output of the [`allocation`][allocation()] or
#'   `allocation_discrete()` function.
#' @template params-bb-area
#' @template params-annotation
#'
#' @return A [`ggplot2`][ggplot2::ggplot()] plot showing the potential locations
#'   for new facilities.
#'
#' @family plot functions
#' @keywords reporting
#' @export
#'
#' @examples
#'
#' ## Plotting Results of the `allocation()` Function -----
#'
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
#'   allocation_data <-
#'     naples_population |>
#'     allocation(
#'       traveltime = traveltime_data,
#'       bb_area = naples_shape,
#'       facilities = naples_fountains,
#'       weights = NULL,
#'       objectiveminutes = 15,
#'       objectiveshare = 0.99,
#'       heur = "max",
#'       dowscaling_model_type = "lm",
#'       mode = "walk",
#'       res_output = 100
#'     )
#'
#'   allocation_data |> allocation_plot(naples_shape)
#' }
#'
#' ## Plotting Results of the `allocation_discrete()` Function -----
#'
#' \dontrun{
#'   library(sf)
#'
#'   traveltime_data <-
#'     naples_fountains |>
#'     traveltime(
#'       bb_area = naples_shape,
#'       dowscaling_model_type = "lm",
#'       mode = "walk",
#'       res_output = 100
#'     )
#'
#'   allocation_data <-
#'     naples_population |>
#'     allocation_discrete(
#'       traveltime = traveltime_data,
#'       bb_area = naples_shape,
#'       facilities = naples_fountains,
#'       candidate = naples_shape |> st_sample(20),
#'       n_fac = 2,
#'       weights = NULL,
#'       objectiveminutes = 15,
#'       dowscaling_model_type = "lm",
#'       mode = "walk",
#'       res_output = 100,
#'       n_samples = 1000,
#'       par = TRUE
#'     )
#'
#'   allocation_data |> allocation_plot(naples_shape)
#' }
allocation_plot <- function(
  allocation,
  bb_area,
  annotation_location = "br",
  annotation_scale = TRUE,
  annotation_north_arrow = TRUE
) {
  assert_allocation(allocation)
  assert_bb_area(bb_area)
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

  max_limit <-
    allocation |>
    magrittr::extract2("travel_time") |>
    stars_values() |>
    max(na.rm = TRUE)

  plot <-
    ggplot2::ggplot() +
    ggplot2::geom_raster(
      mapping = ggplot2::aes(x = x, y = y, fill = layer),
      data = allocation |> #nolint
        magrittr::extract2("travel_time") |>
        mask_raster_to_polygon(bb_area) |>
        stars_to_dataframe() |>
        stats::na.omit()
    ) +
    ggplot2::geom_sf(
      data = allocation |> #nolint
        magrittr::extract2("facilities") |>
        sf::st_as_sf(),
      color = "black",
      size = 2.5
    ) +
    ggplot2::scale_fill_distiller(
      palette = "Spectral",
      direction = -1,
      limits = c(0, max_limit)
    ) +
    ggplot2::labs(
      x = NULL,
      y = NULL,
      fill = "Minutes"
    ) +
    ggplot2::theme_bw() +
    ggplot2::theme(panel.grid = ggplot2::element_blank())

  plot |>
    add_plot_annotation(
      annotation_location = annotation_location,
      annotation_scale = annotation_scale,
      annotation_north_arrow = annotation_north_arrow
    )
}
