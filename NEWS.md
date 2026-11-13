# locationallocation (development version)

- The package citation (`citation("locationallocation")`) refers to version 2 of the preprint.

# locationallocation 0.2.0

## Bug fixes

- `allocation_discrete()` is exported again (it was dropped from the `NAMESPACE` when its source was merged into `R/allocation.R`).
- `allocation_discrete()` no longer fails with its default `n_fac = Inf`, with `n_fac = 1`, or when `n_fac` exceeds the number of candidates; with `objectiveshare`, it no longer skips the 1-facility solution or loops forever when `n_fac = 1`.
- `allocation_discrete()` no longer computes the friction surface twice when `facilities` is supplied without `traveltime`.
- `allocation(heur = "kd")` works (it previously always failed). The kernel score is reimplemented with `terra`, which removes the `spatialEco` dependency.
- `allocation()` no longer adds facilities that do not increase coverage, and it no longer picks up an object called `new_facilities` from the global environment.
- `friction()` no longer downscales the friction surface with `dissever`. The coarse Malaria Atlas Project (MAP) surfaces assign each ~1 km pixel the speed of the fastest mode of transport within it, whereas the mass-preserving downscaling forced fine cells to average to that value: it produced impossible speeds on road cells (faster than walking in `"walk"` mode) and slowed most other cells to ~2.6 km/h in the Naples example. The results were also not reproducible (random training sample, no seed).
- Online downloads now have fallbacks. Friction surfaces come from the first available of: the cache (surface of the area, or a cached global surface), the Malaria Atlas Project data service (retried), and, with `cache = TRUE`, a one-time download of the global surface (~730 MB) from the OSF mirror. The OpenStreetMap road network is retrieved from the cache or from several public Overpass API servers in turn, skipping servers that are unreachable or at capacity; if none responds, `friction()` warns and uses the Malaria Atlas Project travel speed surface instead. When all sources fail, the error lists what was tried and how to proceed (e.g., supplying `file` or `roads`). New options: `locationallocation.cache_dir`, `locationallocation.overpass_urls`, and `locationallocation.retry_wait`.
- `cache = TRUE` now caches the friction surface of the area and the road network, instead of always downloading the global friction surface (~730 MB), which is only downloaded as a fallback. Global surfaces cached by previous versions are still used.
- `friction(cache = TRUE)` no longer recurses indefinitely if the downloaded archive does not contain the expected file.
- `traveltime_plot()` works with `facilities = NULL` (the default) and with several `contour_traveltime` values.
- `traveltime_stats()` no longer overwrites the CRS of `demand`.
- `mask_raster_to_polygon()` now honors `updatevalue`, accepts raster masks, and transforms polygons to the CRS of the raster.
- Cropping the friction surface no longer adds a spurious row or column of cells when the boundary of `bb_area` coincides with cell edges.
- Coverage messages use the correct plural for the number of facilities.
- Documentation: the effect of `exp_demand` and `exp_weights` was described backwards; the years of the MAP friction surfaces were swapped; the default of `cache` was wrong; `naples_population` holds people per cell, not density.

## Changes

- `allocation_discrete()` now uses the deterministic greedy algorithm described in the package paper, refined with vertex substitution (Teitz & Bart, 1968), instead of random sampling. The travel time from each candidate is computed once, so the solver is much faster and returns optimal or near-optimal solutions. `n_samples` is deprecated and ignored; `par` now parallelizes the travel time computations.
- `allocation()` now implements the greedy step of the package paper (a lazy greedy heuristic): at each iteration, the heuristic score only shortlists promising locations, their actual catchments are computed, and the new facility goes to the evaluated location that covers the most uncovered demand. Previously, the facility was placed directly at the highest-scoring cell. The greedy solution is then refined by vertex substitution (Teitz & Bart, 1968) with a pattern search for new locations around each facility, and, with `objectiveshare`, by dropping facilities as long as the target is still met. New arguments: `shortlist` (locations evaluated per iteration) and `refine` (set to `FALSE` for faster, greedy-only solutions). The default `heur` is now `"kd"`. In the Naples example (with the downscaled friction surface of the previous version), 99% coverage was reached with 25 new facilities instead of 37, matching a near-optimal reference solution computed over a dense grid of candidate locations.
- Travel times in `allocation()` and `allocation_discrete()` are computed on a routing graph built once per problem, instead of rebuilding it at each `gdistance::accCost()` call. Results are identical, and each computation is about 8 times faster on the Naples example. Travel times are aligned to the `demand` grid in double precision (`terra::resample()` rounds values to single precision).
- At resolutions finer than 1 km (`res_output < 1000`), `friction()` now follows the rules used to build the MAP surfaces, where the fastest mode of transport within a cell takes precedence. In `"walk"` mode, MAP assigns 5 km/h to both roads and urban land, so the walking surface is resampled to the finer grid without changing its values (no OpenStreetMap download is needed). In `"fastest"` mode, cells crossed by an OpenStreetMap road get the speed of the fastest road class crossing them (new `road_speeds` argument; defaults from `default_road_speeds()`, the free-flow speeds of the OSRM car profile), and all other cells the MAP walking surface. New `roads` argument to supply the road network instead of downloading it; with `cache = TRUE`, the downloaded road network is cached on disk, and failed downloads are retried. `dowscaling_model_type` is deprecated and ignored, and the `dissever` dependency is removed.
- `allocation()` gains `n_fac`, the maximum number of new facilities. With a finite `n_fac`, `objectiveshare` can be `NULL` to allocate exactly `n_fac` facilities.
- `allocation()` accepts `facilities = NULL` to allocate facilities from scratch.
- In `allocation()` and `allocation_discrete()`, `traveltime` is only used for its friction surface: the travel times from `facilities` are recomputed on the unmasked surface, exactly as for new facilities. Previously, demand cells near the boundary of `bb_area` could be counted as uncovered even next to an existing facility. When `traveltime` is `NULL`, only `friction()` is run.
- `traveltime()` uses all facilities within the bounding box of `bb_area` as sources (previously only those inside the polygon), since facilities just outside the boundary still serve demand inside it.
- Travel times are aligned to the `demand` grid with nearest-neighbor resampling, so that the coverage reported by the allocation functions exactly matches their `travel_time` map. Coverage checks against `objectiveshare` now use the weighted demand.
- `allocation_plot()` gains a `facilities` argument to plot the existing facilities, and both plot functions draw the boundary of `bb_area` and show unreachable cells in gray.
- Inputs in any CRS are accepted for `sf` objects (they are transformed to WGS 84), and `demand`/`weights` can be `SpatRaster` objects. `weights` on a different grid are resampled to the grid of `demand`.
- New `print()` methods for the outputs of `traveltime()`, `allocation()` and `allocation_discrete()`.
- The `P15_cumsum` column of the `traveltime_stats()` data is renamed to `cumulative_coverage`.
- Updated the README, the package documentation (see `?locationallocation`), the package description, the citation metadata, and the package paper (methods, use case, and figures) to the current methods.
- All examples run offline, using a small copy of the Malaria Atlas Project walking surface for the Naples example (`inst/extdata/naples-friction-walk.tif`). Examples that download data are marked as requiring an internet connection.
- Added an offline test suite based on a synthetic problem, including a brute-force check of `allocation_discrete()`.

- Added a `cache` argument to `friction()` and `traveltime()` functions to enable caching of friction surfaces for improved performance on repeated calls.
- Added a `file` argument to `friction()` and `traveltime()` functions to allow loading a friction surface from disk.
- Refactored the codebase for better maintainability.
- Fixed R-CMD-check issues.
- Added [`checkmate`](https://mllg.github.io/checkmate/) for defensive programming.
- Added [`cli`](https://cli.r-lib.org/) for improved command line interface, including progress bars.
- Added [`lintr`](https://lintr.r-lib.org/) and updated the code to follow the [tidy tools manifesto](https://tidyverse.tidyverse.org/articles/manifesto.html), the [tidyverse design principles](https://design.tidyverse.org/), and the [tidyverse style guide](https://style.tidyverse.org/).
- Added [`spelling`](https://docs.ropensci.org/spelling/) for spell checking.
- Added [`testthat`](https://testthat.r-lib.org/) for unit testing.
- Added the [Contributor Code of Conduct v3](https://www.contributor-covenant.org/version/3/0/code_of_conduct/) to incentive contributions.
- Added `CITATION.cff` and `codemeta.json` files for better citation and metadata.
- Added a `NEWS.md` file to track changes to the package.
- Added an R-CMD-check GitHub Action workflow.
- Added default values to `allocation()`, `allocation_discrete()` and other functions.
- Added the demo data as documented exports, and changed their names to: `naples_shape`, `naples_population`, `naples_fountains`, and `naples_hot_days`.
- Added scale and north arrow annotations to maps using the [`ggspatial`](https://paleolimbot.github.io/ggspatial/) R package. These are on by default but can be disabled by setting the `annotation_scale` and `annotation_north_arrow` arguments to `FALSE`.
- Changed the theme of [`ggplot2`](https://ggplot2.tidyverse.org/) plots to `theme_minimal()` with customizations.
- Changed `allocation_plot()` to have `0` as a lower limit for the color scale.
- Merged `allocation_plot()` and `allocation_plot_discrete()` into a single `allocation_plot()` function.
- Changed `allocation()` and `allocation_discrete()` to raise an error when the initial coverage is greater or equal to the `objectiveshare` parameter.
- Changed `traveltime_plot()` to only show travel time contours up to the maximum travel time in the travel time map.
- Improved code efficiency and performance.
- Improved documentation and examples for all functions.
- Removed `demo_data_load()`, as it is no longer necessary.
- Removed the `fasterize` dependency due to compatibility issues with Linux systems.
- Updated `_pkgdown.yml` for better pkgdown site generation.
- Updated package dependencies to their latest versions.
- Updated README documentation and added badges for R-CMD-check, DOI, license, and Contributor Code of Conduct.

# locationallocation 0.1.1

- Updated weighting approach and added weights normalization and exponentiation arguments.

# locationallocation 0.1.0

- First release! 🎉

# locationallocation 0.0.1 (pre-release)

# locationallocation 0.0.0.9000

- Initial version.
