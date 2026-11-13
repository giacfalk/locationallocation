# Plot results of the `allocation()` and `allocation_discrete()` functions

`allocation_plot()` plots the results of the
[`allocation()`](https://giacfalk.github.io/locationallocation/reference/allocation.md)
and
[`allocation_discrete()`](https://giacfalk.github.io/locationallocation/reference/allocation.md)
functions, showing the travel time to the nearest facility after the
allocation and the location of the new facilities.

## Usage

``` r
allocation_plot(
  allocation,
  bb_area,
  facilities = NULL,
  annotation_location = "br",
  annotation_scale = TRUE,
  annotation_north_arrow = TRUE
)
```

## Arguments

- allocation:

  The output of the
  [`allocation()`](https://giacfalk.github.io/locationallocation/reference/allocation.md)
  or
  [`allocation_discrete()`](https://giacfalk.github.io/locationallocation/reference/allocation.md)
  function.

- bb_area:

  A [`sf`](https://r-spatial.github.io/sf/reference/st_as_sf.html)
  object with the polygon(s) of the area of interest.

- facilities:

  (optional) A
  [`sf`](https://r-spatial.github.io/sf/reference/st_as_sf.html) object
  with the existing facilities, plotted as hollow circles (default:
  `NULL`).

- annotation_location:

  (optional) A [`character`](https://rdrr.io/r/base/character.html)
  string specifying the location of the annotation on the plot. See
  [`annotation_scale`](https://paleolimbot.github.io/ggspatial/reference/annotation_scale.html)
  for possible values (default: `"br"`).

- annotation_scale:

  (optional) A [`logical`](https://rdrr.io/r/base/logical.html) flag
  indicating whether to include a scale annotation on the plot (default:
  `TRUE`).

- annotation_north_arrow:

  (optional) A [`logical`](https://rdrr.io/r/base/logical.html) flag
  indicating whether to include a north arrow annotation on the plot
  (default: `TRUE`).

## Value

A [`ggplot2`](https://ggplot2.tidyverse.org/reference/ggplot.html) plot
showing the travel time to the nearest facility and the location of the
new facilities.

## Examples

``` r
if (FALSE) { # \dontrun{
  library(sf)

  traveltime_data <-
    naples_fountains |>
    traveltime(bb_area = naples_shape)

  ## Plotting Results of the `allocation()` Function -----

  allocation_data <-
    naples_population |>
    allocation(
      bb_area = naples_shape,
      facilities = naples_fountains,
      traveltime = traveltime_data,
      objectiveminutes = 15,
      objectiveshare = 0.99
    )

  allocation_data |> allocation_plot(naples_shape)

  ## Plotting Results of the `allocation_discrete()` Function -----

  allocation_data <-
    naples_population |>
    allocation_discrete(
      bb_area = naples_shape,
      candidate = naples_shape |> st_sample(20),
      facilities = naples_fountains,
      traveltime = traveltime_data,
      n_fac = 2,
      objectiveminutes = 15
    )

  allocation_data |>
    allocation_plot(naples_shape, facilities = naples_fountains)
} # }
```
