walking_surface <- function() {
  terra::toMemory(crop_to_area(terra::rast(problem$file), problem$bb_area))
}

area_file <- function(mode) {
  file.path(
    get_cache_directory(),
    paste0(map_datasets[[mode]], "-", bbox_key(problem$bb_area), ".tif")
  )
}

test_roads <- function() {
  sf::st_sf(
    highway = "primary",
    geometry = sf::st_sfc(
      sf::st_linestring(rbind(c(14.001, 40.8215), c(14.049, 40.8215))),
      crs = 4326
    )
  )
}

# Friction surfaces -----

test_that("map_friction() retries the MAP service", {
  calls <- 0

  local_mocked_bindings(
    internet_available = function() TRUE,
    download_map_area = function(dataset, bb_area) {
      calls <<- calls + 1
      if (calls == 1) stop("HTTP 503")
      walking_surface()
    }
  )

  out <- suppressMessages(map_friction("walk", problem$bb_area))

  expect_s4_class(out, "RasterLayer")
  expect_equal(calls, 2)
})

test_that("map_friction() explains how to proceed when all sources fail", {
  local_mocked_bindings(
    internet_available = function() TRUE,
    download_map_area = function(dataset, bb_area) stop("HTTP 503 {busy}")
  )

  error <- expect_error(
    suppressMessages(map_friction("walk", problem$bb_area))
  )

  message <- conditionMessage(error)

  expect_match(message, "HTTP 503 {busy}", fixed = TRUE)
  expect_match(message, "file", fixed = TRUE)
  expect_match(message, "cache = TRUE", fixed = TRUE)
  expect_match(message, "osf.io", fixed = TRUE)

  local_mocked_bindings(internet_available = function() FALSE)

  expect_error(
    suppressMessages(map_friction("walk", problem$bb_area)),
    "No internet connection"
  )
})

test_that("map_friction() falls back to the OSF mirror and caches the area", {
  unlink(area_file("walk"))
  on.exit(unlink(area_file("walk")))

  local_mocked_bindings(
    internet_available = function() TRUE,
    download_map_area = function(dataset, bb_area) stop("HTTP 503"),
    download_global_surface = function(dataset) terra::rast(problem$file)
  )

  out <- suppressMessages(map_friction("walk", problem$bb_area, cache = TRUE))

  expect_equal(unique(stats::na.omit(signif(raster::values(out), 6))), 0.012)
  expect_true(file.exists(area_file("walk")))

  # The cached area is then used without any download.
  local_mocked_bindings(
    internet_available = function() FALSE,
    download_global_surface = function(dataset) stop("should not be called")
  )

  cached <- suppressMessages(
    map_friction("walk", problem$bb_area, cache = TRUE)
  )

  expect_equal(raster::values(cached), raster::values(out))
})

test_that("map_friction() uses a cached global surface", {
  unlink(area_file("walk"))
  dir <- file.path(get_cache_directory(), map_datasets[["walk"]])
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  file.copy(problem$file, file.path(dir, "global.tif"), overwrite = TRUE)
  on.exit(unlink(c(dir, area_file("walk")), recursive = TRUE))

  local_mocked_bindings(
    internet_available = function() FALSE,
    download_map_area = function(dataset, bb_area) stop("should not be called")
  )

  out <- suppressMessages(map_friction("walk", problem$bb_area, cache = TRUE))

  expect_s4_class(out, "RasterLayer")
})

test_that("nothing is written to disk without cache = TRUE", {
  dir <- tempfile("cache")
  op <- options(locationallocation.cache_dir = dir)
  on.exit(options(op))

  local_mocked_bindings(
    internet_available = function() TRUE,
    download_map_area = function(dataset, bb_area) walking_surface()
  )

  suppressMessages(map_friction("walk", problem$bb_area))
  suppressMessages(friction(problem$bb_area, res_output = 100))

  expect_false(dir.exists(dir))
})

# Road network -----

test_that("osm_roads() tries other Overpass servers and caches the result", {
  file <- file.path(
    get_cache_directory(),
    paste0("osm-roads-", bbox_key(problem$bb_area), ".rds")
  )
  unlink(file)
  on.exit(unlink(file))

  queried <- character(0)

  local_mocked_bindings(
    internet_available = function() TRUE,
    overpass_urls = function() {
      c("https://busy.example/api/interpreter",
        "https://up.example/api/interpreter")
    },
    overpass_available = function(url) {
      if (grepl("busy", url)) stop("server unavailable (HTTP 502)")
      invisible(TRUE)
    },
    query_overpass = function(url, bbox, classes) {
      queried <<- c(queried, url)
      test_roads()
    }
  )

  roads <- suppressMessages(
    osm_roads(problem$bb_area, "primary", cache = TRUE)
  )

  expect_equal(queried, "https://up.example/api/interpreter")
  expect_equal(roads$highway, "primary")
  expect_true(file.exists(file))

  local_mocked_bindings(
    internet_available = function() FALSE,
    query_overpass = function(url, bbox, classes) stop("should not be called")
  )

  cached <- suppressMessages(
    osm_roads(problem$bb_area, "primary", cache = TRUE)
  )

  expect_equal(cached$highway, "primary")
})

test_that("query_overpass() parses responses and detects failures", {
  osm <- paste(
    '<?xml version="1.0" encoding="UTF-8"?>',
    '<osm version="0.6" generator="Overpass API">',
    '<node id="1" lat="40.8215" lon="14.001"/>',
    # `osmdata` needs at least one tagged node, as in real responses.
    '<node id="2" lat="40.8215" lon="14.049">',
    '<tag k="highway" v="traffic_signals"/></node>',
    '<way id="10"><nd ref="1"/><nd ref="2"/>',
    '<tag k="highway" v="primary"/></way>',
    "</osm>",
    sep = "\n"
  )

  respond <- function(status, text) {
    function(url, body, timeout) {
      list(status_code = status, content = charToRaw(text))
    }
  }

  bbox <- sf::st_bbox(problem$bb_area)

  local_mocked_bindings(overpass_post = respond(200, osm))
  roads <- query_overpass("https://up.example/api/interpreter", bbox, "primary")

  expect_s3_class(roads, "sf")
  expect_equal(roads$highway, "primary")

  local_mocked_bindings(overpass_post = respond(504, "Gateway Timeout"))
  expect_error(
    query_overpass("https://up.example/api/interpreter", bbox, "primary"),
    "HTTP 504"
  )

  local_mocked_bindings(
    overpass_post = respond(200, "<remark> runtime error: timeout </remark>")
  )
  expect_error(
    query_overpass("https://up.example/api/interpreter", bbox, "primary"),
    "runtime error"
  )
})

test_that("osm_roads() reports all failed servers", {
  local_mocked_bindings(
    internet_available = function() TRUE,
    overpass_urls = function() {
      c("https://a.example/api/interpreter",
        "https://b.example/api/interpreter")
    },
    overpass_available = function(url) stop("HTTP 429"),
    query_overpass = function(url, bbox, classes) stop("should not be called")
  )

  expect_error(
    suppressMessages(osm_roads(problem$bb_area, "primary")),
    "a.example: HTTP 429; b.example: HTTP 429"
  )
})

test_that("friction() falls back to the MAP travel speed surface", {
  local_mocked_bindings(
    internet_available = function() TRUE,
    osm_roads = function(bb_area, classes, cache) {
      stop("all Overpass API servers failed")
    },
    download_map_area = function(dataset, bb_area) {
      # A travel speed surface six times faster than walking.
      if (grepl("Travel_Speed", dataset)) walking_surface() / 6 else
        walking_surface()
    }
  )

  expect_warning(
    out <- suppressMessages(
      friction(problem$bb_area, mode = "fastest", res_output = 100)
    ),
    "road network could not be downloaded"
  )

  values <- stats::na.omit(raster::values(out$friction_layer))

  expect_equal(unique(signif(values, 6)), signif(0.012 / 6, 6))
})
