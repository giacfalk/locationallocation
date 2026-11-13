# Default speeds of OpenStreetMap road classes

`default_road_speeds()` returns the default speed (km/h) of each
OpenStreetMap road class (`highway` tag), used by
[`friction()`](https://giacfalk.github.io/locationallocation/reference/friction.md)
with `mode = "fastest"` to build friction surfaces finer than the native
resolution of the Malaria Atlas Project surfaces.

The values are the free-flow speeds of the car profile of the Open
Source Routing Machine ([OSRM](https://project-osrm.org/)). They do not
account for congestion, and can be modified and passed to the
`road_speeds` argument of
[`friction()`](https://giacfalk.github.io/locationallocation/reference/friction.md)
and
[`traveltime()`](https://giacfalk.github.io/locationallocation/reference/traveltime.md).

## Usage

``` r
default_road_speeds()
```

## Value

A named [`numeric`](https://rdrr.io/r/base/numeric.html) vector of
speeds in km/h.

## See also

Other travel time functions:
[`friction()`](https://giacfalk.github.io/locationallocation/reference/friction.md),
[`traveltime()`](https://giacfalk.github.io/locationallocation/reference/traveltime.md),
[`traveltime_plot()`](https://giacfalk.github.io/locationallocation/reference/traveltime_plot.md),
[`traveltime_stats()`](https://giacfalk.github.io/locationallocation/reference/traveltime_stats.md)

## Examples

``` r
default_road_speeds()
#>       motorway  motorway_link          trunk     trunk_link        primary 
#>             90             45             85             40             65 
#>   primary_link      secondary secondary_link       tertiary  tertiary_link 
#>             30             55             25             40             20 
#>   unclassified    residential  living_street        service 
#>             25             25             10             15 

# Slower urban speeds
speeds <- default_road_speeds()
speeds[c("primary", "secondary")] <- c(40, 30)
```
