# Plot results of the `allocation()` and `allocation_discrete()` functions

`allocation_plot()` plot the results of the
[`allocation`](https://giacfalk.github.io/locationallocation/reference/allocation.md)
and
[`allocation_discrete()`](https://giacfalk.github.io/locationallocation/reference/allocation_discrete.md)
functions, showing the potential locations for new facilities and the
coverage attained.

## Usage

``` r
allocation_plot(allocation, bb_area)
```

## Arguments

- allocation:

  The output of the
  [`allocation`](https://giacfalk.github.io/locationallocation/reference/allocation.md)
  or
  [`allocation_discrete()`](https://giacfalk.github.io/locationallocation/reference/allocation_discrete.md)
  function.

- bb_area:

  A [`sf`](https://r-spatial.github.io/sf/reference/st_as_sf.html)
  boundary box object with the area of interest.

## Value

A [`ggplot2`](https://ggplot2.tidyverse.org/reference/ggplot.html) plot
showing the potential locations for new facilities.

## Examples

``` r
## Plotting Results of the `allocation()` Function -----

if (FALSE) { # \dontrun{
  traveltime_data <- traveltime(
    facilities = naples_fountains,
    bb_area = naples_shape,
    dowscaling_model_type = "lm",
    mode = "walk",
    res_output = 100
  )

  allocation_data <-
    naples_population |>
    allocation(
      traveltime = traveltime_data,
      bb_area = naples_shape,
      facilities = naples_fountains,
      weights = NULL,
      objectiveminutes = 15,
      objectiveshare = 0.99,
      heur = "max",
      dowscaling_model_type = "lm",
      mode = "walk",
      res_output = 100
    )

  allocation_data |> allocation_plot(naples_shape)
} # }

## Plotting Results of the `allocation_discrete()` Function -----

if (FALSE) { # \dontrun{
  library(sf)

  traveltime_data <- traveltime(
    facilities = naples_fountains,
    bb_area = naples_shape,
    dowscaling_model_type = "lm",
    mode = "walk",
    res_output = 100
  )

  allocation_data <-
    naples_population |>
    allocation_discrete(
      traveltime = traveltime_data,
      bb_area = naples_shape,
      facilities = naples_fountains,
      candidate = naples_shape |> st_sample(20),
      n_fac = 2,
      weights = NULL,
      objectiveminutes = 15,
      dowscaling_model_type = "lm",
      mode = "walk",
      res_output = 100,
      n_samples = 1000,
      par = TRUE
    )

  allocation_data |> allocation_plot(naples_shape)
} # }
```
