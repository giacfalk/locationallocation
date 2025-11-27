# Package index

## Travel Time

Functions to calculate travel time maps using geospatial data.

- [`friction()`](https://giacfalk.github.io/locationallocation/reference/friction.md)
  : Download and downscale a friction surface layer
- [`traveltime()`](https://giacfalk.github.io/locationallocation/reference/traveltime.md)
  : Generate a travel time map

## Maximal Coverage Location-Allocation (MCLA)

Functions to solve Maximal Coverage Location-Allocation problems using
geospatial data.

- [`allocation()`](https://giacfalk.github.io/locationallocation/reference/allocation.md)
  : Compute the maximal coverage location-allocation for continuous
  problems
- [`allocation_discrete()`](https://giacfalk.github.io/locationallocation/reference/allocation_discrete.md)
  : Compute the maximal coverage location-allocation for discrete
  problems

## Statistics

Functions to compute statistics from location-allocation model results.

- [`traveltime_stats()`](https://giacfalk.github.io/locationallocation/reference/traveltime_stats.md)
  :

  Summarize results of the
  [`traveltime()`](https://giacfalk.github.io/locationallocation/reference/traveltime.md)
  function

## Plots

Functions to visualize results from location-allocation models.

- [`allocation_plot()`](https://giacfalk.github.io/locationallocation/reference/allocation_plot.md)
  :

  Plot results of the
  [`allocation()`](https://giacfalk.github.io/locationallocation/reference/allocation.md)
  and
  [`allocation_discrete()`](https://giacfalk.github.io/locationallocation/reference/allocation_discrete.md)
  functions

- [`traveltime_plot()`](https://giacfalk.github.io/locationallocation/reference/traveltime_plot.md)
  :

  Plot results of the
  [`traveltime()`](https://giacfalk.github.io/locationallocation/reference/traveltime.md)
  function

## Data

Datasets included in the package for examples and testing.

- [`naples_shape`](https://giacfalk.github.io/locationallocation/reference/naples_shape.md)
  : Administrative boundary of the city of Naples, Italy
- [`naples_fountains`](https://giacfalk.github.io/locationallocation/reference/naples_fountains.md)
  : Water fountains in the city of Naples, Italy
- [`naples_population`](https://giacfalk.github.io/locationallocation/reference/naples_population.md)
  : Population density in the city of Naples, Italy
- [`naples_hot_days`](https://giacfalk.github.io/locationallocation/reference/naples_hot_days.md)
  : Hot days in the city of Naples, Italy

## Utilities

Utility functions to help with data manipulation.

- [`mask_raster_to_polygon()`](https://giacfalk.github.io/locationallocation/reference/mask_raster_to_polygon.md)
  :

  Mask a `RasterLayer` object to a `sf` object
