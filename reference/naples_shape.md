# Administrative boundary of the city of Naples, Italy

A [`sf`](https://r-spatial.github.io/sf/reference/st_as_sf.html) polygon
geometry object representing the administrative boundary of the city of
Naples, Italy.

## Usage

``` r
naples_shape
```

## Format

A [`sf`](https://r-spatial.github.io/sf/reference/st_as_sf.html)
`MULTIPOLYGON` geometry object with 1 feature and 8 fields:

- GISCO_ID:

  A [`character`](https://rdrr.io/r/base/character.html) field with the
  Geographic Information System of the Commission
  ([GISCO](https://ec.europa.eu/eurostat/web/gisco)) ID of the
  administrative unit.

- CNTR_CODE:

  A [`character`](https://rdrr.io/r/base/character.html) field with the
  country code of Italy.

- LAU_ID:

  A [`character`](https://rdrr.io/r/base/character.html) field with the
  Local Administrative Unit (LAU) ID of the administrative unit.

- LAU_NAME:

  A [`character`](https://rdrr.io/r/base/character.html) field with the
  name of the administrative unit.

- POP_2021:

  A [`double`](https://rdrr.io/r/base/double.html) field with the
  population of the administrative unit as of 2021.

- POP_DENS_2021:

  A [`double`](https://rdrr.io/r/base/double.html) field with the
  population density (people per square kilometer) of the administrative
  unit as of 2021.

- AREA_KM2:

  A [`double`](https://rdrr.io/r/base/double.html) field with the area
  (in square kilometers) of the administrative unit.

- YEAR:

  A [`integer`](https://rdrr.io/r/base/integer.html) field with the year
  of the population data (2021).

## See also

Other datasets:
[`naples_fountains`](https://giacfalk.github.io/locationallocation/reference/naples_fountains.md),
[`naples_hot_days`](https://giacfalk.github.io/locationallocation/reference/naples_hot_days.md),
[`naples_population`](https://giacfalk.github.io/locationallocation/reference/naples_population.md)
