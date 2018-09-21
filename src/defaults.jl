# Return the default settings. All parameters must be registered here.
function defaultSettings()
    Dict("avgnoloci" => 1, # average number of loci/copies per gene
         "biggenelength" => 200,
         "burn-in" => 1000, # timesteps before invasion starts
         "cellsize" => 20e6, # maximum biomass per hectare in gramm (based on Clark et al. 2001)
         "config" => "simulation.conf", # configuration file name
         "debug" => false, # write out debug statements
         "dest" => string(Dates.today()), # output folder name
         "disturbance" => 0, # percentage of individuals killed per update per cell
         "fasta" => false, # record fasta data?
         "fixtol" => true,
         "global-species-pool" => 0, # size of the global species pool (invasion source)
         "indsize" => "seed", # initialize organisms as seed, adult or mixed
         "lineages" => false, # record lineage and diversity data?
         "linkage" => "random", # gene linkage type (random/full/none)
         "logging" => false, # write output to logfile
         "maps" => "", # comma-separated list of map files
         "maxrepsize" => 14, # maximal repsize in grams calculated as exp(maxrepsize) -> 1.2 t
         "maxseedsize" => 10, # maximal seedsize in grams calculated as exp(maxseedsize) -> 22 kg
         "minrepsize" => 3, # minimal repsize in grams calculated as exp(minrepsize) -> 20 g
         "minseedsize" => -2, # minimal seedsize in grams calculated as exp(minseedsize) -> 0.14 g
         "mutate" => true, # mutations occur
         "nniches" => 2, # number of environmental niches (max. 3)
         "outfreq" => 100, # output frequency
         "phylo" => false, # record phylogeny?
         "popsize" => "metabolic", # initialisation algorithm: metabolic/bodysize/minimal/single
         "propagule-pressure" => 0, # number of non-native individuals introduced per invasion event
         "quiet" => false, # don't write output to screen
         "seed" => 0, # for the RNG, seed = 0 -> random seed
         "smallgenelength" => 20,
         "static" => true, # mainland sites don't undergo eco-evolutionary processes
         "tolerance" => 0.8, # sequence similarity threshold for reproduction
         "traitnames" => ["compat",
                          "dispmean",
                          "dispshape",
                          "mutprob",
                          "precopt",
                          "prectol",
                          "repsize",
                          "reptol",
                          "seedsize",
                          "tempopt",
                          "temptol"], # minimal required traitnames
         "usebiggenes" => true
         ) 
end

# Return a list of traits with randomised default values
function defaultΤraits(settings::Dict{String, Any}) #TODO: this is all very ugly. (case/switch w/ v. 2.0+?)
    traitnames = settings["traitnames"]
    traits = Trait[]
    # exponential distributions of body sizes:
    seedoffset = settings["maxseedsize"] - settings["minseedsize"]
    repoffset = settings["maxrepsize"] - settings["minrepsize"]
    seedsize = exp(settings["minseedsize"] + seedoffset * rand()) 
    repsize = exp(settings["minrepsize"] + repoffset * rand())
    while repsize <= seedsize
        repsize = exp(settings["minrepsize"] + repoffset * rand())
    end
    for idx in eachindex(traitnames)
        if occursin("rate", traitnames[idx])
            push!(traits, Trait(idx, rand() * 100))
        elseif occursin("dispshape", traitnames[idx])
            push!(traits, Trait(idx, rand() * maxdispmean))
        elseif occursin("tempopt", traitnames[idx])
            push!(traits, Trait(idx, rand() * 25 + 288)) # range 15-40°C
        elseif occursin("temptol", traitnames[idx])
            push!(traits, Trait(idx, (rand() + 0.39) * 5))
        elseif occursin("mut", traitnames[idx])
            mutationrate == 0 ? push!(traits, Trait(idx, rand())) : push!(traits, Trait(idx, mutationrate))
        elseif occursin("repsize", traitnames[idx])
            push!(traits, Trait(idx, repsize))
        elseif occursin("seedsize", traitnames[idx])
            push!(traits, Trait(idx, seedsize))
        elseif occursin("precopt", traitnames[idx])
            push!(traits, Trait(idx, rand() * 10))
        elseif occursin("prectol", traitnames[idx])
            push!(traits, Trait(idx, rand() + 0.39))
        elseif occursin("reptol", traitnames[idx])
            push!(traits, Trait(idx, settings["tolerance"]))
        else
            push!(traits, Trait(idx, rand()))
        end
    end
    traits
end

