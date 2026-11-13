# locationallocation: Maximal Coverage Location-Allocation Using Geospatial Data

`locationallocation` solves Maximal Coverage Location-Allocation (MCLA)
problems with geospatial data: where to place new facilities so that as
much (optionally weighted) demand as possible can reach a facility
within a given travel time.

## Workflow

1.  [`friction()`](https://giacfalk.github.io/locationallocation/reference/friction.md)
    retrieves a friction surface (time needed to cross each cell) from
    the Malaria Atlas Project, for walking or for the fastest mode of
    transport, at the spatial resolution of the analysis.

2.  [`traveltime()`](https://giacfalk.github.io/locationallocation/reference/traveltime.md)
    computes the travel time from any cell to the nearest existing
    facility.
    [`traveltime_stats()`](https://giacfalk.github.io/locationallocation/reference/traveltime_stats.md)
    and
    [`traveltime_plot()`](https://giacfalk.github.io/locationallocation/reference/traveltime_plot.md)
    summarize and map it.

3.  [`allocation()`](https://giacfalk.github.io/locationallocation/reference/allocation.md)
    places new facilities anywhere within the area of interest
    (continuous problem), and
    [`allocation_discrete()`](https://giacfalk.github.io/locationallocation/reference/allocation.md)
    selects them among candidate locations (discrete problem), until a
    target share of the demand is covered or a maximum number of
    facilities is reached.
    [`allocation_plot()`](https://giacfalk.github.io/locationallocation/reference/allocation_plot.md)
    maps the result.

Demand can be weighted by other layers (e.g., population times exposure
to a hazard). The package includes example data for the city of Naples,
Italy
([`naples_shape`](https://giacfalk.github.io/locationallocation/reference/naples_shape.md),
[`naples_population`](https://giacfalk.github.io/locationallocation/reference/naples_population.md),
[`naples_fountains`](https://giacfalk.github.io/locationallocation/reference/naples_fountains.md),
[`naples_hot_days`](https://giacfalk.github.io/locationallocation/reference/naples_hot_days.md)).

## Algorithms

Travel times are least-cost paths over the friction surface. Both
allocation problems are solved with a greedy heuristic that adds, at
each step, the location covering the most demand not yet covered (Church
& ReVelle, 1974), refined by vertex substitution (Teitz & Bart, 1968).
See
[`allocation()`](https://giacfalk.github.io/locationallocation/reference/allocation.md)
for details.

## Online data

Friction surfaces are downloaded from the Malaria Atlas Project and, for
the fastest mode at a fine resolution, road networks from OpenStreetMap.
Downloads have fallbacks (cache, retries, mirrors) and can be cached on
disk with `cache = TRUE`. See
[`friction()`](https://giacfalk.github.io/locationallocation/reference/friction.md)
for details and for the options that control this behavior.

## References

Church, R., & ReVelle, C. (1974). The maximal covering location problem.
*Papers of the Regional Science Association*, *32*(1), 101–118.
[doi:10.1007/BF01942293](https://doi.org/10.1007/BF01942293)

Teitz, M. B., & Bart, P. (1968). Heuristic methods for estimating the
generalized vertex median of a weighted graph. *Operations Research*,
*16*(5), 955–961.
[doi:10.1287/opre.16.5.955](https://doi.org/10.1287/opre.16.5.955)

Weiss, D. J., Nelson, A., Gibson, H. S., Temperley, W., Peedell, S.,
Lieber, A., Hancher, M., Poyart, E., Belchior, S., Fullman, N., Mappin,
B., Dalrymple, U., Rozier, J., Lucas, T. C. D., Howes, R. E., Tusting,
L. S., Kang, S. Y., Cameron, E., Bisanzio, D., ... Gething, P. W.
(2018). A global map of travel time to cities to assess inequalities in
accessibility in 2015. *Nature*, *553*(7688), 333–336.
[doi:10.1038/nature25181](https://doi.org/10.1038/nature25181)

## See also

Useful links:

- <https://giacfalk.github.io/locationallocation/>

- <https://github.com/giacfalk/locationallocation/>

- Report bugs at
  <https://github.com/giacfalk/locationallocation/issues/>

## Author

**Maintainer**: Giacomo Falchetta <giacomo.falchetta@cmcc.it>
([ORCID](https://orcid.org/0000-0003-2607-2195)) \[conceptor, copyright
holder\]

Other contributors:

- Daniel Vartanian <danielvartan@proton.me>
  ([ORCID](https://orcid.org/0000-0001-7782-759X)) \[contributor\]
