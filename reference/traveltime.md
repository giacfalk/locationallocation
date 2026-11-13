# Generate a travel time map

`traveltime()` generates a map of the travel time (in minutes) to the
nearest facility, based on the input facilities, area of interest, and
travel mode.

See the
[`friction()`](https://giacfalk.github.io/locationallocation/reference/friction.md)
function for details on how the friction layer is generated.

## Usage

``` r
traveltime(
  facilities,
  bb_area,
  mode = "walk",
  dowscaling_model_type = NULL,
  res_output = 100,
  cache = FALSE,
  file = NULL,
  roads = NULL,
  road_speeds = default_road_speeds()
)
```

## Arguments

- facilities:

  A [`sf`](https://r-spatial.github.io/sf/reference/st_as_sf.html)
  object with the existing facilities (`POINT` geometries).

- bb_area:

  A [`sf`](https://r-spatial.github.io/sf/reference/st_as_sf.html)
  object with the polygon(s) of the area of interest.

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

- cache:

  (optional) A [`logical`](https://rdrr.io/r/base/logical.html) flag
  indicating whether to cache downloaded data (friction surface of the
  area, road network) on disk and reuse it in later calls. It also
  enables a fallback to a one-time download of the global friction
  surface (~730 MB) when the Malaria Atlas Project service is
  unavailable. See *Details* of
  [`friction()`](https://giacfalk.github.io/locationallocation/reference/friction.md)
  (default: `FALSE`).

- file:

  (optional) A [`character`](https://rdrr.io/r/base/character.html)
  string indicating the path to a local Malaria Atlas Project friction
  surface raster file, used instead of downloading it: the walking-only
  surface, except with `mode = "fastest"` and `res_output >= 1000`,
  where it is the travel speed surface (default: `NULL`).

- roads:

  (optional) A
  [`sf`](https://r-spatial.github.io/sf/reference/st_as_sf.html) object
  with the road network (`LINESTRING` or `MULTILINESTRING` geometries),
  used when `mode = "fastest"` and `res_output < 1000`. It must have
  either a `speed` column with speeds in km/h, or a `highway` column
  with OpenStreetMap road classes, which are converted to speeds with
  `road_speeds`. If `NULL`, the road network is downloaded from
  OpenStreetMap (default: `NULL`).

- road_speeds:

  (optional) A named [`numeric`](https://rdrr.io/r/base/numeric.html)
  vector with the speed (km/h) of each OpenStreetMap road class
  (`highway` tag). Road classes not in `road_speeds` are ignored
  (default:
  [`default_road_speeds()`](https://giacfalk.github.io/locationallocation/reference/default_road_speeds.md)).

## Value

An [invisible](https://rdrr.io/r/base/invisible.html)
[`list`](https://rdrr.io/r/base/list.html) of class `traveltime` with
the following elements:

- `travel_time`: A
  [`RasterLayer`](https://rdrr.io/pkg/raster/man/raster.html) object
  with the travel time (in minutes) to the nearest facility.

- `friction`: A [`list`](https://rdrr.io/r/base/list.html) with the
  outputs of the
  [`friction()`](https://giacfalk.github.io/locationallocation/reference/friction.md)
  function.

## Details

All facilities within the extent of the friction surface (i.e., the
bounding box of `bb_area`) are used as sources, including those located
just outside the boundary of `bb_area`, since they can still serve
demand within it. The resulting travel time map is masked to `bb_area`.
Cells that cannot be reached from any facility (e.g., cells with no
friction data, such as open water) have an infinite travel time.

## See also

Other travel time functions:
[`default_road_speeds()`](https://giacfalk.github.io/locationallocation/reference/default_road_speeds.md),
[`friction()`](https://giacfalk.github.io/locationallocation/reference/friction.md),
[`traveltime_plot()`](https://giacfalk.github.io/locationallocation/reference/traveltime_plot.md),
[`traveltime_stats()`](https://giacfalk.github.io/locationallocation/reference/traveltime_stats.md)

## Examples

``` r
# Offline example with a bundled copy of the walking surface for Naples
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
#> ✔ Using user-provided friction data file [588ms]
#> 
#> ℹ Computing transition matrix and geocorrection
#> ✔ Computing transition matrix and geocorrection [41ms]
#> 
#> ℹ Computing travel time map
#> ✔ Computing travel time map [592ms]
#> 

traveltime_data
#> Travel time map
#> • Travel time (minutes): median 8.44, max 53.18
#> • Unreachable cells: 0 of 231
#> • Resolution: 0.00833 and 0.00833 degrees (15 x 26 cells)

if (FALSE) { # \dontrun{
# Download the friction surface (requires an internet connection)
traveltime_data <-
  naples_fountains |>
  traveltime(bb_area = naples_shape, mode = "walk", res_output = 100)
} # }
```
