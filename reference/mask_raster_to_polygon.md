# Mask a `RasterLayer` object to a `sf` object

This function rapidly masks a
[`RasterLayer`](https://rdrr.io/pkg/raster/man/raster.html) object to a
[`sf`](https://r-spatial.github.io/sf/reference/st_as_sf.html) object.

## Usage

``` r
mask_raster_to_polygon(ras, mask, inverse = FALSE, updatevalue = NA)
```

## Arguments

- ras:

  A [`RasterLayer`](https://rdrr.io/pkg/raster/man/raster.html) object.

- mask:

  A [`RasterLayer`](https://rdrr.io/pkg/raster/man/raster.html) or
  [`sf`](https://r-spatial.github.io/sf/reference/st_as_sf.html) object.

- inverse:

  A [`logical`](https://rdrr.io/r/base/logical.html) flag. If `TRUE`,
  the mask is inverted (default: `FALSE`).

- updatevalue:

  The value to update the
  [`RasterLayer`](https://rdrr.io/pkg/raster/man/raster.html) object
  with (default: `NA`).

## Value

A masked [`RasterLayer`](https://rdrr.io/pkg/raster/man/raster.html)
object.

## Examples

``` r
naples_population |> mask_raster_to_polygon(naples_shape)
#> class      : RasterLayer 
#> dimensions : 146, 261, 38106  (nrow, ncol, ncell)
#> resolution : 0.0008333333, 0.0008333333  (x, y)
#> extent     : 14.13542, 14.35292, 40.79292, 40.91458  (xmin, xmax, ymin, ymax)
#> crs        : +proj=longlat +datum=WGS84 +no_defs 
#> source     : memory
#> names      : pop_napoli 
#> values     : 0, 1399.186  (min, max)
#> 
```
