# Download and downscale a friction surface layer

`friction()` retrieves a [friction
surface](https://en.wikipedia.org/wiki/Friction_of_distance) layer from
the Malaria Atlas Project ([MAP](https://malariaatlas.org/)) database
(Hay et al., 2006; Malaria Atlas Project, 2015, 2019) and optionally
downscale it to the spatial resolution of the analysis using road
network data from OpenStreetMap (n.d.)
([OSM](https://www.openstreetmap.org/)).

This function requires an active internet connection.

## Usage

``` r
friction(
  bb_area,
  mode = "walk",
  dowscaling_model_type = "lm",
  res_output = 100,
  cache = FALSE,
  file = NULL
)
```

## Arguments

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

- `friction_layer`: A
  [`RasterLayer`](https://rdrr.io/pkg/raster/man/raster.html) object
  with the friction surface layer.

- `transition_matrix`: A
  [`TransitionLayer`](https://AgrDataSci.github.io/gdistance/reference/transition.html)
  with the transition matrix for cost-distance calculations.

- `geocorrection_matrix`: A
  [`TransitionLayer`](https://AgrDataSci.github.io/gdistance/reference/transition.html)
  with the geocorrection matrix for accurate distance calculations.

## References

Hay, S. I., & Snow, R. W. (2006). The Malaria Atlas Project: Developing
global maps of malaria risk. *PLOS Medicine*, *3*(12), e473.
[doi:10.1371/journal.pmed.0030473](https://doi.org/10.1371/journal.pmed.0030473)

Malaria Atlas Project. (2015). *Friction surface: Global travel speed
friction surface* (Version 201501). <https://data.malariaatlas.org/maps>

Malaria Atlas Project. (2019). *Friction surface: Global walking only
friction surface* (Version 202001). <https://data.malariaatlas.org/maps>

OpenStreetMap Foundation. (n.d.). *OpenStreetMap* \[Computer software\].
<https://www.openstreetmap.org>

## See also

Other travel time functions:
[`traveltime()`](https://giacfalk.github.io/locationallocation/reference/traveltime.md),
[`traveltime_plot()`](https://giacfalk.github.io/locationallocation/reference/traveltime_plot.md),
[`traveltime_stats()`](https://giacfalk.github.io/locationallocation/reference/traveltime_stats.md)

## Examples

``` r
if (FALSE) { # \dontrun{
  naples_shape |> friction()
} # }
```
