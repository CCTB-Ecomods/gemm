#!/usr/bin/env julia
## contains all custom types necessary for eco-evo-env speciation island model

module GeneInds

using Distributions


## Types:

type Gene
    sequence::String # contains gene base code
    codes::String # function of the gene
    value::Float64 # numerical effect of function
end

type Chromosome
    genes::Array{Gene,1} # 1D array of genes
    origin::Bool # parental origin of chromosome (paternal/maternal)
end

type Individual
    genome::Array{Chromosome,1} # genome = 2D array of chromosomes (>=1 sets)
    gamete::Array{Chromosome,1} # gamete = 2D array of chromosomes (>=0 sets)
    fitness::Float64 # reproduction scaling factor representing life history
    stage::String # demographic stage of individual
    isnew::Bool # indicator whether individual is new to a patch
    noff::Float64 # mean number of offspring GENE
    pgerm::Float64 # probability of germination GENE
    pmat::Float64 # probability of maturation GENE
    pdie::Float64 # probability of dying GENE
    dead::Bool # is individual dead?
end

type Patch
    community::Array{Individual,1} # holds the population (1D) of prob not: present species (2nd D)
    altitude::Float64 # altitude: corresponds to T
    nichea::Float64 # additional niches,
    nicheb::Float64 # e.g. precipitation
end

type Island
    patches::Array{Patch,1}
end


## methods:

function mutate!(gene::Gene, temp::Float64, p::Float64)
    for i in eachindex(gene.sequence)
        (rand() < temp*p) && (gene.sequence[i]=rand(collect("acgt"),1)[1]) # for now, but consider indels!
    end
end

function recombinate!(chromosome::Chromosome)
end

## following: act @ population/community level?

function evalenv!(patch::Patch,ind::Individual)
end

function germinate!(ind::Individual)
    ind.dead && return
    ind.isnew = false
    if (ind.stage == "seed") && (rand() <= ind.pgerm) 
        ind.stage = "juvenile"
    end
    ## decide activation/inactivation of alleles here!
    (rand() <= ind.pdie) && (ind.dead = true)
end

function mature!(ind::Individual)
    ## consider alleles for survival etc.!
    ind.dead && return
    if (ind.stage == "juvenile") && (rand() <= ind.pmat) 
        ind.stage = "adult"
    end
end

function reproduce(ind::Individual)
    ## genetic "fitness"!
    ind.dead && return []
    offspring = []
    if ind.stage == "adult"
        noff = rand(Poisson(ind.noff))
        for i in 1:noff
            child = deepcopy(ind)
            child.isnew = true
            child.stage = "seed"
            push!(offspring, child)
        end
    end
    offspring
end

function disperse(ind::Individual)
    ## consider genetics + life history!
    ind.dead && return
    if ind.isnew
        ind.isnew = false
        return
    else
        ind.isnew = true
    end
end

end
