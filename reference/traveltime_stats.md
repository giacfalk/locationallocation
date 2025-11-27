# Summarize results of the `traveltime()` function

`traveltime_stats()` generates a summary of the
[`traveltime()`](https://giacfalk.github.io/locationallocation/reference/traveltime.md)
function results, producing a statistic for the percent of demand which
is covered within a given objective travel time along with a cumulative
curve plot.

## Usage

``` r
traveltime_stats(
  traveltime,
  demand,
  breaks = c(5, 10, 15, 30),
  objectiveminutes = 15,
  print = TRUE
)
```

## Arguments

- traveltime:

  A [`list`](https://rdrr.io/r/base/list.html) with the output of the
  [`traveltime()`](https://giacfalk.github.io/locationallocation/reference/traveltime.md)
  function.

- demand:

  A [`RasterLayer`](https://rdrr.io/pkg/raster/man/raster.html) object
  with the demand layer (e.g. population density).

- breaks:

  (optional) A [`numeric`](https://rdrr.io/r/base/numeric.html) object
  indicating the breaks (in minutes) for the cumulative curve plot
  (default: `c(5, 10, 15, 30)`).

- objectiveminutes:

  (optional) A number indicating the target travel time in minutes used
  to compute the statistics (default: `15`).

- print:

  (optional) A [`logical`](https://rdrr.io/r/base/logical.html) flag
  indicating whether to print the results to the console (default:
  `TRUE`).

## Value

A [`list`](https://rdrr.io/r/base/list.html) containing:

- `percent`: A [`numeric`](https://rdrr.io/r/base/numeric.html) value
  indicating the percent of demand covered within the objective travel
  time.

- `data`: A
  [`tibble`](https://dplyr.tidyverse.org/reference/reexports.html)
  object with the data used to generate the cumulative curve plot.

- `plot`: A
  [`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html) object
  with the cumulative curve plot.

## See also

Other travel time functions:
[`friction()`](https://giacfalk.github.io/locationallocation/reference/friction.md),
[`traveltime()`](https://giacfalk.github.io/locationallocation/reference/traveltime.md),
[`traveltime_plot()`](https://giacfalk.github.io/locationallocation/reference/traveltime_plot.md)

## Examples

``` r
if (FALSE) { # \dontrun{
  traveltime_data <-
    naples_fountains |>
    traveltime(
      bb_area = naples_shape,
      dowscaling_model_type = "lm",
      mode = "walk",
      res_output = 100
    )

  traveltime_data |>
    traveltime_stats(
      demand = naples_population,
      breaks = c(5, 10, 15, 30),
      objectiveminutes = 15
    )
} # }
```
