# Summarize results of the `traveltime()` function

`traveltime_stats()` generates a summary of the
[`traveltime()`](https://giacfalk.github.io/locationallocation/reference/traveltime.md)
function results, producing a statistic for the share of demand which is
covered within a given objective travel time along with a cumulative
coverage curve.

## Usage

``` r
traveltime_stats(
  traveltime,
  demand,
  objectiveminutes = 15,
  breaks = c(5, 10, 15, 30),
  print = TRUE
)
```

## Arguments

- traveltime:

  A [`list`](https://rdrr.io/r/base/list.html) with the output of the
  [`traveltime()`](https://giacfalk.github.io/locationallocation/reference/traveltime.md)
  function.

- demand:

  A [`RasterLayer`](https://rdrr.io/pkg/raster/man/raster.html) or
  single-layer
  [`SpatRaster`](https://rspatial.github.io/terra/reference/rast.html)
  object with the demand (e.g., number of people per cell), in
  geographic coordinates (WGS 84). It defines the grid of the analysis.

- objectiveminutes:

  (optional) A number indicating the travel time threshold, in minutes,
  within which demand is considered covered (default: `15`).

- breaks:

  (optional) A [`numeric`](https://rdrr.io/r/base/numeric.html) vector
  indicating the breaks (in minutes) for the cumulative curve plot
  (default: `c(5, 10, 15, 30)`).

- print:

  (optional) A [`logical`](https://rdrr.io/r/base/logical.html) flag
  indicating whether to print the results to the console (default:
  `TRUE`).

## Value

An [invisible](https://rdrr.io/r/base/invisible.html)
[`list`](https://rdrr.io/r/base/list.html) with the following elements:

- `coverage`: A [`numeric`](https://rdrr.io/r/base/numeric.html) value
  indicating the share of demand covered within the objective travel
  time.

- `unmet_demand`: A [`numeric`](https://rdrr.io/r/base/numeric.html)
  value indicating the share of demand that remains unmet.

- `data`: A
  [`tibble`](https://dplyr.tidyverse.org/reference/reexports.html)
  object with the travel time and demand of each cell, sorted by travel
  time, and the cumulative share of demand covered (in %).

- `plot`: A
  [`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html) object
  with the cumulative curve plot.

## Details

The travel time map is aligned to the grid of `demand` (nearest-neighbor
resampling). Coverage is computed over the demand cells that fall within
the travel time map (i.e., within `bb_area`). Demand in cells that
cannot be reached (infinite travel time) counts as not covered.

## See also

Other travel time functions:
[`default_road_speeds()`](https://giacfalk.github.io/locationallocation/reference/default_road_speeds.md),
[`friction()`](https://giacfalk.github.io/locationallocation/reference/friction.md),
[`traveltime()`](https://giacfalk.github.io/locationallocation/reference/traveltime.md),
[`traveltime_plot()`](https://giacfalk.github.io/locationallocation/reference/traveltime_plot.md)

## Examples

``` r
friction_file <- system.file(
  "extdata", "naples-friction-walk.tif",
  package = "locationallocation"
)

traveltime_data <-
  naples_fountains |>
  traveltime(
    bb_area = naples_shape,
    res_output = 1000,
    file = friction_file
  )
#> ℹ Using user-provided friction data file
#> ✔ Using user-provided friction data file [550ms]
#> 
#> ℹ Computing transition matrix and geocorrection
#> ✔ Computing transition matrix and geocorrection [36ms]
#> 
#> ℹ Computing travel time map
#> ✔ Computing travel time map [13ms]
#> 

traveltime_data |>
  traveltime_stats(
    demand = naples_population,
    objectiveminutes = 15,
    breaks = c(5, 10, 15, 30),
    print = FALSE
  ) |>
  magrittr::extract2("coverage")
#> [1] 0.9283284
```
