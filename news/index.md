# Changelog

## locationallocation 0.1.1.9000 (development version)

- Added a `cache` argument to
  [`friction()`](https://giacfalk.github.io/locationallocation/reference/friction.md)
  and
  [`traveltime()`](https://giacfalk.github.io/locationallocation/reference/traveltime.md)
  functions to enable caching of friction surfaces for improved
  performance on repeated calls.
- Added a `file` argument to
  [`friction()`](https://giacfalk.github.io/locationallocation/reference/friction.md)
  and
  [`traveltime()`](https://giacfalk.github.io/locationallocation/reference/traveltime.md)
  functions to allow loading a friction surface from disk.
- Refactored the codebase for better maintainability.
- Fixed R-CMD-check issues.
- Added [`checkmate`](https://mllg.github.io/checkmate/) for defensive
  programming.
- Added [`cli`](https://cli.r-lib.org/) for improved command line
  interface, including progress bars.
- Added [`lintr`](https://lintr.r-lib.org/) and updated the code to
  follow the [tidy tools
  manifesto](https://tidyverse.tidyverse.org/articles/manifesto.html),
  the [tidyverse design principles](https://design.tidyverse.org/), and
  the [tidyverse style guide](https://style.tidyverse.org/).
- Added [`spelling`](https://docs.ropensci.org/spelling/) for spell
  checking.
- Added [`testthat`](https://testthat.r-lib.org/) for unit testing.
- Added the [Contributor Code of Conduct
  v3](https://www.contributor-covenant.org/version/3/0/code_of_conduct/)
  to incentive contributions.
- Added `CITATION.cff` and `codemeta.json` files for better citation and
  metadata.
- Added a `NEWS.md` file to track changes to the package.
- Added an R-CMD-check GitHub Action workflow.
- Added default values to
  [`allocation()`](https://giacfalk.github.io/locationallocation/reference/allocation.md),
  [`allocation_discrete()`](https://giacfalk.github.io/locationallocation/reference/allocation_discrete.md)
  and other functions.
- Added the demo data as documented exports, and changed their names to:
  `naples_shape`, `naples_population`, `naples_fountains`, and
  `naples_hot_days`.
- Added scale and north arrow annotations to maps using the
  [`ggspatial`](https://paleolimbot.github.io/ggspatial/) R package.
  These are on by default but can be disabled by setting the
  `annotation_scale` and `annotation_north_arrow` arguments to `FALSE`.
- Changed the theme of [`ggplot2`](https://ggplot2.tidyverse.org/) plots
  to `theme_minimal()` with customizations.
- Changed
  [`allocation_plot()`](https://giacfalk.github.io/locationallocation/reference/allocation_plot.md)
  to have `0` as a lower limit for the color scale.
- Merged
  [`allocation_plot()`](https://giacfalk.github.io/locationallocation/reference/allocation_plot.md)
  and `allocation_plot_discrete()` into a single
  [`allocation_plot()`](https://giacfalk.github.io/locationallocation/reference/allocation_plot.md)
  function.
- Changed
  [`allocation()`](https://giacfalk.github.io/locationallocation/reference/allocation.md)
  and
  [`allocation_discrete()`](https://giacfalk.github.io/locationallocation/reference/allocation_discrete.md)
  to raise an error when the initial coverage is greater or equal to the
  `objectiveshare` parameter.
- Changed
  [`traveltime_plot()`](https://giacfalk.github.io/locationallocation/reference/traveltime_plot.md)
  to only show travel time contours up to the maximum travel time in the
  travel time map.
- Improved code efficiency and performance.
- Improved documentation and examples for all functions.
- Removed `demo_data_load()`, as it is no longer necessary.
- Removed the `fasterize` dependency due to compatibility issues with
  Linux systems.
- Updated `_pkgdown.yml` for better pkgdown site generation.
- Updated package dependencies to their latest versions.
- Updated README documentation and added badges for R-CMD-check, DOI,
  license, and Contributor Code of Conduct.

## locationallocation 0.1.1

- Updated weighting approach and added weights normalization and
  exponentiation arguments.

## locationallocation 0.1.0

- First release! 🎉

## locationallocation 0.0.1 (pre-release)

## locationallocation 0.0.0.9000

- Initial version.
