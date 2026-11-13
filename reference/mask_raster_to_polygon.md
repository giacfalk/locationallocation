# Mask a raster to a polygon or to another raster

`mask_raster_to_polygon()` sets to `updatevalue` (default: `NA`) all
cells of a raster that fall outside a
[`sf`](https://r-spatial.github.io/sf/reference/st_as_sf.html) polygon
(or that are `NA` in another raster).

## Usage

``` r
mask_raster_to_polygon(ras, mask, inverse = FALSE, updatevalue = NA)
```

## Arguments

- ras:

  A [`RasterLayer`](https://rdrr.io/pkg/raster/man/raster.html) or
  [`SpatRaster`](https://rspatial.github.io/terra/reference/rast.html)
  object.

- mask:

  A [`sf`](https://r-spatial.github.io/sf/reference/st_as_sf.html)
  object with `POLYGON` or `MULTIPOLYGON` geometries, or a
  [`RasterLayer`](https://rdrr.io/pkg/raster/man/raster.html) or
  [`SpatRaster`](https://rspatial.github.io/terra/reference/rast.html)
  object with the same geometry as `ras`.

- inverse:

  (optional) A [`logical`](https://rdrr.io/r/base/logical.html) flag. If
  `TRUE`, the mask is inverted, i.e., cells *inside* the polygon are
  masked (default: `FALSE`).

- updatevalue:

  (optional) The value assigned to the masked cells (default: `NA`).

## Value

A masked raster of the same class as `ras`.

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
