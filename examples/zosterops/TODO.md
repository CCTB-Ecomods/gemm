# ZOSTEROPS TODO

## General

- [ ] read species & habitat descriptions of *Zosterops* & Taita Hills

- [ ] read up on current literature about evolutionary rescue, introgressive hybridization

- [X] prepare F2 presentation on "Adapting a plant community model to bird populations"

- [X] prepare Ecomods presentation on the design of GeMM

## GeMM adaptation

- [X] introduce `modes` to differentiate between experiment types

- [X] convert `precipitation` niche to `AGC` (above-ground carbon) (isn't that simply a relabelling?)

- [X] setup config file to enable testing

- [X] find a suitable temperature value

- [X] change species initialisation process to read predefined species

- [X] initialise two species
		- highland species *Z. silvanus* (Taita White-eye, a.k.a. subspecies of *Z. poliogaster*)
		- lowland species *Z. jubaensis* (former subspecies of *Z. abyssinicus*)

- [X] introduce sex (birds are not hermaphrodites)

- [X] write an alternate findmate() function
		-> breeding pairs stay faithful for life
		-> occupy & stay in a territory

- [X] make sure growth is capped at `repsize`

- [X] move species properties to settings

- [X] fix seed initialisation bug

- [X] add a StringGene class and `compressgenes` setting

- [X] make sure `map_creator.R` works with Petri's data

- [ ] performance issue (https://docs.julialang.org/en/v1/manual/performance-tips/):
  - [X] profile RAM/CPU trade-off with `compressgenes`
  - [X] circumvent `push!()` calls, preallocate memory instead - doesn't work?
  - [X] use immutable structs - doesn't work either?
  - [X] avoid intermediate allocations when compressing gene sequences
  - [X] avoid string interpolation in output
  - [ ] avoid `deepcopy()`?
  - [X] write a coordinate lookup function to speed up `zdisperse!()`
  - [X] further optimise `zdisperse()` if possible
  - [X] further optimise meiosis
  - [X] don't check viability of all individuals every update
  - [X] optimise `zdisperse()` further still if possible
  - [X] @simlog macro
  - [ ] don't simulate unnecessary gene sequences
  - [ ] buffer more output for better I/O performance (`open()` is expensive)
  - [X] replace `gettraitdict()` with `trait()`? - doesn't work
  - [X] do another profile after finishing Zosterops features
  - [X] parallelise...
  - [X] add `neighbours` array to patches
  - [ ] speed up initialisation
  - [ ] replace Trait struct with Pair
  - [X] further optimise `gettraitdict()`

- [X] turn off mutation except at initialisation

- [X] make `settings` global

- [X] rewrite dispersal function as discussed on 19/01/21

- [X] implement lineage tagging for chromosomes

- [X] juveniles are "born with" adult size

- [X] hybridisation: only if no conspecific partner available

- [X] hybridisation: assign offspring to lineage based on phenotypical similarity

- [X] allow for ecological/neutral speciation in `ziscompatible()`

- [X] throw an error if input files don't exist

- [X] basicparser() should concatenate lines ending with a \

- [X] rethink species trait definition in config

- [X] concatenate functional genes when calculating compatibility with ecological speciation

- [X] disable `selfing` gene for Zosterops studies (how about `seedsize`?)

- [X] test dispersal and reproduction functions
		- [X] BUG: breeding pairs formed after dispersal don't mate (problem: excessive mortality)
		- [X] BUG: dispshape sometimes not greater zero (required for logistic distribution)
		- [X] make sure hybridisation works as intended
		- [X] error when linkage != "none"?
		- [ ] lots of "seed/rep" warnings
		- [X] massively faulty genomes

- [X] decrease world size for experiments? (currently ~10^5 patches)

- [X] backport dispersal code changes from `globalmating`

- [X] backport `minprec` setting from `globalmating`

- [X] measure & record population heterozygosity

- [X] automate experimental setup for hybridisation and habitat fragmentation studies

- [ ] prepare map series for habitat scenarios (cf. Githiru et al. 2011):
		- [ ] converted exotic plantations
		- [ ] random homestead tree planting
		- [ ] reduced montane forest patches

- [ ] measure & record:
		- degree of heterozygosity
		- genetic diversity
		- population sizes

- [X] test parameterisation
		- [X] adjust body sizes and dispersal distances
		- [X] temperature opt/tol must allow sufficient survival rates

- [ ] write data analysis script

- [ ] update documentation

## Notes

- restrict mutations of max & min sizes?
  -> either in `mutate!` or in `checkviability!`

- what determines brood density in lowland species? forest cover?

- dispersal distance:
  - "Based on 339 retraps, the max dispersal distance for Z. silvanus is 1.84 km. 
	This is certainly an underestimation of the max natal dispersal distance 
	because we have never ringed pulli in the nest for this species."
  - "For adults, the mean dispersal distance of females is 0.38 km and for 
	males is 0.21 km."
