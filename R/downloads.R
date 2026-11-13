# Online data sources with fallbacks -----
#
# Friction surfaces (Malaria Atlas Project, MAP), tried in order:
#
# 1. With `cache = TRUE`: the surface of the area cached by a previous call,
#    then a cached copy of the global surface.
# 2. The MAP data service (retried once).
# 3. With `cache = TRUE`: a one-time download of the global surface from the
#    OSF mirror (~730 MB), cached for later calls.
#
# Road network (OpenStreetMap, OSM), tried in order:
#
# 1. With `cache = TRUE`: the road network of the area cached by a previous
#    call.
# 2. The Overpass API servers listed by `overpass_urls()`, in turn, skipping
#    servers that are unreachable or at capacity. Each server gets a single
#    attempt, with a time limit.
#
# If all sources fail, an error lists what was tried and the solutions.
#
# Options:
#
# - `locationallocation.cache_dir`: cache directory (default:
#   `tools::R_user_dir("locationallocation", "cache")`).
# - `locationallocation.overpass_urls`: Overpass API servers to try.
# - `locationallocation.retry_wait`: seconds to wait before retrying
#   (default: `30`).

map_datasets <- c(
  fastest = "Accessibility__201501_Global_Travel_Speed_Friction_Surface",
  walk = "Accessibility__202001_Global_Walking_Only_Friction_Surface"
)

map_global_urls <- c(
  "Accessibility__201501_Global_Travel_Speed_Friction_Surface" =
    "https://osf.io/za4cv/download",
  "Accessibility__202001_Global_Walking_Only_Friction_Surface" =
    "https://osf.io/yn78e/download"
)

retry_wait <- function() {
  getOption("locationallocation.retry_wait", 30)
}

internet_available <- function() {
  curl::has_internet()
}

overpass_urls <- function() {
  getOption(
    "locationallocation.overpass_urls",
    c(
      osmdata::get_overpass_url(),
      "https://overpass-api.de/api/interpreter",
      "https://maps.mail.ru/osm/tools/overpass/api/interpreter",
      "https://overpass.kumi.systems/api/interpreter",
      "https://overpass.private.coffee/api/interpreter"
    )
  ) |>
    unique()
}

# Key identifying the bounding box of an area in cache file names.
bbox_key <- function(bb_area) {
  bb_area |>
    sf::st_bbox() |>
    round(4) |>
    format(nsmall = 4, trim = TRUE) |>
    paste(collapse = "_")
}

# Run the functions in `sources` in order and return the first result that is
# not `NULL`, with the name of its source. Failures are collected in
# `errors`.
first_available <- function(sources) {
  errors <- character(0)

  for (name in names(sources)) {
    out <- tryCatch(sources[[name]](), error = function(e) e)

    if (inherits(out, "error")) {
      errors[[name]] <- conditionMessage(out)
    } else if (!is.null(out)) {
      return(list(value = out, source = name, errors = errors))
    }
  }

  list(value = NULL, source = NA_character_, errors = errors)
}

# Run `fun()`, retrying after `retry_wait()` seconds if it fails.
with_retry <- function(fun, attempts = 2) {
  for (attempt in seq_len(attempts)) {
    out <- tryCatch(fun(), error = function(e) e)

    if (!inherits(out, "error")) return(out)
    if (attempt < attempts) Sys.sleep(retry_wait())
  }

  stop(out)
}

# Friction surfaces -----

# MAP friction surface of a mode (`"walk"` or `"fastest"`), cropped to the
# area of interest, as a `RasterLayer`.
map_friction <- function(mode, bb_area, cache = FALSE, file = NULL) {
  if (!is.null(file)) {
    cli::cli_progress_step("Using user-provided friction data file")

    out <-
      file |>
      terra::rast() |>
      crop_to_area(bb_area) |>
      raster::raster() |>
      as_raster_layer(name = "file")

    names(out) <- "friction"

    return(out)
  }

  dataset <- map_datasets[[mode]]

  area_file <- file.path(
    get_cache_directory(),
    paste0(dataset, "-", bbox_key(bb_area), ".tif")
  )

  sources <- list()

  if (isTRUE(cache)) {
    sources[["cached surface of the area"]] <- function() {
      if (file.exists(area_file)) terra::rast(area_file)
    }

    sources[["cached global surface"]] <- function() {
      cached_global_surface(dataset)
    }
  }

  sources[["Malaria Atlas Project data service"]] <- function() {
    if (!internet_available()) stop("No internet connection.")

    cli::cli_progress_step(
      "Downloading friction data from the Malaria Atlas Project"
    )

    with_retry(\() download_map_area(dataset, bb_area))
  }

  if (isTRUE(cache)) {
    sources[["OSF mirror of the global surface"]] <- function() {
      if (!internet_available()) stop("No internet connection.")

      download_global_surface(dataset)
    }
  }

  result <- first_available(sources)

  if (is.null(result$value)) {
    cli::cli_abort(
      c(
        "The {mode} friction surface could not be obtained.",
        stats::setNames(
          cli_escape(paste0(names(result$errors), ": ", result$errors)),
          rep("x", length(result$errors))
        ),
        "i" = paste0(
          "Download the global surface ({.url {map_global_urls[[dataset]]}}) ",
          "and supply it via {.arg file}."
        ),
        "i" = if (!isTRUE(cache)) {
          paste0(
            "Or use {.code cache = TRUE} to fall back to a one-time ",
            "download of the global surface (~730 MB) from a mirror."
          )
        },
        "i" = "Or try again later."
      )
    )
  }

  out <- crop_to_area(result$value, bb_area)

  if (isTRUE(cache) && !grepl("^cached", result$source)) {
    get_cache_directory(create = TRUE)
    terra::writeRaster(out, area_file, overwrite = TRUE)
  }

  out <- as_raster_layer(raster::raster(out), name = "friction surface")
  names(out) <- "friction"

  out
}

download_map_area <- function(dataset, bb_area) {
  dataset |>
    malariaAtlas::getRaster(extent = matrix(sf::st_bbox(bb_area), ncol = 2)) |>
    quietly() |>
    as_spatraster() |>
    terra::toMemory()
}

# Global surface cached on disk (`NULL` if absent).
cached_global_surface <- function(dataset) {
  cache_dir <- get_cache_directory()

  files <- c(
    list.files(
      file.path(cache_dir, dataset),
      pattern = "\\.tif$",
      full.names = TRUE,
      recursive = TRUE
    ),
    # Layout of versions <= 0.1.1.
    list.files(
      cache_dir,
      pattern = paste0(substring(dataset, 16), ".*\\.tif$"),
      full.names = TRUE
    )
  )

  if (length(files) == 0) return(NULL)

  cli::cli_progress_step("Using cached global friction surface")

  terra::rast(files[1])
}

# Download the global surface from the OSF mirror into the cache directory.
download_global_surface <- function(dataset) {
  cli::cli_progress_step(
    paste0(
      "Downloading the global friction surface (~730 MB, once) ",
      "from the OSF mirror"
    )
  )

  zip_file <- tempfile(fileext = ".zip")
  on.exit(unlink(zip_file), add = TRUE)

  with_retry(
    \() curl::curl_download(map_global_urls[[dataset]], zip_file, quiet = TRUE)
  )

  zip::unzip(
    zip_file,
    exdir = file.path(get_cache_directory(create = TRUE), dataset)
  )

  out <- cached_global_surface(dataset)

  if (is.null(out)) {
    stop("The downloaded archive does not contain a GeoTIFF file.")
  }

  out
}

# Road network -----

# Road network (lines with a `highway` column) within the bounding box of
# `bb_area`, restricted to the road classes in `classes`.
osm_roads <- function(bb_area, classes, cache = FALSE) {
  file <- file.path(
    get_cache_directory(),
    paste0("osm-roads-", bbox_key(bb_area), ".rds")
  )

  if (isTRUE(cache) && file.exists(file)) {
    cached <- readRDS(file)

    if (all(classes %in% cached$classes)) {
      cli::cli_progress_step("Using cached OpenStreetMap road network")

      return(cached$roads)
    }
  }

  if (!internet_available()) {
    stop("No internet connection to download the OpenStreetMap road network.")
  }

  cli::cli_progress_step("Downloading road network data from OpenStreetMap")

  bbox <- sf::st_bbox(bb_area)
  errors <- character(0)
  roads <- NULL

  # Trying the next server is the retry: each server gets a single attempt.
  for (url in overpass_urls()) {
    host <- sub("^https?://([^/]+).*$", "\\1", url)

    out <- tryCatch(
      {
        overpass_available(url)
        query_overpass(url, bbox, classes)
      },
      error = function(e) e
    )

    if (!inherits(out, "error")) {
      roads <- out
      break
    }

    errors[[host]] <- conditionMessage(out)
  }

  if (is.null(roads)) {
    stop(
      paste0(
        "all Overpass API servers failed (",
        paste0(names(errors), ": ", errors, collapse = "; "),
        ")"
      )
    )
  }

  if (nrow(roads) == 0) {
    roads <- sf::st_sf(
      highway = character(0),
      geometry = sf::st_sfc(crs = 4326)
    )
  }

  roads <- roads[, "highway"]

  if (isTRUE(cache)) {
    get_cache_directory(create = TRUE)
    saveRDS(list(classes = classes, roads = roads), file)
  }

  roads
}

# Fail fast when an Overpass server is unreachable or at capacity.
overpass_available <- function(url) {
  status <- sub("interpreter/?$", "status", url)

  response <- curl::curl_fetch_memory(
    status,
    handle = curl::new_handle(timeout = 20)
  )

  if (response$status_code != 200) {
    stop("server unavailable (HTTP ", response$status_code, ")")
  }

  invisible(TRUE)
}

# Query an Overpass server for the road network. The query is sent with a
# single attempt and a client-side time limit (`osmdata` retries up to ten
# times, which can take very long on an overloaded server), and the response
# is parsed by `osmdata`.
query_overpass <- function(url, bbox, classes, timeout = 120) {
  query <-
    bbox |>
    osmdata::opq(timeout = timeout) |>
    osmdata::add_osm_feature(key = "highway", value = classes)

  response <- overpass_post(url, osmdata::opq_string(query), timeout + 30)

  if (response$status_code != 200) {
    stop("HTTP ", response$status_code)
  }

  content <- rawToChar(response$content)

  if (grepl("runtime error", content, fixed = TRUE)) {
    stop("the query failed on the server (runtime error)")
  }

  file <- tempfile(fileext = ".osm")
  on.exit(unlink(file), add = TRUE)
  writeLines(content, file, useBytes = TRUE)

  roads <-
    osmdata::osmdata_sf(query, doc = file) |>
    magrittr::extract2("osm_lines")

  if (is.null(roads) || nrow(roads) == 0) {
    roads <- sf::st_sf(
      highway = character(0),
      geometry = sf::st_sfc(crs = 4326)
    )
  }

  roads
}

overpass_post <- function(url, body, timeout) {
  curl::curl_fetch_memory(
    url,
    handle = curl::new_handle(copypostfields = body, timeout = timeout)
  )
}
