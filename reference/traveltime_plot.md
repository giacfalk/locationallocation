# Plot results of the `traveltime()` function

`traveltime_plot()` plot the results of the
[`traveltime()`](https://giacfalk.github.io/locationallocation/reference/traveltime.md)
function, showing the travel time from the facilities to the area of
interest.

## Usage

``` r
traveltime_plot(
  traveltime,
  bb_area,
  facilities = NULL,
  contour_traveltime = 15
)
```

## Arguments

- traveltime:

  A [`list`](https://rdrr.io/r/base/list.html) with the output of the
  [`traveltime()`](https://giacfalk.github.io/locationallocation/reference/traveltime.md)
  function.

- bb_area:

  A [`sf`](https://r-spatial.github.io/sf/reference/st_as_sf.html)
  boundary box object with the area of interest.

- facilities:

  A [`sf`](https://r-spatial.github.io/sf/reference/st_as_sf.html)
  object with the existing facilities.

- contour_traveltime:

  (optional) A number indicating the contour thresholds for the travel
  time (default: `15`).

## Value

A [`ggplot2`](https://ggplot2.tidyverse.org/reference/ggplot.html) plot
showing the travel time from the facilities to the area of interest.

## See also

Other travel time functions:
[`friction()`](https://giacfalk.github.io/locationallocation/reference/friction.md),
[`traveltime()`](https://giacfalk.github.io/locationallocation/reference/traveltime.md),
[`traveltime_stats()`](https://giacfalk.github.io/locationallocation/reference/traveltime_stats.md)

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
    traveltime_plot(
      bb_area = naples_shape,
      facilities = naples_fountains
    )
} # }
```
