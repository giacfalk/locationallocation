#' Summarize results of the `traveltime()` function
#'
#' @description
#'
#' `traveltime_stats()` generates a summary of the
#' [`traveltime()`][traveltime] function results, producing a statistic for
#' the percent of demand which is covered within a given objective travel time
#' along with a cumulative curve plot.
#'
#' @template params-traveltime-a
#' @template params-demand
#' @template params-objectiveminutes
#' @param breaks (optional) A [`numeric`][base::numeric] object indicating the
#'   breaks (in minutes) for the cumulative curve plot
#'   (default: `c(5, 10, 15, 30)`).
#' @param print (optional) A [`logical`][base::logical] flag indicating
#' whether to print the results to the console (default: `TRUE`).
#'
#' @return An [invisible][base::invisible] [`list`][base::list] with the
#'   following elements:
#'   - `coverage`: A [`numeric`][base::numeric()] value indicating the share of
#'   demand covered within the objective travel time.
#'   - `unmet_demand`: A [`numeric`][base::numeric()] value indicating the share
#'   of demand that remains unmet.
#'   - `data`: A [`tibble`][dplyr::tibble] object with the data used to
#'   generate the cumulative curve plot.
#'   - `plot`: A [`ggplot`][ggplot2::ggplot] object with the cumulative curve
#'   plot.
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
#'     traveltime_stats(
#'       demand = naples_population,
#'       objectiveminutes = 15,
#'       breaks = c(5, 10, 15, 30)
#'     )
#' }
traveltime_stats <- function(
  traveltime,
  demand,
  objectiveminutes = 15,
  breaks = c(5, 10, 15, 30),
  print = TRUE
) {
  assert_traveltime(traveltime)
  demand <- as_stars_if_needed(demand)
  assert_stars(demand)
  checkmate::assert_numeric(breaks, min.len = 1)
  checkmate::assert_number(objectiveminutes, lower = 1)
  checkmate::assert_flag(print)

  # R CMD Check variable bindings fix
  # nolint start
  traveltime_values <- demand_values <- P15_cumsum <- th <- NULL
  # nolint end

  sf::st_crs(demand) <- 4326

  traveltime_warped <-
    traveltime[[1]] |>
    sf::st_set_crs(4326) |>
    stars::st_warp(dest = demand, method = "near")

  data_curve <-
    data.frame(
      traveltime_values = as.vector(stars::st_values(traveltime_warped)),
      demand_values = as.vector(stars::st_values(demand))
    ) |>
    stats::na.omit() |>
    dplyr::arrange(traveltime_values) |>
    dplyr::as_tibble() |>
    dplyr::mutate(
      P15_cumsum = demand_values |> #nolint
        cumsum() |>
        magrittr::divide_by(sum(demand_values, na.rm = TRUE)) |>
        magrittr::multiply_by(100),
      th = traveltime_values |> #nolint
        cut(
          breaks = c(-Inf, breaks, Inf),
          labels = c(
            paste0("<", breaks),
            paste0(">", dplyr::last(breaks))
          )
        )
    )

  coverage <-
    data_curve |>
    dplyr::filter(traveltime_values <= objectiveminutes) |>
    dplyr::pull(demand_values) |>
    sum(na.rm = TRUE) |>
    magrittr::divide_by(
      data_curve |>
        dplyr::pull(demand_values) |>
        sum(na.rm = TRUE)
    )

  plot <-
    data_curve |>
    ggplot2::ggplot() +
    ggplot2::geom_step(
      ggplot2::aes(
        x = traveltime_values,
        y = P15_cumsum,
        color = th
      )
    ) +
    ggplot2::scale_color_brewer(
      palette = "Reds",
      direction = 1
    ) +
    ggplot2::labs(
      x = "Travel Time (Minutes)",
      y = "Cumulative Coverage (%)",
      color = "Minutes"
    ) +
    ggplot2::scale_y_continuous(
      limits = c(0, 100)
    ) +
    ggplot2::theme_bw() +
    ggplot2::theme(panel.grid = ggplot2::element_blank())

  if (isTRUE(print)) {
    cli::cli_alert_info(
      paste0(
        "{.strong {cli::col_blue(round(coverage * 100, 5))}}% ",
        "of coverage within the ",
        "{.strong {cli::col_yellow(objectiveminutes)}} ",
        "minutes threshold."
      )
    )

    print(plot)
  }

  list(
    coverage = coverage,
    unmet_demand = 1 - coverage,
    data = data_curve,
    plot = plot
  ) |>
    invisible()
}
