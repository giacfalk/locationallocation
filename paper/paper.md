---
title: "*locationallocation*: an R package for solving
  Maximal Coverage Location-Allocation geospatial infrastructure
  assessment and planning problems"
tags:
  - R
  - geographic information science
  - geospatial analysis
  - spatial optimisation
  - Maximal Coverage Location-Allocation problems
authors:
  - name: Giacomo Falchetta
    orcid: 0000-0003-2607-2195
    affiliation: "1, 2" # (Multiple affiliations must be quoted)
affiliations:
 - name: Centro Euro-Mediterraneo sui Cambiamenti Climatici, Venice, Italy
   index: 1
 - name: International Institute for Applied Systems Analysis, Laxenburg, Austria
   index: 2
repository: https://github.com/giacfalk/locationallocation
date: 24 March 2025
bibliography: paper.bib
---

# Summary

Assessing and planning infrastructure and networks over space
conditional to a spatially distributed demand and with consideration of
accessibility and spatial justice goals and under infrastructure
allocation constraints is a key policy objective
[@schindler2021getting; @seto2014human; @todes2012new; @brown2014spatial].
This is particularly crucial in cities because the world is keeping on
urbanizing (the size and share of global population classified as living
in urban areas has overtaken the rural population since 2007 and it
projected to increase to 68% by 2050 [@urbanization2018revision]).\

In facility allocation problems, one of the most critical considerations
is maximizing the coverage of demand points with a limited number of
facilities. The Maximal Coverage Location-Allocation (MCLA) seeks to
determine the best locations for facilities to serve the highest
possible number of demand points within a predefined distance or service
threshold. @Church1974 provided the first mathematical formulation of
the Maximal Covering Location Problem (MCLP) to determine the best
locations for facilities to maximize the coverage of demand within a
given distance or time constraint.\

Some of the primary reasons why MCLA problems are important include: (i)
efficient resource utilization, e.g. in the case of organizations
operating with limited resources, such as emergency response units,
public health clinics, or distribution centers. Here, solving the MCLA
problem helps optimize the placement of these resources to maximize
service coverage, ensuring that the highest number of people benefit
from the available facilities; (ii) another use case is emergency
response and public safety: in scenarios where response time is crucial,
such as ambulance or fire station placement, solving the MCLA problem
can directly impact lives. By strategically locating facilities,
authorities can reduce response times and improve emergency
preparedness; (iii) also in retail and service industry optimization,
solving the MCLA is key for businesses to maximize their customer base
while minimizing costs, for instance by identifying optimal store
locations, improving accessibility for the largest number of potential
customers; (iv) finally, in the domain of infrastructure and urban
planning governments and city planners use MCLA models to determine the
best locations for schools, hospitals, and transportation hubs. Properly
placed infrastructure ensures equitable access to essential services,
reducing disparities in service distribution.\

Recent work, such as @Bonnet2015, demonstrated an implementation of the
MCLA framework with the use of geospatial data for optimally locating
automated external defibrillators (AEDs) in cities to improve emergency
response times and cardiac arrest survival rates. Other studies, such as
@Falchetta2020 - upon which the scientific software package introduced
in this paper is building - demonstrated solutions to the MCLA for
healthcare facilities accessibility, a challenge which was already
explored (although mostly in a descriptive rather than planning-oriented
lens, by @weiss2020global). However, irrespective of such previous work
implementing the domains of data science and the solution to problem
such as MCLA (see the review of @chen2021open), existing open-source
implementations in R are limited to *traveltime* [@Ryan2025], which is
suitable to calculate descriptive snapshots and maps, the *maxcovr*
[@maxcovrbib] package (<https://github.com/njtierney/maxcovr>), which
however is not implemented in a way to be integrated with R's geospatial
data processing capabilities.\

The *locationallocation* R package allows spatially optimizing the
allocation of facilities and infrastructure based on spatial
accessibility criteria weighted by one or more variables or a function
of those. In *locationallocation*, such maximization can be modified to
e.g. minimize risk (exposure of the population times environmental
hazard), even considering population-specific vulnerability (age, health
status, other geographical features).\

Here, I introduce a concise mathematical formulation of the MCLP problem
and of its solution algorithm; then, I discuss the software and data
implementation that underlie the *locationallocation* R package. I then
present an use case of the package on how to tackle urban-scale climate
risk through infrastructure assessment and spatial planning based on
sample data and objectives. I conclude with a commentary on the
potential use cases of the package, as well as its current limitation
and potential for future further developments.\

# Statement of need

*locationallocation* is an R package to solve Maximal Coverage
Location-Allocation problems using geospatial data leveraging widely
used R programming language geospatial libraries. The package allows to
produce travel time maps and spatially optimizing the allocation of
facilities in both continuous and discrete choice problems and based on
spatial accessibility criteria weighted by one or more variables or a
function of those. *locationallocation* relies heavily on the
*malariaAtlas* package [@malariaAtlaspackage] to obtain the friction
layers used to compute the travel time by different means of transport,
as well as on the *gdistance* package [@gdistancepackage] to compute
transition matrices and run cumulative cost algorithms to compute travel
time maps.\

*locationallocation* is designed to be used in the domains of public
infrastructure assessment and planning (public services provision, e.g.
transport, social services, healthcare, parks), urban environmental and
climate risk reduction interventions, logistics and hubs allocation,
commercial and strategic decisions. The underlying approach has already
been used in a number of scientific publications [@Falchetta2020; @Falchetta2021], but
through this package it becomes formally available to the scientific and
practice communities.

# Methods and data {#methods-and-data .unnumbered}

## Maximal Coverage Location Problem (MCLP) {#maximal-coverage-location-problem-mclp .unnumbered}

Before introducing the software implementation and the functioning of
the *locationallocation* R package, it is worth providing a concise
mathematical formulation of the class of problems addressed by the
package.\
**Sets and Indices:**

- $I$ : Set of candidate facility locations ($i \in I$).

- $J$ : Set of demand points ($j \in J$).

**Parameters:**

- $w_j$ : Population (or demand weight) at location $j$.

- $d_{ij}$ : Travel time from facility location $i$ to demand point $j$.

- $T$ : Maximum acceptable travel-time threshold for coverage.

- $N_j = \{ i \in I \mid d_{ij} \leq T \}$ : Set of candidate facilities
  that can cover demand point $j$.

- *Optionally,* $P^(\star)$ : Maximum number of facilities to be located
  from a discrete set of pre-defined locations $P$ on the lattice space.

\
**Decision Variables:**

- $x_i \in \{0,1\}$ : 1 if a facility is located at site $i$, 0
  otherwise.

- $y_j \in \{0,1\}$ : 1 if demand point $j$ is covered by at least one
  facility, 0 otherwise.

\
**Objective Function:** Maximize the total covered population:

$$\max \sum_{j \in J} w_j y_j$$

**Constraints:**

1.  Coverage constraint: A demand point $j$ is covered if at least one
    facility in $N_j$ is selected:
    $$y_j \leq \sum_{i \in N_j} x_i, \quad \forall j \in J$$

2.  Binary constraints: $$x_i \in \{0,1\}, \quad \forall i \in I$$

    $$y_j \in \{0,1\}, \quad \forall j \in J$$

    and, optionally:\

3.  Facility location constraint (at most $P^(\star)$ facilities must be
    chosen from a discrete set of pre-defined locations $P$ on the
    lattice space): $$\sum_{i \in I} x_i \leq P^(\star)$$

## Problem solution algorithm {#problem-solution-algorithm .unnumbered}

Greedy Heuristic are used to identify quasi-optimal solution without
resorting to resource and time-intensive constrained optimization
approaches such as Mixed-Integer Programming (MIP):\

***
Require: Set of candidate facility locations $I$, set of demand points $J$,
travel-time matrix $d_{ij}$, population weights $w_j$, number of
facilities $P$, coverage threshold $T$.\
***
Ensure: A set $S$ of selected facility locations.\
***
1: Initialize $S \gets \emptyset$ \
2: Initialize $J_{\text{unmet}} \gets J$ \
3: for k = 1 to P* \in P do \
4: Find the facility $i^*$ that maximizes covered demand: \
$$i^* = \arg\max_{i \in I \setminus S} \sum_{j \in J_{\text{unmet}}} w_j \mathbb{1}(d_{ij} \leq T)$$
5: Add $i^*$ to the selected facilities: $S \gets S \cup \{ i^* \}$  \
6: Update covered demand points: \
$$J_{\text{unmet}} \gets J_{\text{unmet}} \setminus \{ j \mid d_{i^* j} \leq T \}$$
7: end for \
8: return S \

Since the travel time from a set of facilities is the minimum of the
travel times from each of them, the demand covered by a set of
facilities is the union of the catchments
$\{ j \mid d_{ij} \leq T \}$ of its members. The package exploits this
property in both versions of the problem:

- **Discrete problem.** $I$ is a user-defined set of candidate
  locations. The catchment of each candidate is computed once, so that
  step 4 is evaluated exactly over all candidates.

- **Continuous problem.** Any cell of the demand grid is a potential
  location, and computing the catchment of each of them would be
  prohibitive. At each iteration, a score of the uncovered demand
  proposes a shortlist of promising locations (the local maxima of the
  score): either the uncovered demand of each cell, or the uncovered
  demand smoothed with a kernel whose bandwidth is the distance that can
  be traveled within $T$, i.e., an estimate of the uncovered demand
  within the catchment of each cell. The catchments of the shortlisted
  locations are then computed, and step 4 is evaluated over all the
  locations evaluated so far (lazy greedy heuristic).

The greedy solution is then refined by vertex substitution
[@Teitz1968]: each selected facility is in turn replaced by the
location that covers the most demand left uncovered by the other
facilities, as long as such swaps increase the covered demand. In the
continuous problem, new locations around each facility are evaluated at
each pass (pattern search). When the objective is a target share of
covered demand rather than a fixed number of facilities $P^{\star}$,
facilities are added until the target is met and, in the continuous
problem, then dropped as long as the refined solution still meets the
target. The solutions are deterministic but, as with any heuristic, not
guaranteed to be globally optimal.

## Software and data implementation {#software-and-data-implementation .unnumbered}

The approach includes consideration of different travel modes and can be
applied to any location in the world. The Malaria Atlas Project friction
surfaces have a resolution of 30 arc-seconds (~1 km), and each of their
pixels takes the speed of the fastest mode of transport available within
it [@Weiss2018]. To perform location-allocation at a higher spatial
resolution (particularly useful in urban-scale applications), the
package produces the friction surface on a finer grid following the same
rule. For walking, for which the Malaria Atlas Project assigns the same
speed to roads and to urban land, the walking surface is resampled to
the finer grid. For the fastest mode, cells crossed by an OpenStreetMap
road are assigned the speed of the fastest road class crossing them (by
default, the free-flow speeds of the car profile of the Open Source
Routing Machine [@Luxen2011]), and all other cells the walking speed.
Since these data are downloaded from online services, the package can
cache them, and falls back to alternative sources (retries, mirrors, and
a coarser surface) when a service is unavailable. Travel times are
computed with the accumulated cost algorithm of the *gdistance* package
[@gdistancepackage], on a routing graph built once per problem. A set of
reporting functions and graphical outputs are included in the package.
The package further relies on *malariaAtlas* [@malariaAtlaspackage],
*osmdata*, and *igraph* functions, as well as on *raster*, *terra*, and
*sf* object classes.\

- **Friction layers:** Malaria Atlas friction surfaces: walking or
  fastest mode. These datasets provide 1-km resolution global gridded
  data on the average estimated time to cross a pixel based on the local
  geography and transport infrastructure [@weiss2020global].

- **Point locations of existing facilities:** A point simple feature
  geometry object ($sf$).

- **Point locations for candidate facilities:** Optional, a point simple
  feature geometry object ($sf$).

- **Demand weights:** A raster. It can be, for instance, population
  counts per location (grid cell) - optionally in a weighted form by
  specifying the $weights$ argument to another raster of a function of
  several rasters. This would allow using a risk framework where the
  demand is defined as a risk map $R$ of:
  $R = POP \times HAZARD \times VULNERABILITY$.

The package core functions are the following:

``` {.r language="R"}

traveltime(facilities, bb_area, mode = "walk", res_output = 100,
cache = FALSE)
```

The $traveltime$ function generates a map of the travel time to the
nearest facility based on the input facilities, area of interest, and
travel mode, having the following arguments:

- $facilities$: An sf object with the existing facilities.

- $bb\_area$: An sf polygon with the area of interest.

- $mode$: The mode of transport (walking or fastest).

- $res\_output$: The spatial resolution of the friction raster (and of
  the analysis), in meters.

- $cache$: Whether to cache the downloaded data for later use.

``` {.r language="R"}

allocation(demand, bb_area, facilities, traveltime = NULL,
weights = NULL, objectiveminutes = 15, objectiveshare = 0.99,
heur = "kd", n_fac = Inf)
```

The $allocation$ function allocates facilities in a continuous location
problem, based on the demand, travel time, and weights for the demand,
and on a target travel time threshold and either a target share of the
demand to be covered or a maximum number of facilities, having the
following arguments:

- $demand$: A raster with the demand for the service (e.g.,
  population).

- $bb\_area$: An sf polygon with the area of interest.

- $facilities$: An sf object with the existing facilities, or $NULL$.

- $traveltime$: The output of the $traveltime$ function, whose friction
  surface is reused. If not provided, the friction surface is computed
  first.

- $weights$: A raster with weights for the demand (e.g., a hazard
  layer).

- $objectiveminutes$: The travel time threshold, in minutes.

- $objectiveshare$: The share of the demand to be covered.

- $heur$: The score used to shortlist promising locations: \"kd\"
  (kernel-smoothed uncovered demand, default) or \"max\" (uncovered
  demand of each cell).

- $n\_fac$: The maximum number of new facilities.

``` {.r language="R"}

allocation_discrete(demand, bb_area, candidate, facilities = NULL,
n_fac = Inf, traveltime = NULL, weights = NULL, objectiveminutes = 15,
objectiveshare = NULL)
```

The $allocation\_discrete$ function solves the discrete location
problem, with the same arguments as $allocation$, plus:

- $candidate$: An sf object with the candidate locations for the new
  facilities.

- $n\_fac$: The maximum number of new facilities.

- $objectiveshare$: If $NULL$ (default), up to $n\_fac$ candidates are
  selected to maximize the covered demand; otherwise, as few candidates
  as possible are selected to reach the target share.

Ancillary functions include $friction()$, $traveltime\_stats()$,
$traveltime\_plot()$, $allocation\_plot()$, $default\_road\_speeds()$,
and $mask\_raster\_to\_polygon()$, and they are documented in the
package website (<https://giacfalk.github.io/locationallocation/>).

# Use case: optimal allocation of public water fountains with consideration of heat hazard and exposure {#use-case-optimal-allocation-of-public-water-fountains-with-consideration-of-heat-hazard-and-exposure .unnumbered}

The world is experiencing climate change impacts (climate impacts are
becoming ever more frequent and severe for both citizens and governments
across a range of dimensions, including socio-economic outcomes, human
health, and environmental systems). Hence, evaluating the public
provisions of infrastructure that can support adaptation to different
climate hazards and impacts at the urban scale has crucial implications
for acting to reduce the adversity and inequity of climate change
impacts. Such knowledge can be used to inform the design and
transformation of urban areas into more climate-resilient, just,
sustainable living systems.\

As a use case, we evaluate accessibility and optimize accessibility
goals to public drinking water fountains in the city of Naples, Italy
with consideration of exposure (population density) and hazard (average
number of days per year with a local Wet-Bulb Globe Temperature \> 25°
C).\

First, we obtain water fountain coordinate location for city from the
Open Street Maps API using the *osmdata* package using the query
*$amenity = drinking\_water$*. We also obtain gridded population data at
a 100m spatial resolution from GHS-POP data product [@Florczyk2019], a
urban microclimate model output for historical Wet-Bulb Globe
Temperature from the UrbClim model [@Lauwaet2024], and the
administrative boundaries of the city of Naples from the Eurostat's LAU
database, as depicted in Figure
[1](fig:maps_naples){reference-type="ref" reference="fig:maps_naples"}.
The following example datasets are fully embedded in the package.

![Map of population density and location of public drinking water
fountains in Naples, Italy.\label{fig:maps_naples}](figures_paper/maps_Napoli.pdf)

Then, we implement the *traveltime* function to calculate a map of
accessibility to public drinking water sources as follows:

``` {.r language="R"}

out_tt <- traveltime(facilities = naples_fountains, bb_area = naples_shape,
mode = "walk", res_output = 100)
```

The function yields a raster output which - for each pixel - shows the
estimated travel time to reach the most accessible facility (nearest in
travel time terms) for the selected travel mode. The resulting layer can
be visualized via:

``` {.r language="R"}

traveltime_plot(traveltime=out_tt,  bb_area=naples_shape, facilities = naples_fountains)
```

![Map of the walking travel time to the nearest public drinking water
fountain in Naples,
Italy.\label{fig:enter-label}](figures_paper/traveltime_map_fountains.png)

We can also produce a summary plot and statistic based on the output of
the $traveltime$ function and a given demand (e.g., population) raster,
as well as a given time threshold parameter:

``` {.r language="R"}

traveltime_stats(traveltime = out_tt, demand = naples_population, breaks=c(5, 10, 15, 30),
objectiveminutes=5)
```

yielding:

        43.46% of coverage within the 5 minutes threshold.

Within 15 minutes, 90.14% of the population can reach a fountain. We
then can proceed and optimize allocation of new water fountains to
cover maximum share of (unweighted) population. Location-allocation
can be either solved discretely or continuously over space, and either
with a facility constraint or with a policy goal for demand (population)
coverage. For instance, if the goals is to optimise allocation of new
water fountains to cover maximum share of heat-risk weighted
population (exposure), we can use:

``` {.r language="R"}

output_allocation <- allocation(demand = naples_population,
traveltime = out_tt, bb_area = naples_shape,
facilities = naples_fountains, weights = NULL, objectiveminutes = 15,
objectiveshare = 0.99)

allocation_plot(output_allocation, bb_area = naples_shape,
facilities = naples_fountains)
```

This yields an output object containing both the coordinate location of
the allocated facilities to meet the accessibility objectives, and the
updated travel time map. In this example, 9 new fountains raise the
share of the population within a 15-minute walk from 90.14% to 99.11%:

![Map of the continuous location-allocation problem solution for a
15-minute walk and a 99% demand coverage objective for the nearest
public drinking water fountain in Naples,
Italy.\label{fig:sol_cont}](figures_paper/allocation_15mins_fountains.png)

If we use demand weights (e.g. maximum temperature), we can use:

``` {.r language="R"}

output_allocation_weighted <- allocation(demand = naples_population,
traveltime = out_tt, bb_area = naples_shape,
facilities = naples_fountains, weights = naples_hot_days,
objectiveminutes = 15, objectiveshare = 0.99)

allocation_plot(output_allocation_weighted, bb_area = naples_shape,
facilities = naples_fountains)
```

where $naples\_hot\_days$ is a raster layer with the number of hot days
per year (resampled to the grid of the demand raster if needed). The
objective now refers to the heat-weighted population, of which 99.16% is
covered with 9 new fountains. We can notice how results change when
using such weighted approach:

![Map of the continuous location-allocation weighted problem solution
for a 15-minute walk, a 99% demand coverage objective, and a demand
weight based on the frequency of hot days for the nearest public
drinking water fountain in Naples,
Italy.\label{fig:sol_cont_weighted}](figures_paper/allocation_15mins_fountains_weighted.png)

Otherwise, if we want to prioritize among a discrete set of pre-defined
potential sites (e.g. sites along the water pipes network), we can use:

``` {.r language="R"}

set.seed(333)

candidates <- st_sample(naples_shape, 30)

output_allocation_discrete <- allocation_discrete(demand = naples_population,
traveltime = out_tt, bb_area = naples_shape,
facilities = naples_fountains, candidate = candidates, n_fac = 10,
weights = NULL, objectiveminutes = 15)

allocation_plot(output_allocation_discrete, bb_area = naples_shape,
facilities = naples_fountains)
```

The resulting map shows the coordinate location of the selected
facilities among the candidate set (subject to the number of facilities
constraint). The 10 selected candidates raise the share of the
population within a 15-minute walk to 94.29%:

![Map of the discrete location-allocation problem solution for a
15-minute walk and up to 10 new public drinking water fountains selected
among 30 candidate locations in Naples,
Italy.\label{fig:sol_disc}](figures_paper/allocation_discrete_fountains.png)

Note that it is also possible to solve location-allocation problems from
scratch, i.e. in the absence of pre-existing facilities:

``` {.r language="R"}

output_allocation_discrete_from_scratch <- allocation_discrete(
demand = naples_population, traveltime = out_tt, bb_area = naples_shape,
facilities = NULL, candidate = candidates, n_fac = 10, weights = NULL,
objectiveminutes = 15)

allocation_plot(output_allocation_discrete_from_scratch,
bb_area = naples_shape)
```

Also in this case, the resulting map shows the coordinate location of
the selected facilities among the candidate set (subject to the number
of facilities constraint). Only the friction surface of $out\_tt$ is
reused, and the coverage is computed from the new facilities alone: 10
facilities cover 56.77% of the population within a 15-minute walk:

![Map of the discrete location-allocation problem solution for a
15-minute walk and up to 10 public drinking water fountains selected
among 30 candidate locations, in the absence of pre-existing facilities
in Naples,
Italy.\label{fig:sol_disc_scratch}](figures_paper/allocation_discrete_fromscratch_fountains.png)

# Discussion and conclusion {#discussion-and-conclusion .unnumbered}

This paper provides an illustration of the theoretical background, the
software and data implementation, and the use case for the
*locationallocation* R package. The suite of functions in the package
are suitable to be applied to geographical location-allocation problems,
such as (but not only) in cities. Example applications in the domain of
urban environmental and climate risk include cooling centers, green
space, emergency services, drinking water, transport, or flood
protection infrastructure. Beyond, other domains of application include
public infrastructure assessment and planning (public services
provision, e.g. transport, social services, healthcare, parks),
logistics and hubs allocation, commercial and strategic decisions.\

Despite the advancements brought by *locationallocation* in its capacity
to bridge the mathematical formulation of the MCLA problem with the
application with geospatial data and libraries in the R scientific
programming language, the package has limitations. For instance
currently, the package does not support facility-level attributes that
can affect the location allocation or local density or size of the
facility to be allocated (e.g. supply constraints such as beds per
hospital or users per facilities), as all facilities are equally
defined. Moreover, the location-allocation problems are solved with greedy and
vertex substitution heuristics, whose solutions are not guaranteed to
coincide with the (possibly non-unique) globally optimal solution,
although in our tests they matched exhaustive or dense-grid reference
solutions. In the continuous problem, the locations evaluated at each
iteration are proposed by a score of the uncovered demand that does not
account for the road network. The identification of a provably optimal
solution would require formulating the problem as a mixed-integer
program and using dedicated solvers, which is computationally intensive
for large study areas. Finally, the friction surfaces at a fine
resolution do not model congestion, public transport, or barriers such
as motorways and railways, and the default road speeds are free-flow
speeds. Future software
work might implement such features and expand the package capabilities.\

# Acknowledgements

The author gratefully acknowledges the openly available data and
algorithm resources from malariaAtlas and OpenStreetMap, without which
the development of this package would not have been possible. The author
is thankful to Ahmed T. Hammad for the previous joint work in
@Falchetta2020 which led to the development of this package. The author
is also grateful to his scientific affiliations CMCC and IIASA for their
continuous support.

# References