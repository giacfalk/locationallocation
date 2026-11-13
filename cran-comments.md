## R CMD check results

0 errors | 0 warnings | 2 notes

* This is a new submission.
* The example of `allocation()` takes about 8 seconds, about half of which
  is the loading of the spatial dependencies on their first use in the
  examples. The other examples take less than 5 seconds.

## Test environments

* Local: Windows 11, R 4.5.3.
* GitHub Actions: macOS (R release), Windows (R release), Ubuntu (R devel,
  release, and oldrel-1).

## Comments

* The package downloads data from online services (the Malaria Atlas Project
  and OpenStreetMap). Examples that require these downloads are wrapped in
  `\dontrun{}`, because they need an internet connection and can take
  several minutes. All exported functions also have examples that run
  offline, using a small friction surface bundled with the package
  (`inst/extdata`). Tests run offline and mock all online requests.
* Downloaded data are only written to disk when users explicitly set
  `cache = TRUE`, in the directory given by `tools::R_user_dir()`.
