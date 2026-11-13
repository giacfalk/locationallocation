# Download a friction surface at the resolution of the analysis

`friction()` retrieves a [friction
surface](https://en.wikipedia.org/wiki/Friction_of_distance) layer from
the Malaria Atlas Project ([MAP](https://malariaatlas.org/)) database
(Hay et al., 2006; Weiss et al., 2018, 2020) and produces it at the
spatial resolution of the analysis, following the rules used to build
the MAP surfaces.

Friction values are expressed in minutes required to travel one meter.

An internet connection is required, unless the data are supplied via
`file` and `roads`, or were cached by a previous call with
`cache = TRUE`.

## Usage

``` r
friction(
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
  unavailable. See *Details* of `friction()` (default: `FALSE`).

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
[`list`](https://rdrr.io/r/base/list.html) with the following elements:

- `friction_layer`: A
  [`RasterLayer`](https://rdrr.io/pkg/raster/man/raster.html) object
  with the friction surface layer (minutes per meter).

- `transition_matrix`: A
  [`TransitionLayer`](https://AgrDataSci.github.io/gdistance/reference/transition.html)
  with the transition matrix for cost-distance calculations.

- `geocorrection_matrix`: A
  [`TransitionLayer`](https://AgrDataSci.github.io/gdistance/reference/transition.html)
  with the geocorrection matrix for accurate distance calculations.

## Details

### Spatial resolution

The MAP surfaces have a resolution of 30 arc-seconds (~1 km). When
`res_output >= 1000`, the surface of the chosen `mode` is used at its
native resolution.

When `res_output < 1000`, the surface is produced on a grid of about
`res_output` meters following the rule used to build the MAP surfaces:
within each cell, the fastest mode of transport takes precedence (Weiss
et al., 2018).

- `mode = "walk"`: MAP assigns the same walking speed (5 km/h) to roads
  and to urban land, so the road network adds no information at a finer
  resolution. The walking-only surface is resampled to the finer grid
  (nearest neighbor) without changing its values.

- `mode = "fastest"`: cells crossed by a road get the speed of the
  fastest road crossing them (see `road_speeds`). All other cells get
  the friction of the MAP walking-only surface, which accounts for land
  cover and slope. Railways, ferries and congestion are not modeled.

The road network is downloaded from OpenStreetMap
([OSM](https://www.openstreetmap.org/)) through the Overpass API, unless
it is supplied via `roads`.

### Example data

The package includes a copy of the MAP walking-only friction surface for
the area of
[`naples_shape`](https://giacfalk.github.io/locationallocation/reference/naples_shape.md)
(`naples-friction-walk.tif`, see the examples), used to run the examples
offline. Source: Malaria Atlas Project (2020); see
<https://data.malariaatlas.org> for the terms of use.

### Online data and fallbacks

Online services can be unavailable or overloaded. The friction surface
is obtained from the first available of these sources:

1.  With `cache = TRUE`, the surface of the area cached by a previous
    call, or a cached copy of the global surface.

2.  The MAP data service (retried once).

3.  With `cache = TRUE`, a one-time download of the global surface (~730
    MB) from a mirror on the Open Science Framework
    ([OSF](https://osf.io/)), which is then cached.

If none is available, the error message suggests downloading the global
surface manually and supplying it via `file`.

The road network is obtained from the cache (with `cache = TRUE`) or
from several public Overpass API servers in turn (each with a single
attempt of at most ~2.5 minutes), skipping those that are unreachable or
at capacity. If none responds, a warning is issued and the MAP travel
speed surface (~1 km) is used on the finer grid instead.

Cached data are stored in
`tools::R_user_dir("locationallocation", "cache")`. The following
options change the default behavior:

- `locationallocation.cache_dir`: the cache directory.

- `locationallocation.overpass_urls`: the Overpass API servers to try,
  in order.

- `locationallocation.retry_wait`: the number of seconds to wait before
  retrying a failed download (default: `30`).

## References

Hay, S. I., & Snow, R. W. (2006). The Malaria Atlas Project: Developing
global maps of malaria risk. *PLOS Medicine*, *3*(12), e473.
[doi:10.1371/journal.pmed.0030473](https://doi.org/10.1371/journal.pmed.0030473)

Weiss, D. J., Nelson, A., Gibson, H. S., Temperley, W., Peedell, S.,
Lieber, A., Hancher, M., Poyart, E., Belchior, S., Fullman, N., Mappin,
B., Dalrymple, U., Rozier, J., Lucas, T. C. D., Howes, R. E., Tusting,
L. S., Kang, S. Y., Cameron, E., Bisanzio, D., ... Gething, P. W.
(2018). A global map of travel time to cities to assess inequalities in
accessibility in 2015. *Nature*, *553*(7688), 333–336.
[doi:10.1038/nature25181](https://doi.org/10.1038/nature25181)

Weiss, D. J., Nelson, A., Vargas-Ruiz, C. A., Gligorić, K., Bavadekar,
S., Gabrilovich, E., Bertozzi-Villa, A., Rozier, J., Gibson, H. S.,
Shekel, T., Kamath, C., Lieber, A., Schulman, K., Shao, Y., Qarkaxhija,
V., Nandi, A. K., Keddie, S. H., Rumisha, S., Amratia, P., ... Gething,
P. W. (2020). Global maps of travel time to healthcare facilities.
*Nature Medicine*, *26*(12), 1835–1838.
[doi:10.1038/s41591-020-1059-1](https://doi.org/10.1038/s41591-020-1059-1)

Malaria Atlas Project. (2015). *Friction surface: Global travel speed
friction surface* (Version 201501). <https://data.malariaatlas.org/maps>

Malaria Atlas Project. (2020). *Friction surface: Global walking only
friction surface* (Version 202001). <https://data.malariaatlas.org/maps>

OpenStreetMap Foundation. (n.d.). *OpenStreetMap* \[Computer software\].
<https://www.openstreetmap.org>

## See also

Other travel time functions:
[`default_road_speeds()`](https://giacfalk.github.io/locationallocation/reference/default_road_speeds.md),
[`traveltime()`](https://giacfalk.github.io/locationallocation/reference/traveltime.md),
[`traveltime_plot()`](https://giacfalk.github.io/locationallocation/reference/traveltime_plot.md),
[`traveltime_stats()`](https://giacfalk.github.io/locationallocation/reference/traveltime_stats.md)

## Examples

``` r
# Offline example with a bundled copy of the walking surface for Naples
friction_file <- system.file(
  "extdata", "naples-friction-walk.tif",
  package = "locationallocation"
)

friction_data <-
  naples_shape |>
  friction(res_output = 1000, file = friction_file)
#> ℹ Using user-provided friction data file
#> ✔ Using user-provided friction data file [492ms]
#> 
#> ℹ Computing transition matrix and geocorrection
#> ✔ Computing transition matrix and geocorrection [62ms]
#> 

friction_data$friction_layer
#> class      : RasterLayer 
#> dimensions : 15, 26, 390  (nrow, ncol, ncell)
#> resolution : 0.008333333, 0.008333333  (x, y)
#> extent     : 14.13333, 14.35, 40.79167, 40.91667  (xmin, xmax, ymin, ymax)
#> crs        : +proj=longlat +datum=WGS84 +no_defs 
#> source     : naples-friction-walk.tif 
#> names      : friction 
#> values     : 0.012, 0.06307979  (min, max)
#> 

if (FALSE) { # \dontrun{
# Download the surfaces (requires an internet connection)
naples_shape |> friction()

naples_shape |> friction(mode = "fastest", cache = TRUE)
} # }
```
