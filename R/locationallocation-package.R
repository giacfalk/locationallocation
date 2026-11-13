#' locationallocation: Maximal Coverage Location-Allocation Using Geospatial
#' Data
#'
#' @description
#'
#' `locationallocation` solves Maximal Coverage Location-Allocation (MCLA)
#' problems with geospatial data: where to place new facilities so that as
#' much (optionally weighted) demand as possible can reach a facility within a
#' given travel time.
#'
#' @section Workflow:
#'
#' 1. [`friction()`][friction()] retrieves a friction surface (time needed to
#'    cross each cell) from the Malaria Atlas Project, for walking or for the
#'    fastest mode of transport, at the spatial resolution of the analysis.
#' 2. [`traveltime()`][traveltime()] computes the travel time from any cell
#'    to the nearest existing facility.
#'    [`traveltime_stats()`][traveltime_stats()] and
#'    [`traveltime_plot()`][traveltime_plot()] summarize and map it.
#' 3. [`allocation()`][allocation()] places new facilities anywhere within the
#'    area of interest (continuous problem), and
#'    [`allocation_discrete()`][allocation_discrete()] selects them among
#'    candidate locations (discrete problem), until a target share of the
#'    demand is covered or a maximum number of facilities is reached.
#'    [`allocation_plot()`][allocation_plot()] maps the result.
#'
#' Demand can be weighted by other layers (e.g., population times exposure to
#' a hazard). The package includes example data for the city of Naples, Italy
#' ([`naples_shape`], [`naples_population`], [`naples_fountains`],
#' [`naples_hot_days`]).
#'
#' @section Algorithms:
#'
#' Travel times are least-cost paths over the friction surface. Both
#' allocation problems are solved with a greedy heuristic that adds, at each
#' step, the location covering the most demand not yet covered (Church &
#' ReVelle, 1974), refined by vertex substitution (Teitz & Bart, 1968). See
#' [`allocation()`][allocation()] for details.
#'
#' @section Online data:
#'
#' Friction surfaces are downloaded from the Malaria Atlas Project and, for
#' the fastest mode at a fine resolution, road networks from OpenStreetMap.
#' Downloads have fallbacks (cache, retries, mirrors) and can be cached on
#' disk with `cache = TRUE`. See [`friction()`][friction()] for details and
#' for the options that control this behavior.
#'
#' @references
#'
#' Church, R., & ReVelle, C. (1974). The maximal covering location problem.
#' *Papers of the Regional Science Association*, *32*(1), 101–118.
#' \doi{10.1007/BF01942293}
#'
#' Teitz, M. B., & Bart, P. (1968). Heuristic methods for estimating the
#' generalized vertex median of a weighted graph. *Operations Research*,
#' *16*(5), 955–961. \doi{10.1287/opre.16.5.955}
#'
#' Weiss, D. J., Nelson, A., Gibson, H. S., Temperley, W., Peedell, S., Lieber,
#' A., Hancher, M., Poyart, E., Belchior, S., Fullman, N., Mappin, B.,
#' Dalrymple, U., Rozier, J., Lucas, T. C. D., Howes, R. E., Tusting, L. S.,
#' Kang, S. Y., Cameron, E., Bisanzio, D., ... Gething, P. W. (2018). A global
#' map of travel time to cities to assess inequalities in accessibility in
#' 2015. *Nature*, *553*(7688), 333–336. \doi{10.1038/nature25181}
#'
#' @keywords internal
"_PACKAGE"

# The following block is used by usethis to automatically manage
# roxygen namespace tags. Modify with care!
## usethis namespace: start
#' @importFrom magrittr %>%
## usethis namespace: end
NULL
