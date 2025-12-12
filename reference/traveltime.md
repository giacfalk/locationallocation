# Generate a travel time map

`traveltime()` generates a travel time map based on the input
facilities, bounding box area, and travel mode.

See the
[`friction()`](https://giacfalk.github.io/locationallocation/reference/friction.md)
function for details on how the friction layer is generated.

## Usage

``` r
traveltime(
  facilities,
  bb_area,
  mode = "walk",
  dowscaling_model_type = "lm",
  res_output = 100,
  cache = FALSE,
  file = NULL
)
```

## Arguments

- facilities:

  A [`sf`](https://r-spatial.github.io/sf/reference/st_as_sf.html)
  object with the existing facilities.

- bb_area:

  A [`sf`](https://r-spatial.github.io/sf/reference/st_as_sf.html)
  boundary box object with the area of interest.

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

- cache:

  (optional) A [`logical`](https://rdrr.io/r/base/logical.html) flag
  indicating whether to cache the downloaded friction data for future
  use (default: `TRUE`).

- file:

  (optional) A [`character`](https://rdrr.io/r/base/character.html)
  string indicating the path to a local friction surface raster file. If
  provided, the function will use this file instead of downloading the
  friction data.

## Value

An [invisible](https://rdrr.io/r/base/invisible.html)
[`list`](https://rdrr.io/r/base/list.html) with the following elements:

- `travel_time`: A
  [`RasterLayer`](https://rdrr.io/pkg/raster/man/raster.html) object
  with the travel time map.

- `friction`: A [`list`](https://rdrr.io/r/base/list.html) with the
  outputs of the
  [`friction()`](https://giacfalk.github.io/locationallocation/reference/friction.md)
  function.

## See also

Other travel time functions:
[`friction()`](https://giacfalk.github.io/locationallocation/reference/friction.md),
[`traveltime_plot()`](https://giacfalk.github.io/locationallocation/reference/traveltime_plot.md),
[`traveltime_stats()`](https://giacfalk.github.io/locationallocation/reference/traveltime_stats.md)

## Examples

``` r
if (FALSE) { # \dontrun{
  library(dplyr)

  traveltime_data <-
    naples_fountains |>
    traveltime(
      bb_area = naples_shape,
      dowscaling_model_type = "lm",
      mode = "walk",
      res_output = 100
    )

  traveltime_data |> glimpse()

  traveltime_data |>
    traveltime_plot(
      bb_area = naples_shape,
      facilities = naples_fountains
  )
} # }
```
