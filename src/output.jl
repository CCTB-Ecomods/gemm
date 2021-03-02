# Output functions for GeMM

"""
    printheader(io, sep)

Print a list of property names to the given IO stream. This is a helper function
for `dumpinds`.
"""
function printheader(io::IO = stdout, sep::String = "\t")
    #XXX Transfer to a dynamic system? (As in createworld()?)
    print(io, "time", sep)
    print(io, "patch_no", sep)
    print(io, "xloc", sep)
    print(io, "yloc", sep)
    print(io, "temp", sep)
    print(io, "capacity", sep)
    setting("nniches") > 1 && print(io, "prec", sep)
    setting("nniches") > 2 && print(io, "nicheb", sep)
    print(io, "island", sep)
    print(io, "isolation", sep)
    print(io, "invasible", sep)
    print(io, "initpop", sep)
    print(io, "id", sep)
    print(io, "lineage", sep)
    print(io, "new", sep)
    print(io, "tempadaptation", sep)
    print(io, "precadaptation", sep)
    print(io, "size", sep)
    print(io, "lnkgunits", sep)
    print(io, "ngenes", sep)
    for key in setting("traitnames")
        print(io, key, sep)
    end
    println(io)
end

"""
    dumpinds(world, io, sep)

Output all data of individuals in `world` as table to `io`. Columns are separated by `sep`.
WARNING: this produces *very* large files!
"""
function dumpinds(world::Array{Patch, 1}, timestep::Int, io::IO = stdout, sep::String = "\t")
    timestep == 0 && printheader(io, sep)
    onlyisland = setting("static") && timestep > 1
    for patch in world
        #XXX Sometimes, this only dumps three or four individuals, with a population of >10⁴!
        # (Should be fixed)
        (onlyisland && !patch.isisland) && continue
        if !patch.isisland && setting("static")
            community = patch.seedbank
        else
            community = patch.community
        end
        for ind in community
            print(io, timestep, sep)
            print(io, patch.id, sep)
            print(io, patch.location[1], sep)
            print(io, patch.location[2], sep)
            print(io, patch.temp, sep)
            print(io, patch.capacity, sep)
            setting("nniches") > 1 && print(io, patch.prec, sep)
            setting("nniches") > 2 && print(io, patch.nicheb, sep)
            patch.isisland ? print(io, 1, sep) : print(io, 0, sep)
            patch.isolated ? print(io, 1, sep) : print(io, 0, sep)
            patch.invasible ? print(io, 1, sep) : print(io, 0, sep)
            patch.initpop ? print(io, 1, sep) : print(io, 0, sep)
            print(io, ind.id, sep)
            print(io, ind.lineage, sep)
            ind.marked ? print(io, 1, sep) : print(io, 0, sep)
            print(io, ind.tempadaptation, sep)
            print(io, ind.precadaptation, sep)
            print(io, ind.size, sep)
            print(io, length(ind.genome), sep)
            print(io, sum(map(x -> length(x.genes), ind.genome)), sep)
            for key in setting("traitnames")
                try
                    print(io, ind.traits[key], sep)
                catch
                    print(io, "NA", sep)
                end
            end
            println(io)
        end
    end
end

"""
    makefasta(world, io, onlyisland, sep)

Record the genome of every individual currently alive to the given IO stream.
(High-detail data recording function.) WARNING: this produces *very* large files!
"""
function makefasta(world::Array{Patch, 1}, io::IO = stdout, onlyisland::Bool = false, sep::String = "_")
    for patch in world
        (onlyisland && !patch.isisland) && continue
        if !patch.isisland && setting("static")
            community = patch.seedbank
        else
            community = patch.community
        end
        lineage = ""
        for ind in community
            (!patch.isisland && setting("static") && ind.lineage == lineage) && continue # only one individual per species on mainland
            chrmno = 0
            for chrm in ind.genome
                chrmno += 1
                geneno = 0
                for gene in chrm.genes
                    geneno += 1
                    traits = ""
                    if length(gene.codes) == 0
                        traits *= ","
                    else
                        for trait in gene.codes
                            traits *= string(setting("traitnames")[trait.nameindex]) * ":" * string(trait.value) * ","
                        end
                    end
                    header = ">" * ind.lineage * sep * string(ind.id) * sep * string(chrmno) * sep * string(geneno) * sep * traits
                    if (setting("fasta") == "compat" && occursin("compat", header)) || setting("fasta") != "compat"
                        println(io, header)
                        if setting("compressgenes")
                            println(io, num2seq(gene.sequence))
                        else
                            println(io, gene.sequence)
                        end
                    end
                end
            end
            lineage = ind.lineage
        end
    end
end

"""
    setupdatadir(dir)

Creates the output directory and copies relevant files into it.
"""
function setupdatadir()
    if isdir(setting("dest"))
        #XXX a more useful solution might be to rename "dest" to avoid conflict
        simlog(string(setting("dest"))*" exists. Aborting to avoid overwriting files.", 'e')
    else
        mkpath(setting("dest"))
    end
    simlog("Setting up output directory "*string(setting("dest")))
    writesettings()
    if in("maps", settingkeys())
        for m in setting("maps")
            isempty(m) && continue
            !(isfile(m)) && simlog("Map file "*string(m)*" doesn't exist!", 'e')
            cp(m, joinpath(setting("dest"), basename(m)), force = true)
        end
    end
end

"""
    writesettings()

Record the settings actually used for a simulation run (cf. `getsettings`).
Creates a config file that can be used for future replicate runs.
Also records a time stamp and the current git commit.
"""
function writesettings()
    if isempty(basename(setting("config")))
        settingspath = "settings.conf"
    else
        settingspath = basename(setting("config"))
    end
    open(joinpath(setting("dest"), settingspath), "w") do f
        println(f, "#\n# --- GeMM configuration parameters ---")
        println(f, "# This file was generated automatically.")
        println(f, "# Simulation run on "*string(Dates.format(Dates.now(), "d u Y HH:MM:SS")))
        println(f, "# "*string(split(read(pipeline(`git log`, `head -1`), String), "\n")[1])*"\n")
        for k in settingkeys()
            value = setting(k)
            if isa(value, String)
                value = "\"" * value * "\""
            elseif isa(value, Array)
                vstr = "\""
                        for x in value
                            vstr *= string(x) * ","
                        end
                        value = vstr[1:end-1] * "\""
            end
            println(f, string(k), " ", string(value))
        end
    end
end

"""
    writedata(world, timestep)

Writes simulation output from `world` to separate table and fasta files. (Which
data is recorded depends on the settings.) `timestep` and `setting` information
is used for file name creation.
"""
function writedata(world::Array{Patch,1}, timestep::Int)
    if setting("raw")
        filename = "inds_s" * string(setting("seed"))
        filename = joinpath(setting("dest"), filename)
        filename = filename * ".tsv"
        simlog("Writing data \""*string(filename)*"\"")
        open(filename, "a") do file
            dumpinds(world, timestep, file)
        end
    end
    if setting("stats")
        filename = "pops_s" * string(setting("seed"))
        filename = joinpath(setting("dest"), filename)
        filename = filename * ".tsv"
        simlog("Writing stats to \""*string(filename)*"\"")
        open(filename, "a") do file
            printpopstats(file, world, timestep)
        end
    end
    if setting("fasta") != "off"
        filename = "seqs_s" * string(setting("seed"))
        filename = joinpath(setting("dest"), filename)
        filename = filename * ".fa"
        simlog("Writing fasta \""*string(filename)*"\"")
        open(filename, "a") do file
            makefasta(world, file, setting("static") && timestep > 1)
        end
    end
end

"""
    recordstatistics(w)

Write out world properties to the log file for later analysis.
"""
function recordstatistics(world::Array{Patch,1})
    if !isfile(joinpath(setting("dest"), "diversity.log"))
        simlog("population,freespace,lineages,alpha,beta,gamma", 'i', "diversity.log", true)
    end
    popsize = sum(x -> length(x.community), world)
    lineages = unique(reduce(vcat, map(p -> map(x -> x.lineage, p.community), world)))
    div = round.(diversity(world), digits = 3)
    space = freespace(world)
    simlog("Metacommunity size: "*string(popsize)*", lineages: "*string(length(lineages))) # to stdout
    simlog(string(popsize)*","*string(space)*","*string(length(lineages))*","*
           string(div[1])*","*string(div[2])*","*string(div[3]),
           'i', "diversity.log", true)
end

"""
    recordlineages(w)

Save the abundance of each lineage per patch. (Low-detail data recording function.)
"""
function recordlineages(world::Array{Patch,1}, timestep::Int)
    #XXX despite being low-detail, calling this frequently still means a lot of I/O
    if !isfile(joinpath(setting("dest"), "lineages.log"))
        simlog("t,X,Y,lineage,abundance,temp,prec", 'i', "lineages.log", true)
    end
    datastring = ""
    for p in world
        for l in unique(map(x -> x.lineage, p.community))
            datastring *= string(timestep)*","*string(p.location[1])*","*string(p.location[2])*
            ","*string(l)*","*string(length(findall(x -> x.lineage == l, p.community)))*","*
            string(p.temp)*","*string(p.prec)*"\n"
        end
    end
    simlog(datastring, 'i', "lineages.log", true)
end

"""
    printpopheader(io)

Print a list of property names to the given IO stream. This is a helper function
for `printpopstats`.
"""
function printpopheader(io::IO)
    print(io, "time", "\tx", "\ty", "\ttemp", "\tprec", "\tcapacity", "\tisisland",
          "\tlineage", "\tjuveniles", "\tadults", "\ttempadaptationmean",
          "\tprecadaptationmean", "\theterozygosity")
    #XXX this probably should't be hardcoded, use `setting("traitnames")` instead
    traitnames =  ["compat", "compatsd", "dispmean", "dispmeansd", "dispshape", "dispshapesd",
                   "ngenes", "nlnkgunits", "precopt", "precoptsd", "prectol", "prectolsd",
                   "repsize", "repsizesd", "seqsimilarity", "seqsimilaritysd", "seedsize", "seedsizesd",
                   "tempopt", "tempoptsd", "temptol", "temptolsd"]
    for traitname in traitnames
        print(io, "\t", traitname, "mean")
        print(io, "\t", traitname, "std")
    end
    print(io, "\treplicate", "\tconf")
    println(io)
end

"""
    printpopstats(io, world, timestep)

Record statistical information (maximum, minimum, median, standard deviation)
for a range of individual properties, as seen over the whole world population.
(Medium-detail data recording function.)
"""
function printpopstats(io::IO, world::Array{Patch, 1}, timestep::Integer)
    timestep == 0 && printpopheader(io)
    #XXX this probably should't be hardcoded, use `setting("traitnames")` instead
    traitnames =  ["compat", "compatsd", "dispmean", "dispmeansd", "dispshape", "dispshapesd",
                   "ngenes", "nlnkgunits", "precopt", "precoptsd", "prectol", "prectolsd",
                   "repsize", "repsizesd", "seqsimilarity", "seqsimilaritysd", "seedsize", "seedsizesd",
                   "tempopt", "tempoptsd", "temptol", "temptolsd"]
    for patch in world
        lineages = unique(map(i -> i.lineage, patch.community))
        for lineage in lineages
            print(io, timestep, "\t", patch.location[1], "\t", patch.location[2],
                  "\t", patch.temp, "\t", patch.prec, "\t", patch.capacity, "\t", patch.isisland)
            popidxs = findall(i -> i.lineage == lineage, patch.community)
            population = patch.community[popidxs]
            adultidxs = findall(i -> i.size >= i.traits["repsize"], patch.community[popidxs])
            print(io, "\t", population[1].lineage, "\t", length(popidxs) - length(adultidxs), "\t", length(adultidxs),
                  "\t", mean(skipmissing(map(i -> i.tempadaptation, population))),
                  "\t", mean(skipmissing(map(i -> i.precadaptation, population))),
                  "\t", heterozygosity(population))
            for traitname in traitnames
                poptrait = map(i -> i.traits[traitname], population)
                print(io, "\t", mean(skipmissing(poptrait)))
                print(io, "\t", std(skipmissing(poptrait))) # CAVEAT: this returns NaN if only one individual
            end
            print(io, "\t", setting("seed"), "\t", setting("config"))
            println(io)
        end
    end
end

"""
    simlog(msg, category, logfile, onlylog)

Write a log message to STDOUT/STDERR and the specified logfile
(if logging is turned on in the settings).

Categories: `d` (debug), `i` (information, default), `w` (warn), `e` (error)

If `logfile` is the empty string (default: "simulation.log"), the message will
only be printed to the screen. If `onlylog` is true (default: false), the
message is not printed to screen but only to the log.
"""
function simlog(msg::String, category::Char='i', logfile::String="simulation.log", onlylog::Bool=false)
    #TODO Julia now has inbuilt logging facilities: https://docs.julialang.org/en/v1/stdlib/Logging/
    # This function ought to be rewritten to make use of these (especially warning and error macros)
    (isa(category, String) && length(category) == 1) && (category = category[1])
    function logprint(msg::String, tostderr=false)
        if tostderr || !(setting("quiet") || onlylog)
            tostderr ? iostr = stderr : iostr = stdout
            println(iostr, msg)
        end
        if setting("logging")
            #XXX always opening new connections is expensive -> should we buffer the output?
            open(joinpath(setting("dest"), logfile), "a") do f
                println(f, msg)
            end
        end
    end
    if category == 'i'
        logprint(msg)
    elseif category == 'd'
        setting("debug") && logprint("DEBUG: "*string(msg))
    elseif category == 'w'
        logprint("WARNING: "*string(msg), true)
    elseif category == 'e'
        logprint("ERROR: "*string(msg), true)
        exit(1)
    else
        simlog("Invalid log category "*string(category)*".", 'w')
    end
end

"""
    @simlog(message, category, args)

A wrapper macro around the function `simlog()`. Use this for debug statements, as it
prevents evaluation of the message string if debug mode is not on (a slight performance gain).
"""
macro simlog(msg::Union{String,Expr}, category::Char='i', args...)
    return :(($category == 'd') && setting("debug") && simlog(:($$msg), $category, $(args...)))
end

#XXX perhaps the utility functions below should go elsewhere?

"""
    diversity(w)

Calculate (average) alpha, beta and gamma diversity of the world.
Returns a tuple with the three values (a,b,g).
cf. Veech et al. 2002
"""
function diversity(world::Array{Patch,1})
    # calculate diversity with the Shannon-Wiener index
    function shannon(index::Dict{String,Int})
        isempty(index) && return 0
        total = sum(x -> index[x], keys(index))
        -1 * sum(s -> (index[s]/total)*log(index[s]/total), keys(index))
    end
    alphas = Float64[]
    globalindex = Dict{String, Int}()
    for p in world
        localindex = Dict{String, Int}()
        for s in unique(map(x -> x.lineage, p.community))
            localindex[s] = length(findall(x -> x.lineage == s, p.community))
        end
        merge!(+, globalindex, localindex)
        append!(alphas, shannon(localindex))
    end
    alpha = mean(alphas)
    gamma = shannon(globalindex)
    beta = gamma - alpha
    (alpha, beta, gamma)
end

"""
    heterozygosity(population)

Calculate the percentage of extraspecific chromosomes in a population's gene pool.
"""
function heterozygosity(population::Array{Individual,1})
    (!(setting("heterozygosity") || isempty(population))) && return 0
    lineage = population[1].lineage
    chromosomes = 0
    extraspecifics = 0
    for ind in population
        for c in ind.genome
            chromosomes += 1
            (c.lineage != lineage) && (extraspecifics += 1)
        end
    end
    return (extraspecifics/chromosomes) * 100
end

"""
    freespace(world)

Calculate the average amount of free space on each patch.
"""
function freespace(world::Array{Patch,1})
    space = 0
    for p in world
        if length(p.community) != 0
            space += p.capacity - sum(x -> x.size, p.community)
        else
            space += p.capacity
        end
    end
    round((space/length(world))/1e6, digits = 3)
end
