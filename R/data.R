#' Administrative boundary of the city of Naples, Italy
#'
#' @description
#'
#' A [`sf`][sf::st_as_sf()] polygon geometry object representing the
#' administrative boundary of the city of Naples, Italy.
#'
#' @format A [`sf`][sf::st_as_sf()] `MULTIPOLYGON` geometry object with 1
#' feature and 8 fields:
#'
#' \describe{
#'   \item{GISCO_ID}{
#'   A [`character`][base::character()] field with the Geographic Information
#'   System of the Commission
#'   ([GISCO](https://ec.europa.eu/eurostat/web/gisco)) ID of the
#'   administrative unit.
#'   }
#'   \item{CNTR_CODE}{
#'   A [`character`][base::character()] field with the country code of Italy.
#'   }
#'   \item{LAU_ID}{
#'   A [`character`][base::character()] field with the Local Administrative
#'   Unit (LAU) ID of the administrative unit.
#'   }
#'   \item{LAU_NAME}{
#'   A [`character`][base::character()] field with the name of the
#'   administrative unit.
#'   }
#'   \item{POP_2021}{
#'   A [`double`][base::double()] field with the population of the
#'   administrative unit as of 2021.
#'   }
#'   \item{POP_DENS_2021}{
#'   A [`double`][base::double()] field with the population density (people per
#'   square kilometer) of the administrative unit as of 2021.
#'   }
#'   \item{AREA_KM2}{
#'   A [`double`][base::double()] field with the area (in square
#'   kilometers) of the administrative unit.
#'   }
#'   \item{YEAR}{
#'   A [`integer`][base::integer()] field with the year of the population
#'   data (2021).
#'   }
#' }
#'
#' @family datasets
"naples_shape"

#' Water fountains in the city of Naples, Italy
#'
#' @description
#'
#' A [`sf`][sf::st_as_sf()] polygon geometry object representing the
#' locations of water fountains in the city of Naples, Italy.
#'
#' @format A [`sf`][sf::st_as_sf()] `POINT` geometry object with 251
#' feature and 24 fields:
#'
#' @family datasets
"naples_fountains"

#' Population density in the city of Naples, Italy
#'
#' @description
#'
#' A [`stars`][stars::st_as_stars()] object representing the population
#' density in the city of Naples, Italy.
#'
#' The dataset is based on the Global Human
#' Settlement Layer
#' ([GHSL](https://human-settlement.emergency.copernicus.eu)) population grid
#' ([GHS-POP](
#' https://human-settlement.emergency.copernicus.eu/download.php?ds=pop)).
#'
#' @format A [`stars`][stars::st_as_stars()] object with 1 layer.
#'
#' @source Global Human Settlement Layer
#' ([GHSL](https://human-settlement.emergency.copernicus.eu)).
#'
#' @family datasets
"naples_population"

#' Hot days in the city of Naples, Italy
#'
#' @description
#'
#' A [`stars`][stars::st_as_stars()] object representing the number of hot
#' days in the city of Naples, Italy.
#'
#' This 100-meter resolution heat hazard map shows the number of days with
#' [Wet-Bulb Globe Temperature](
#' https://en.wikipedia.org/wiki/Wet-bulb_globe_temperature)
#' above 25 °C during 2008–2017, based on simulations from the
#' [UrbClim](https://www.urban-climate.eu/model) model.
#'
#' @format A [`stars`][stars::st_as_stars()] object with 1 layer.
#'
#' @source [UrbClim](https://www.urban-climate.eu/model).
#'
#' @family datasets
"naples_hot_days"
