#' Summarize results of the `traveltime()` function
#'
#' @description
#'
#' `traveltime_stats()` generates a summary of the
#' [`traveltime()`][traveltime] function results, producing a statistic for
#' the share of demand which is covered within a given objective travel time
#' along with a cumulative coverage curve.
#'
#' @details
#'
#' The travel time map is aligned to the grid of `demand` (nearest-neighbour
#' resampling). Coverage is computed over the demand cells that fall within
#' the travel time map (i.e., within `bb_area`). Demand in cells that cannot
#' be reached (infinite travel time) counts as not covered.
#'
#' @template params-traveltime-a
#' @template params-demand
#' @template params-objectiveminutes
#' @param breaks (optional) A [`numeric`][base::numeric] vector indicating the
#'   breaks (in minutes) for the cumulative curve plot
#'   (default: `c(5, 10, 15, 30)`).
#' @param print (optional) A [`logical`][base::logical] flag indicating
#'   whether to print the results to the console (default: `TRUE`).
#'
#' @return An [invisible][base::invisible] [`list`][base::list] with the
#'   following elements:
#'   - `coverage`: A [`numeric`][base::numeric()] value indicating the share of
#'   demand covered within the objective travel time.
#'   - `unmet_demand`: A [`numeric`][base::numeric()] value indicating the share
#'   of demand that remains unmet.
#'   - `data`: A [`tibble`][dplyr::tibble] object with the travel time and
#'   demand of each cell, sorted by travel time, and the cumulative share of
#'   demand covered (in %).
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
  demand <- as_raster_layer(demand)
  checkmate::assert_number(objectiveminutes, lower = 0, finite = TRUE)
  checkmate::assert_numeric(
    breaks,
    lower = 0,
    finite = TRUE,
    any.missing = FALSE,
    min.len = 1,
    unique = TRUE,
    sorted = TRUE
  )
  checkmate::assert_flag(print)

  # R CMD Check variable bindings fix
  # nolint start
  traveltime_values <- demand_values <- cumulative_coverage <- th <- NULL
  # nolint end

  travel_time <- grid_values(traveltime$travel_time, demand)
  demand_values <- raster::values(demand)
  keep <- !is.na(travel_time) & !is.na(demand_values)

  data_curve <-
    dplyr::tibble(
      traveltime_values = travel_time[keep],
      demand_values = demand_values[keep]
    ) |>
    dplyr::arrange(traveltime_values) |>
    dplyr::mutate(
      cumulative_coverage = demand_values |> #nolint
        cumsum() |>
        magrittr::divide_by(sum(demand_values)) |>
        magrittr::multiply_by(100),
      th = traveltime_values |> #nolint
        cut(
          breaks = c(-Inf, breaks, Inf),
          labels = c(
            paste0("\u2264", breaks),
            paste0(">", dplyr::last(breaks))
          )
        )
    )

  coverage <- coverage_share(
    demand = data_curve$demand_values,
    travel_time = data_curve$traveltime_values,
    objectiveminutes = objectiveminutes
  )

  plot <-
    data_curve |>
    dplyr::filter(is.finite(traveltime_values)) |>
    ggplot2::ggplot() +
    ggplot2::geom_step(
      ggplot2::aes(
        x = traveltime_values,
        y = cumulative_coverage,
        color = th
      )
    ) +
    ggplot2::scale_color_brewer(
      palette = "Reds",
      direction = 1,
      drop = FALSE
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

# Share of `demand` with a travel time within `objectiveminutes`. `NA` cells
# (outside the study area) are ignored.
coverage_share <- function(demand, travel_time, objectiveminutes) {
  valid <- !is.na(demand) & !is.na(travel_time)
  total <- sum(demand[valid])

  if (total <= 0) {
    cli::cli_abort(
      "The total demand within the study area must be greater than zero."
    )
  }

  sum(demand[valid & travel_time <= objectiveminutes]) / total
}
