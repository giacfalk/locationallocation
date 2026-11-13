## Resubmission

This is a resubmission. In this version I have:

* Reduced the run time of the examples. The automatic incoming checks of
  version 0.2.0 reported that the example of `allocation()` took 10.3 s on
  Debian and 11.3 s on Windows. The allocation and masking code is now
  faster (with unchanged results), and the spatial dependencies are imported
  in the `NAMESPACE`, so they are loaded with the package rather than inside
  the first example. The slowest example (`allocation()`) now takes 2.8 s
  on win-builder (R-devel), down from 11.3 s, and 1.5 s locally with
  `R CMD check --as-cran --timings`.

* The incoming checks also flagged the following words in the DESCRIPTION
  as possibly misspelled. They are spelled correctly: "ReVelle" and "Teitz"
  are author names (Church and ReVelle, 1974; Teitz and Bart, 1968), "et
  al." is the standard abbreviation used in citations, and "geospatial" is
  a common technical term.

## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new submission. The note also lists the words in the
  DESCRIPTION discussed above.

## Test environments

* Local: Windows 11, R 4.5.3.
* win-builder: R-devel.
* GitHub Actions: macOS (R release), Windows (R release), Ubuntu (R release
  and oldrel-1).

## Comments

* The package downloads data from online services (the Malaria Atlas Project
  and OpenStreetMap). Examples that require these downloads are wrapped in
  `\dontrun{}`, because they need an internet connection and can take
  several minutes. All exported functions also have examples that run
  offline, using a small friction surface bundled with the package
  (`inst/extdata`). Tests run offline and mock all online requests.
* Downloaded data are only written to disk when users explicitly set
  `cache = TRUE`, in the directory given by `tools::R_user_dir()`.
