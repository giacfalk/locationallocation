coverage_message <- function(allocation) {
  assert_allocation(allocation)

  n_fac <- nrow(allocation$facilities) #nolint
  coverage <- allocation$coverage
  objective_minutes <- allocation$objective_minutes #nolint
  objective_share <- allocation$objective_share

  if (is.null(objective_share)) {
    cli::cli_alert_info(
      paste0(
        "{.strong {cli::col_red(n_fac)}} facilit{?y/ies} ",
        "allocated within the ",
        "{.strong {cli::col_yellow(objective_minutes)}} ",
        "minutes threshold. ",
        "The coverage share attained is ",
        "{.strong {cli::col_green(round(coverage * 100, 5))}}%."
      ),
      wrap = TRUE
    )
  } else if (coverage >= objective_share) {
    cli::cli_alert_success(
      paste0(
        "Target coverage share of ",
        "{.strong {cli::col_blue((objective_share * 100))}}% ",
        "attained with ",
        "{.strong {cli::col_red(n_fac)}} new facilit{?y/ies} ",
        "within the ",
        "{.strong {cli::col_yellow(objective_minutes)}} ",
        "minutes threshold. ",
        "The achieved coverage share is ",
        "{.strong {cli::col_green(round(coverage * 100, 5))}}%."
      ),
      wrap = TRUE
    )
  } else {
    cli::cli_alert_danger(
      paste0(
        "The target coverage share of ",
        "{.strong {cli::col_blue((objective_share * 100))}}% ",
        "could not be attained with ",
        "{.strong {cli::col_red(n_fac)}} new ",
        "facilit{?y/ies} within the ",
        "{.strong {cli::col_yellow(objective_minutes)}} ",
        "minutes threshold. ",
        "The maximum coverage share attained was ",
        "{.strong {cli::col_green(round(coverage * 100, 5))}}%."
      ),
      wrap = TRUE
    )
  }

  invisible(coverage)
}

#' @export
print.allocation <- function(x, ...) {
  type <- if (inherits(x, "allocation_discrete")) "discrete" else "continuous"

  cli::cli_text(
    "{.strong Maximal coverage location-allocation} ({type} problem)"
  )

  coverage_message(x)
  cli::cat_line()
  print(x$facilities, ...)

  invisible(x)
}

#' @export
print.allocation_discrete <- function(x, ...) {
  print.allocation(x, ...)
}

#' @export
print.traveltime <- function(x, ...) {
  values <- raster::values(x$travel_time)
  finite <- values[is.finite(values)]

  cli::cli_text("{.strong Travel time map}")
  cli::cli_ul()
  cli::cli_li(
    paste0(
      "Travel time (minutes): ",
      "median {round(stats::median(finite), 2)}, ",
      "max {round(max(finite), 2)}"
    )
  )
  cli::cli_li(
    paste0(
      "Unreachable cells: {sum(is.infinite(values))} ",
      "of {sum(!is.na(values))}"
    )
  )
  cli::cli_li(
    paste0(
      "Resolution: ",
      "{signif(raster::res(x$travel_time), 3)} degrees ",
      "({paste(dim(x$travel_time)[1:2], collapse = ' x ')} cells)"
    )
  )
  cli::cli_end()

  invisible(x)
}
