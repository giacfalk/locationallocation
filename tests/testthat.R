library(checkmate)
library(magrittr)
library(testthat)

library(locationallocation)

test_check("locationallocation")

# # To Do -----
#
# - Reduce cyclomatic complexity.
# - Add unit tests.
# - Add test coverage (Codecov).
# - Move fully to the r-spatial framework (stars + sf).
# - Standardize parameter names (for example, `updatevalue` to `new_value`).
# - Merge `traveltime` and `traveltime_discrete`.
# - Merge `allocation` and `allocation_discrete`.
# - Document the data.
# - Add a contributor guide.
# - Add references to function documentations and data sources.
# - Update the hex logo.
# - Conduct a thorough review of all algorithms.
# - Unexport mask_raster_to_polygon().

# # For Development Use Only (Comment the Code After Use) -----
#
# cffr::cff_write()
# codemetar::write_codemeta()
# covr::codecov(token = "")
# covr::package_coverage()
# devtools::check()
# devtools::check(remote = TRUE, manual = TRUE)
# devtools::check_mac_release()
# devtools::check_win_devel()
# devtools::check_win_oldrelease()
# devtools::check_win_release()
# devtools::document()
# devtools::install()
# devtools::release()
# devtools::submit_cran()
# devtools:test()
# goodpractice::gp()
# lintr::lint_package()
# pkgdown::build_article("x")
# pkgdown::build_favicons(overwrite = TRUE)
# pkgdown::build_reference()
# pkgdown::build_site()
# revdepcheck::revdep_check(num_workers = 4)
# rutils::update_pkg_versions()
# rutils::update_pkg_year(here::here("inst", "CITATION"))
# spelling::spell_check_package()
# spelling::update_wordlist()
# tcltk::tk_choose.files()
# urlchecker::url_check()
# urlchecker::url_update()
# usethis::use_coverage()
# usethis::use_dev_version()
# usethis::use_github_action("check-standard")
# usethis::use_logo(tcltk::tk_choose.files())
# usethis::use_release_issue("#.#.#")
# usethis::use_revdep()
# usethis::use_tidy_description()
# usethis::use_version()
