# Compute the maximal coverage location-allocation for continuous problems

`allocation()` allocate facilities in a continuous location problem. It
uses the accumulated cost algorithm to find the optimal location for the
facilities based on the share of the demand to be covered.

See
[`allocation_discrete()`](https://giacfalk.github.io/locationallocation/reference/allocation_discrete.md)
for discrete location-allocation problems.

## Usage

``` r
allocation(
  demand,
  bb_area,
  facilities,
  traveltime = NULL,
  mode = "walk",
  dowscaling_model_type = "lm",
  res_output = 100,
  weights = NULL,
  objectiveminutes = 15,
  objectiveshare = 0.99,
  heur = "max",
  approach = "norm",
  exp_demand = 1,
  exp_weights = 1
)
```

## Arguments

- demand:

  A [`RasterLayer`](https://rdrr.io/pkg/raster/man/raster.html) object
  with the demand layer (e.g. population density).

- bb_area:

  A [`sf`](https://r-spatial.github.io/sf/reference/st_as_sf.html)
  boundary box object with the area of interest.

- facilities:

  A [`sf`](https://r-spatial.github.io/sf/reference/st_as_sf.html)
  object with the existing facilities.

- traveltime:

  A [`list`](https://rdrr.io/r/base/list.html) with the output of the
  [`traveltime()`](https://giacfalk.github.io/locationallocation/reference/traveltime.md)
  function. If not provided, the function will run the
  [`traveltime()`](https://giacfalk.github.io/locationallocation/reference/traveltime.md)
  function based on the provided parameters.

- mode:

  (optional) A [`character`](https://rdrr.io/r/base/character.html)
  string indicating the mode of transport. Options are `"fastest"` and
  `"walk"` (default = `"walk"`).

  - For `"fastest"`: The friction layer accounts for multiple modes of
    transport, including walking, cycling, driving, and public
    transport, and are based on the Malaria Atlas Project (2019) *Global
    Travel Speed Friction Surface*.

  - For `"walk"`: The friction layer accounts only for walking speeds
    and is based on the Malaria Atlas Project (2015) *Global Walking
    Only Friction Surface*.

- dowscaling_model_type:

  (optional) A [`character`](https://rdrr.io/r/base/character.html)
  string indicating the type of model used for the spatial downscaling
  of the friction layer. Options are `"lm"` (linear model) and `"rf"`
  (random forest) (default: `"lm"`).

- res_output:

  (optional) A positive
  [integerish](https://mllg.github.io/checkmate/reference/checkIntegerish.html)
  number indicating the spatial resolution of the friction raster (and
  of the analysis), in meters. If the resolution is less than `1000`, a
  spatial downscaling approach is used (default: `100`).

- weights:

  (optional) A raster with the weights for the demand (default: `NULL`).

- objectiveminutes:

  (optional) A number indicating the target travel time in minutes used
  to compute the statistics (default: `15`).

- objectiveshare:

  (optional) A number indicating the proportion of the demand to be
  covered (default: `0.99`).

- heur:

  (optional) The heuristic approach to be used. Options are `"max"` and
  `"kd"` (default: `"max"`).

- approach:

  (optional) The approach to be used for the allocation. Options are
  `"norm"` and `"absweights"`. If "norm", the allocation is based on the
  normalized demand raster multiplied by the normalized weights raster.
  If `"absweights"`, the allocation is based on the normalized demand
  raster multiplied by the raw weights raster (default: `"norm"`).

- exp_demand:

  (optional) The exponent for the demand raster. Default is

  1.  A higher value will give less relative weight to areas with higher
      demand - with respect to the weights layer. This is useful in
      cases where the users want to increase the allocation in areas
      with higher values in the weights layer (default: `1`).

- exp_weights:

  (optional) The exponent for the weights raster. Default is

  1.  A higher value will give less relative weight to areas with higher
      weights - with respect to the demand layer. This is useful in
      cases where the users want to increase the allocation in areas
      with higher values in the demand layer (default: `1`).

## Value

A [`list`](https://rdrr.io/r/base/list.html) with the following
elements:

- `objective_minutes`: The value of the `objectiveminutes` parameter
  used.

- `objective_share`: The value of the `objectiveshare` parameter used.

- `facilities`: A
  [`sf`](https://r-spatial.github.io/sf/reference/sf.html) object with
  the newly allocated facilities.

- `travel_time`: A
  [`raster`](https://rdrr.io/pkg/raster/man/raster.html) RasterLayer
  object representing the travel time map with the newly allocated
  facilities.

## See also

Other location-allocation functions:
[`allocation_discrete()`](https://giacfalk.github.io/locationallocation/reference/allocation_discrete.md)

## Examples

``` r
if (FALSE) { # \dontrun{
  library(dplyr)

  allocation_data <-
    naples_population |>
    allocation(
      bb_area = naples_shape,
      facilities = naples_fountains,
      weights = naples_hot_days,
      objectiveminutes = 15,
      objectiveshare = 0.99
    )

  allocation_data |> glimpse()

  allocation_data |> allocation_plot(naples_shape)
} # }
```
