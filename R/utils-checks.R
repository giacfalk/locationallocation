assert_bb_area <- function(x, null_ok = FALSE) {
  checkmate::assert_flag(null_ok)

  if (is.null(x) && isTRUE(null_ok)) {
    TRUE
  } else {
    name <- deparse(substitute(x)) #nolint

    if (!inherits(x, "sf") || nrow(x) == 0) {
      cli::cli_abort(
        paste0(
          "{.strong {cli::col_red(name)}} ",
          "must be a non-empty {.strong sf} polygon."
        )
      )
    } else {
      TRUE
    }
  }
}

assert_facilities <- function(x, null_ok = FALSE) {
  checkmate::assert_flag(null_ok)

  if (is.null(x) && isTRUE(null_ok)) {
    TRUE
  } else {
    name <- deparse(substitute(x)) #nolint

    if (!inherits(x, "sf") || nrow(x) == 0) {
      cli::cli_abort(
        paste0(
          "{.strong {cli::col_red(name)}} ",
          "must be a non-empty {.strong sf} point geometry data frame."
        )
      )
    } else {
      TRUE
    }
  }
}

assert_traveltime <- function(x, null_ok = FALSE) {
  checkmate::assert_flag(null_ok)

  if (is.null(x) && isTRUE(null_ok)) {
    TRUE
  } else {
    name <- deparse(substitute(x)) #nolint

    if (!inherits(x, "traveltime")) {
      cli::cli_abort(
        paste0(
          "{.strong {cli::col_red(name)}} ",
          "must be an output object from the ",
          "{.strong {cli::col_blue('traveltime()')}} ",
          "function."
        )
      )
    } else {
      TRUE
    }
  }
}

assert_allocation <- function(
  x,
  null_ok = FALSE,
  continuous = TRUE,
  discrete = TRUE
) {
  checkmate::assert_flag(null_ok)
  checkmate::assert_flag(continuous)
  checkmate::assert_flag(discrete)

  if (is.null(x) && isTRUE(null_ok)) {
    TRUE
  } else {
    name <- deparse(substitute(x)) #nolint

    if (isTRUE(continuous) && isTRUE(discrete)) {
      class_check <- c("allocation", "allocation_discrete")

      error_message <- paste0(
        "{.strong {cli::col_red(name)}} ",
        "must be an output object from either the ",
        "{.strong allocation()} or ",
        "{.strong allocation_discrete()} function."
      )
    } else if (isTRUE(continuous) && isFALSE(discrete)) {
      class_check <- "allocation"

      error_message <- paste0(
        "{.strong {cli::col_red(name)}} ",
        "must be an output object from the ",
        "{.strong allocation()} function."
      )
    } else if (isFALSE(continuous) && isTRUE(discrete)) {
      class_check <- "allocation_discrete"

      error_message <- paste0(
        "{.strong {cli::col_red(name)}} ",
        "must be an output object from the ",
        "{.strong allocation_discrete()} function."
      )
    } else {
      cli::cli_abort(
        paste0(
          "At least one of {.strong continuous} or ",
          "{.strong discrete} must be set to {.strong TRUE}."
        )
      )
    }

    if (!inherits(x, class_check)) {
      cli::cli_abort(error_message)
    } else {
      TRUE
    }
  }
}

assert_minimal_coverage <- function(
  traveltime,
  demand,
  objectiveminutes,
  objectiveshare,
  null_ok = FALSE
) {
  assert_traveltime(traveltime)
  checkmate::assert_class(demand, "stars")
  checkmate::assert_number(objectiveminutes, lower = 0)
  checkmate::assert_number(objectiveshare, lower = 0, upper = 1, null.ok = TRUE)
  checkmate::assert_flag(null_ok)

  if (is.null(objectiveshare) && isTRUE(null_ok)) {
    TRUE
  } else {
    coverage <-
      traveltime |>
      traveltime_stats(
        demand = demand,
        objectiveminutes = objectiveminutes,
        print = FALSE
      ) |>
      magrittr::extract2("coverage")


    if (coverage >= objectiveshare) {
      cli::cli_abort(
        paste0(
          "The initial coverage within ",
          "{.strong {cli::col_yellow(objectiveminutes)}} minutes is ",
          "{.strong ",
          "{cli::col_red(round(coverage * 100, 5))}}%, ",
          "which meets the ",
          "{.strong {cli::col_blue(objectiveshare * 100)}}% objective share. ",
          "No additional facilities are required. ",
          "Use {.strong traveltime_stats()} ",
          "to review travel time statistics."
        ),
        wrap = TRUE
      )
    } else {
      TRUE
    }
  }
}

assert_internet <- function() {
  if (!curl::has_internet()) {
    cli::cli_abort(
      paste0(
        "An {.strong {cli::col_red('internet connection')}} ",
        "is required to run this function."
      )
    )
  } else {
    TRUE
  }
}
