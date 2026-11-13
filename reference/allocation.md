# Maximal coverage location-allocation

`allocation()` and `allocation_discrete()` allocate new facilities so as
to maximize the share of (optionally weighted) demand that can reach a
facility within `objectiveminutes` minutes.

- `allocation()` solves a **continuous** problem: new facilities can be
  placed anywhere within `bb_area` (any cell of the `demand` grid).

- `allocation_discrete()` solves a **discrete** problem: new facilities
  are selected from a user-defined set of `candidate` locations.

Both functions can either add facilities until a target coverage
(`objectiveshare`) is reached, using as few facilities as possible, or
allocate a fixed maximum number of facilities (`n_fac`).

## Usage

``` r
allocation(
  demand,
  bb_area,
  facilities,
  traveltime = NULL,
  mode = "walk",
  dowscaling_model_type = NULL,
  res_output = 100,
  weights = NULL,
  objectiveminutes = 15,
  objectiveshare = 0.99,
  heur = "kd",
  approach = "norm",
  exp_demand = 1,
  exp_weights = 1,
  n_fac = Inf,
  shortlist = 10,
  refine = TRUE
)

allocation_discrete(
  demand,
  bb_area,
  candidate,
  facilities = NULL,
  n_fac = Inf,
  n_samples,
  traveltime = NULL,
  mode = "walk",
  dowscaling_model_type = NULL,
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

  A [`RasterLayer`](https://rdrr.io/pkg/raster/man/raster.html) or
  single-layer
  [`SpatRaster`](https://rspatial.github.io/terra/reference/rast.html)
  object with the demand (e.g., number of people per cell), in
  geographic coordinates (WGS 84). It defines the grid of the analysis.

- bb_area:

  A [`sf`](https://r-spatial.github.io/sf/reference/st_as_sf.html)
  object with the polygon(s) of the area of interest.

- facilities:

  A [`sf`](https://r-spatial.github.io/sf/reference/st_as_sf.html)
  object with the existing facilities, or `NULL` if there are no
  existing facilities. Required by `allocation()` (use
  `facilities = NULL` explicitly to allocate from scratch); optional in
  `allocation_discrete()` (default: `NULL`).

- traveltime:

  (optional) The output of the
  [`traveltime()`](https://giacfalk.github.io/locationallocation/reference/traveltime.md)
  function, whose friction surface is reused to avoid downloading and
  downscaling it again. The travel times from `facilities` are
  recomputed on this surface. If `NULL`, the friction surface is
  computed with
  [`friction()`](https://giacfalk.github.io/locationallocation/reference/friction.md)
  using `mode` and `res_output` (default: `NULL`).

- mode:

  (optional) A [`character`](https://rdrr.io/r/base/character.html)
  string indicating the mode of transport. Options are `"fastest"` and
  `"walk"` (default: `"walk"`).

  - For `"fastest"`: The friction layer accounts for multiple modes of
    transport, including walking and driving. At the native resolution,
    it is the Malaria Atlas Project (2015) *Global Travel Speed Friction
    Surface*.

  - For `"walk"`: The friction layer accounts only for walking speeds
    and is based on the Malaria Atlas Project (2020) *Global Walking
    Only Friction Surface*.

- dowscaling_model_type:

  Deprecated and ignored. The friction surface is no longer downscaled
  with a statistical model (see *Details*).

- res_output:

  (optional) A positive
  [integerish](https://mllg.github.io/checkmate/reference/checkIntegerish.html)
  number indicating the spatial resolution of the friction raster (and
  of the analysis), in meters. See *Details* (default: `100`).

- weights:

  (optional) A
  [`RasterLayer`](https://rdrr.io/pkg/raster/man/raster.html) or
  [`SpatRaster`](https://rspatial.github.io/terra/reference/rast.html)
  object with the weights for the demand (e.g., a hazard layer). It is
  resampled to the grid of `demand` if needed (default: `NULL`).

- objectiveminutes:

  (optional) A number indicating the travel time threshold, in minutes,
  within which demand is considered covered (default: `15`).

- objectiveshare:

  (optional) A number between `0` and `1` indicating the share of the
  (weighted) demand to be covered. In `allocation()` it can only be
  `NULL` if `n_fac` is finite (default: `0.99` for `allocation()` and
  `NULL` for `allocation_discrete()`).

- heur:

  (optional) The score used by `allocation()` to shortlist promising
  locations for each new facility. Options are `"kd"` and `"max"`. See
  *Details* (default: `"kd"`).

- approach:

  (optional) The approach used to combine the `demand` and `weights`
  layers. Options are `"norm"` and `"absweights"`. See *Details*
  (default: `"norm"`).

- exp_demand:

  (optional) The exponent applied to the demand layer. Values greater
  than `1` increase the relative priority of high-demand cells, and the
  influence of `demand` with respect to `weights` (default: `1`).

- exp_weights:

  (optional) The exponent applied to the weights layer. Values greater
  than `1` increase the relative priority of cells with high weights,
  and the influence of `weights` with respect to `demand` (default:
  `1`).

- n_fac:

  (optional) A positive
  [integerish](https://mllg.github.io/checkmate/reference/checkIntegerish.html)
  number indicating the maximum number of new facilities to allocate. In
  `allocation_discrete()`, it is capped at the number of candidate
  locations (default: `Inf`).

- shortlist:

  (optional) A positive
  [integerish](https://mllg.github.io/checkmate/reference/checkIntegerish.html)
  number indicating how many new promising locations `allocation()`
  evaluates exactly at each iteration. See *Details* (default: `10`).

- refine:

  (optional) A [`logical`](https://rdrr.io/r/base/logical.html) flag
  indicating whether `allocation()` refines the greedy solution by
  vertex substitution (see *Details*). Refinement usually reduces the
  number of facilities needed for a given coverage, but takes more time
  (default: `TRUE`).

- candidate:

  A [`sf`](https://r-spatial.github.io/sf/reference/st_as_sf.html)
  object with the candidate locations (`POINT` geometries) for the new
  facilities (`allocation_discrete()` only).

- n_samples:

  Deprecated and ignored. `allocation_discrete()` no longer relies on
  random sampling (`allocation_discrete()` only).

- par:

  (optional) A [`logical`](https://rdrr.io/r/base/logical.html) flag
  indicating whether to compute the travel times from the candidate
  locations in [parallel](https://rdrr.io/r/parallel/clusterApply.html)
  (`allocation_discrete()` only; default: `FALSE`).

## Value

An [invisible](https://rdrr.io/r/base/invisible.html)
[`list`](https://rdrr.io/r/base/list.html) of class `allocation`
(continuous problem) or `allocation_discrete` (discrete problem) with
the following elements:

- `coverage`: A [`numeric`](https://rdrr.io/r/base/numeric.html) value
  indicating the share of (weighted) demand covered within the objective
  travel time after allocating the new facilities.

- `unmet_demand`: A [`numeric`](https://rdrr.io/r/base/numeric.html)
  value indicating the share of (weighted) demand that remains unmet
  after allocating the new facilities.

- `objective_minutes`: The value of the `objectiveminutes` parameter
  used.

- `objective_share`: The value of the `objectiveshare` parameter used.

- `facilities`: A
  [`sf`](https://r-spatial.github.io/sf/reference/sf.html) object with
  the newly allocated facilities (for `allocation_discrete()`, the
  selected rows of `candidate`).

- `travel_time`: A
  [`RasterLayer`](https://rdrr.io/pkg/raster/man/raster.html) object, on
  the grid of `demand`, with the travel time (in minutes) to the nearest
  facility after allocating the new facilities.

## Details

### Coverage

A demand cell is covered when its travel time to the nearest (existing
or new) facility is less than or equal to `objectiveminutes`. Coverage
is the share of the total (weighted) demand within `bb_area` that is
covered. Travel times are computed with the accumulated cost algorithm
([`gdistance::accCost()`](https://AgrDataSci.github.io/gdistance/reference/accCost.html))
over the friction surface and aligned to the grid of `demand`.

### Continuous problem (`allocation()`)

Facilities are added one at a time with a (lazy) greedy heuristic. At
each iteration:

1.  A score of the demand not yet covered proposes a shortlist of
    promising locations: the `shortlist` highest local maxima of the
    score, at least half a catchment radius apart. The catchment radius
    is the distance that can be traveled within `objectiveminutes` at
    the median friction of the study area. The score is:

    - `heur = "kd"`: the uncovered demand smoothed with a quartic kernel
      whose bandwidth is the catchment radius, i.e., an estimate of the
      uncovered demand within the catchment of a facility placed at each
      cell.

    - `heur = "max"`: the uncovered demand of each cell.

2.  The catchment of each shortlisted location (the demand cells it can
    reach within `objectiveminutes`) is computed with the accumulated
    cost algorithm. Catchments do not change as facilities are added, so
    the locations evaluated in previous iterations remain candidates at
    no extra cost.

3.  The new facility is placed at the evaluated location that covers the
    largest amount of uncovered demand (greedy step of Church & ReVelle,
    1974).

The greedy phase stops when `objectiveshare` is reached, when `n_fac`
new facilities have been allocated, or when no further location
increases the coverage. The solution is then refined (vertex
substitution heuristic, Teitz & Bart, 1968): each facility is in turn
moved to the evaluated location that covers the most demand left
uncovered by the others, if that increases the coverage. New locations
are evaluated near each facility at every pass: local maxima of the
score, and eight locations around the facility at a distance that starts
at half the catchment radius and is halved whenever the facility is not
moved (pattern search). With `objectiveshare`, the facility covering the
least demand on its own is then dropped and the solution refined again,
as long as the target is still met.

Larger `shortlist` values evaluate more locations per iteration, which
can yield better solutions at the cost of more travel time computations.
Set `refine = FALSE` to skip the refinement phase for faster,
greedy-only solutions.

### Discrete problem (`allocation_discrete()`)

Since the travel time from a set of facilities is the minimum of the
travel times from each of them, the set of demand cells covered by each
candidate location is computed once (one accumulated cost run per
candidate). Then:

1.  Candidates are added one at a time, each time selecting the
    candidate that covers the largest amount of demand not yet covered
    (greedy heuristic, Church & ReVelle, 1974).

2.  The selection is refined by swapping selected and non-selected
    candidates as long as a swap increases the coverage (vertex
    substitution heuristic, Teitz & Bart, 1968).

If `objectiveshare` is `NULL`, up to `n_fac` candidates are selected to
maximize coverage. Otherwise, candidates are added (and the selection
refined) until `objectiveshare` is reached or `n_fac` candidates have
been selected. The solution is deterministic and usually optimal or
near-optimal.

### Demand weights

When `weights` is provided, the demand to be covered is a combination of
the `demand` and `weights` layers (e.g., population times exposure to a
hazard):

- `approach = "norm"`: \\D^{a} \times W^{b}\\, where \\D\\ and \\W\\ are
  the demand and weights layers rescaled to \\\[0, 1\]\\ (min-max
  normalization). Note that cells with the lowest weight receive zero
  priority.

- `approach = "absweights"`: \\D^{a} \times w^{b}\\, where \\w\\ are the
  raw (non-negative) weights. Priorities are proportional to the
  weights.

with \\a\\ = `exp_demand` and \\b\\ = `exp_weights`. Without `weights`,
the demand is \\demand^{a}\\. Coverage and `objectiveshare` then refer
to this weighted demand.

## References

Church, R., & ReVelle, C. (1974). The maximal covering location problem.
*Papers of the Regional Science Association*, *32*(1), 101–118.
[doi:10.1007/BF01942293](https://doi.org/10.1007/BF01942293)

Teitz, M. B., & Bart, P. (1968). Heuristic methods for estimating the
generalized vertex median of a weighted graph. *Operations Research*,
*16*(5), 955–961.
[doi:10.1287/opre.16.5.955](https://doi.org/10.1287/opre.16.5.955)

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
#> ✔ Using user-provided friction data file [615ms]
#> 
#> ℹ Computing transition matrix and geocorrection
#> ✔ Computing transition matrix and geocorrection [70ms]
#> 
#> ℹ Computing travel time map
#> ✔ Computing travel time map [19ms]
#> 

# A coarser demand grid (~360 m) keeps the example fast
demand <- raster::aggregate(naples_population, fact = 4, fun = sum)

## Continuous problem: 3 new facilities -----

allocation_data <-
  demand |>
  allocation(
    bb_area = naples_shape,
    facilities = naples_fountains,
    traveltime = traveltime_data,
    weights = naples_hot_days,
    objectiveminutes = 15,
    objectiveshare = NULL,
    n_fac = 3,
    refine = FALSE # Faster, greedy-only solution
  )
#> ℹ Resampling weights to the grid of demand.
#> ℹ Facility 1: share of unmet demand: 4.75306%.
#> ℹ Facility 2: share of unmet demand: 3.31196%.
#> ℹ Facility 3: share of unmet demand: 2.21634%.
#> 
#> ℹ 3 facilities allocated within the 15 minutes threshold. The coverage share
#> attained is 97.78366%.

allocation_data
#> Maximal coverage location-allocation (continuous problem)
#> ℹ 3 facilities allocated within the 15 minutes threshold. The coverage share
#> attained is 97.78366%.
#> 
#> Simple feature collection with 3 features and 0 fields
#> Geometry type: POINT
#> Dimension:     XY
#> Bounding box:  xmin: 14.23708 ymin: 40.85292 xmax: 14.28708 ymax: 40.89625
#> Geodetic CRS:  WGS 84
#>                    geometry
#> 1 POINT (14.27042 40.88625)
#> 2 POINT (14.23708 40.89625)
#> 3 POINT (14.28708 40.85292)

## Discrete problem: 2 of 6 candidate locations -----

set.seed(1)

candidate <- sf::st_sample(naples_shape, 6)
#> Warning: coordinate ranges not computed along great circles; install package lwgeom to get rid of this warning

allocation_data <-
  demand |>
  allocation_discrete(
    bb_area = naples_shape,
    candidate = candidate,
    facilities = naples_fountains,
    traveltime = traveltime_data,
    n_fac = 2,
    objectiveminutes = 15
  )
#> ℹ Facility 1: share of unmet demand: 7.35845%.
#> ℹ Facility 2: share of unmet demand: 7.31739%.
#> 
#> ℹ 2 facilities allocated within the 15 minutes threshold. The coverage share
#> attained is 92.68261%.

allocation_data
#> Maximal coverage location-allocation (discrete problem)
#> ℹ 2 facilities allocated within the 15 minutes threshold. The coverage share
#> attained is 92.68261%.
#> 
#> Simple feature collection with 2 features and 0 fields
#> Geometry type: POINT
#> Dimension:     XY
#> Bounding box:  xmin: 14.17376 ymin: 40.82542 xmax: 14.21626 ymax: 40.8868
#> Geodetic CRS:  WGS 84
#>                           x
#> 1 POINT (14.17376 40.82542)
#> 2  POINT (14.21626 40.8868)
```
