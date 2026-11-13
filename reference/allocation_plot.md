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
#> ✔ Using user-provided friction data file [507ms]
#> 
#> ℹ Computing transition matrix and geocorrection
#> ✔ Computing transition matrix and geocorrection [84ms]
#> 
#> ℹ Computing travel time map
#> ✔ Computing travel time map [499ms]
#> 

# A coarser demand grid (~360 m) keeps the example fast
demand <- raster::aggregate(naples_population, fact = 4, fun = sum)

allocation_data <-
  demand |>
  allocation(
    bb_area = naples_shape,
    facilities = naples_fountains,
    traveltime = traveltime_data,
    objectiveminutes = 15,
    objectiveshare = NULL,
    n_fac = 3,
    refine = FALSE # Faster, greedy-only solution
  )
#> ℹ Facility 1: share of unmet demand: 4.59625%.
#> ℹ Facility 2: share of unmet demand: 3.13073%.
#> ℹ Facility 3: share of unmet demand: 2.2453%.
#> 
#> ℹ 3 facilities allocated within the 15 minutes threshold. The coverage share
#> attained is 97.7547%.

allocation_data |>
  allocation_plot(naples_shape, facilities = naples_fountains)
```
