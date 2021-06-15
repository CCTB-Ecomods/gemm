"""
    defaultSettings()

Defines the list of configuration variables and returns their default values
in a Dict.
"""
function defaultSettings()
    # Return the default settings. All parameters must be registered here.
    Dict(
        "biggenelength" => 200, # length of the compatibility gene's sequence (if `usebiggenes`)
        "bodytemp"=> 312.0, # body temperature in K for homeothermic species
        "borders" => "absorbing", # border behaviour: absorbing/reflecting/mainland
        #"bufferoutput" => false, # use output buffering (faster execution, more RAM usage) #TODO
        "burn-in" => 1000, # timesteps before invasion starts
        "capgrowth" => false, # strictly limit individuals' size to `repsize`
        "cellsize" => 20e6, # maximum biomass per hectare in gramm (based on Clark et al. 2001)
        "compressgenes" => true, # save gene sequences as integers to reduce memory usage
        "config" => "", # configuration file name
        "debug" => false, # write out debug statements
        "degpleiotropy" => 0.1, # How frequent are pleitropy and polygenic inheritance? 0 <= degpleiotropy < 1
        "dest" => string(Dates.today()), # output folder name
        "dispmean" => 1.0, # maximum value of randomly drawn mean dispersal distance in cells
        "dispshape" => 1.0, # maximum value of randomly drawn shape parameter for dispersal kernel. determines tail fatness/long distance dispersal
        "disturbance" => 0, # percentage of individuals killed per update per cell
        "fasta" => "off", # record fasta data? "off", "compat", "all" (high detail output)
        "fastaoutfreq" => 10, #frequency with which to write fasta data
        "fertility" => exp(28.0), # global base reproduction rate 23.8 from Brown et al. 2004, alternatively 25.0, default 30.0
        "fixtol" => true, # fix mating tolerance globally to `tolerance`
        "global-species-pool" => 0, # size of the global species pool (invasion source)
        "globalmating" => false, # global pollen "dispersal"
        "growthrate" => exp(25.2), # global base growth/biomass production from Brown et al. 2004
        "heterozygosity" => false, # keep track of heterozygosity when studying hybridisation
        "indsize" => "seed", # initialize organisms as seed, adult or mixed
        "isolationweight" => 3.0, # additional distance to be crossed when dispersing from or to isolated patches
        "lineages" => false, # record lineage and diversity data (low detail output)
        "linkage" => "random", # gene linkage type (random/full/none)
        "logging" => false, # write output to logfile
        "maps" => "", # comma-separated list of map files
        "maxbreadth" => 5.0, # maximum niche breadth
        "maxloci" => 1, # maximum number of loci/copies per gene
        "maxprec" => 10.0, # max optimum precipitation
        "maxrepsize" => 14.0, # maximal repsize in grams calculated as exp(maxrepsize) -> 1.2 t
        "maxseedsize" => 10.0, # maximal seedsize in grams calculated as exp(maxseedsize) -> 22 kg
        "maxtemp" => 313.0, # max optimum temp in K
        "mortalitytype" => "metabolic", # metabolic/habitat/global
        "minprec" => 0.0, # min optimum precipitation
        "minrepsize" => 3.0, # minimal repsize in grams calculated as exp(minrepsize) -> 20 g
        "minseedsize" => -2.0, # minimal seedsize in grams calculated as exp(minseedsize) -> 0.14 g
        "mintemp" => 273.0, # min optimum temp in K
        "mode" => "default", # experiment type ("default", "invasion", or "zosterops")
        "mortality" => exp(22), # global base mortality from Brown et al. 2004 is 26.3, but competition and dispersal introduce add. mort.
        "mutate" => true, # mutations occur
        "mutationrate" => 3.6e10, # one mutation per generation/individual, corrected for metabolic function
        "nniches" => 2, # number of environmental niches (max. 2) #XXX currently, only 2 is sensible
        "outfreq" => 10, # output frequency
        "overfill" => 1.0, # how much to overfill grid cells beyond their capacity
        "phylconstr" => 0.1, # phylogenetic constraint during mutation and inter-loci variation. scales trait value as sd.
        "popsize" => "metabolic", # initialisation algorithm: metabolic/bodysize/minimal/single
        "precrange" => 0, # max optimum precipitation - deprecated! (use `maxprec`)
        "propagule-pressure" => 0, # number of non-native individuals introduced per invasion event
        "quiet" => false, # don't write output to screen
        "raw" => true, # record raw data
        "sdprec" => 0.0, # SD of precipitation change per time step
        "sdtemp" => 0.0, # SD of temperature change per time step
        "seed" => 0, # for the RNG, seed = 0 -> random seed
        "smallgenelength" => 20, # standard gene sequence length (max. 21)
        "speciation" => "neutral", # allow lineage differentiation? off/neutral/ecological
        "species" => Dict{String,Any}[], # define trait values for each Zosterops species
        "static" => false, # whether mainland sites undergo eco-evolutionary processes (implies "mainland" borders)
        "stats" => true, # record population statistics (medium detail output)
        "tolerance" => 0.8, # sequence similarity threshold for reproduction if `fixtol` == true
        # minimal required traitnames
        "traitnames" => ["compat", # place-holder for the neutral ("compatibility") gene
                         "dispmean", # mean dispersal distance
                         "dispshape", # dispersal shape parameter
                         "numpollen", # number of offspring
                         "precopt", # precipitation/resource optimum
                         "prectol", # precipitation/resource tolerance
                         "repsize", # reproductive size
                         "seqsimilarity", # required genetic sequence similarity for mating
                         "selfing", # probability of self-fertilisation
                         "seedsize", # seed size
                         "tempopt", # temperature optimum
                         "temptol"], # temperature tolerance
        "usebiggenes" => true, # use a longer sequence for the compatibility gene
    )
end
