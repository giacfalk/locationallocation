# Compute the maximal coverage location-allocation for discrete problems

`allocation_discrete()` allocates facilities in a discrete location
problem. It uses the accumulated cost algorithm to identify optimal
facility locations based on the share of demand to be covered, given a
user-defined set of candidate locations and a maximum number of
allocable facilities.

If a `objectiveshare` parameter is specified, the algorithm identifies
the best set of size of up to `n_fac` facilities to achieve the targeted
coverage share. The problem is solved using a statistical heuristic
approach that generates samples of the candidate locations (on top of
the existing locations) and selects the facilities in the one that
minimizes the objective function.

See
[`allocation()`](https://giacfalk.github.io/locationallocation/reference/allocation.md)
for continuous location-allocation problems.

## Usage

``` r
allocation_discrete(
  demand,
  bb_area,
  candidate,
  facilities = NULL,
  n_fac = Inf,
  n_samples = 1000,
  traveltime = NULL,
  mode = "walk",
  dowscaling_model_type = "lm",
  res_output = 100,
  weights = NULL,
  objectiveminutes = 15,
  objectiveshare = NULL,
  approach = "norm",
  exp_demand = 1,
  exp_weights = 1,
  par = FALSE
)
```

## Arguments

- demand:

  A [`RasterLayer`](https://rdrr.io/pkg/raster/man/raster.html) object
  with the demand layer (e.g. population density).

- bb_area:

  A [`sf`](https://r-spatial.github.io/sf/reference/st_as_sf.html)
  boundary box object with the area of interest.

- candidate:

  A [`sf`](https://r-spatial.github.io/sf/reference/st_as_sf.html)
  object with the candidate locations for the new facilities.

- facilities:

  A [`sf`](https://r-spatial.github.io/sf/reference/st_as_sf.html)
  object with the existing facilities.

- n_fac:

  (optional) A positive
  [integerish](https://mllg.github.io/checkmate/reference/checkIntegerish.html)
  number indicating the maximum number of facilities that can be
  allocated (default: `Inf`).

- n_samples:

  (optional) A positive
  [integerish](https://mllg.github.io/checkmate/reference/checkIntegerish.html)
  number indicating the number of samples to generate in the heuristic
  approach for identifying the best set of facilities to be allocated
  (default: `1000`).

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
  covered by adding at most the number of facilities defined by the
  `n_fac` parameter from the pool of candidate facilities (default:
  `NULL`).

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

- par:

  (optional) A [`logical`](https://rdrr.io/r/base/logical.html) flag
  indicating whether to run the function in
  [parallel](https://rdrr.io/r/parallel/clusterApply.html) or not
  (default: `FALSE`).

## Value

An [invisible](https://rdrr.io/r/base/invisible.html)
[`list`](https://rdrr.io/r/base/list.html) with the following elements:

- `coverage`: A [`numeric`](https://rdrr.io/r/base/numeric.html) value
  indicating the share of demand covered within the objective travel
  time after allocating the new facilities.

- `unmet_demand`: A [`numeric`](https://rdrr.io/r/base/numeric.html)
  value indicating the share of demand that remains unmet after
  allocating the new facilities.

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
[`allocation()`](https://giacfalk.github.io/locationallocation/reference/allocation.md)

## Examples

``` r
if (FALSE) { # \dontrun{
  library(dplyr)
  library(sf)

  allocation_data <-
    naples_population |>
    allocation_discrete(
      traveltime = traveltime,
      bb_area = naples_shape,
      facilities = naples_fountains,
      candidate = naples_shape |> st_sample(20),
      n_fac = 2,
      weights = naples_hot_days,
      objectiveminutes = 15,
      objectiveshare = 0.9
    )

  allocation_data |> glimpse()

  allocation_data |> allocation_plot(naples_shape)
} # }
```
