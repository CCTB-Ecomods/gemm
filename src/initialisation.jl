# initialisation functions for GeMM

"""
    createpop(cellsize)

Create a new, random individual and replicates it a certain number of times
(depending on metabolic variables) to create a new population of organisms.
Returns an array of individuals.
"""
function createpop(cellsize::Float64)
    # start with an archetypical individual
    archetype = createind(true)
    population = [archetype]
    # calculate the population size
    popsize = 0
    if occursin("metabolic", setting("popsize")) || occursin("single", setting("popsize"))
        # population size determined by adult size
        popsize = round(setting("fertility") * archetype.traits["repsize"] ^ (-1 / 4) *
                        exp(-act / (boltz * 298.0)))
    elseif occursin("bodysize", setting("popsize"))
        # population size up to 25% of the maximum possible in this cell
        quarterpopsize = Integer(ceil(cellsize / archetype.traits["repsize"]) / 4)
        popsize = rand(1:quarterpopsize) + 1
    elseif occursin("minimal", setting("popsize")) || popsize == 0
        popsize = 2 #Takes two to tangle ;-)
    else
        simlog("Invalid value for `popsize`: $(setting("popsize"))", 'e')
    end
    # clone & mutate the archetype N times
    locivar = rand()
    for i in 2:popsize
        #TODO avoid `deepcopy` here
        ind = deepcopy(archetype) # XXX this is potentially very slow!
        ind.id = rand(UInt64)
        varyalleles!(ind.genome, locivar)
        ind.traits = gettraitdict(ind.genome, setting("traitnames"))
        if !(setting("indsize") == "adult" || setting("indsize") == "seed")
            #XXX sizes uniformally distributed?
            ind.size = ind.traits["seedsize"] + rand() * (ind.traits["repsize"] - ind.traits["seedsize"])
        end
        push!(population, ind)
    end
    population
end

"""
    createind(marked=false)

Create an individual organism of a new species with a random genome.
"""
function createind(marked::Bool = false)
    id = rand(UInt64)
    lineage = randstring(6)
    ngenes = rand(1:setting("maxloci")) * length(setting("traitnames"))
    setting("degpleiotropy") == 0 && (ngenes = length(setting("traitnames")))
    ngenes < 1 && (simlog("0 genes would be created", 'e')) #shouldn't happen
    traits = createtraits()
    genes = creategenes(ngenes, traits)
    if setting("linkage") == "none"
        nchrms = length(genes)
    elseif setting("linkage") == "full"
        nchrms = 1
    else
        linkage = rand(1:length(genes))
        nchrms = Integer(round(ngenes/linkage))
    end
    chromosomes = createchrms(nchrms, genes, lineage)
    varyalleles!(chromosomes, rand())
    traitdict = gettraitdict(chromosomes, setting("traitnames"))
    if setting("indsize") == "adult"
        indsize = traitdict["repsize"]
    elseif setting("indsize") == "seed"
        indsize = traitdict["seedsize"]
    else
        indsize = traitdict["seedsize"] + rand() * (traitdict["repsize"] - traitdict["seedsize"])
    end
    Individual(lineage, chromosomes, traitdict, marked, 1.0, 1.0, indsize, hermaphrodite, 0, id)
end

"""
    genesis(cellsize)

Create a new community, composed of random new species populations, for a patch.
Returns an array of individuals.
"""
function genesis(cellsize::Float64)
    community = Individual[]
    totalmass = 0.0
    while true
        population = createpop(cellsize)
        popsize = length(population)
        # Check the cell capacity
        popmass = sum(map(x -> x.size, population))
        if totalmass + popmass > cellsize * setting("overfill")
            # stop loop if cell is full
            if totalmass >= cellsize * 0.9 || occursin("single", setting("popsize"))
                #make sure the cell is full enough
                @simlog("Cell is now $(round((totalmass/cellsize)*100))% full.", 'd')
                break
            else
                continue
            end
        end
        totalmass += popmass
        append!(community, population)
        occursin("single", setting("popsize")) && break
    end
    @simlog("Patch initialized with $(length(community)) individuals.", 'd')
    community
end

"""
    createpatch(patchentry)

Create a new patch and set its parameters by parsing one line of the map file.
"""
function createpatch(patchentry::Array{String,1})
    size(patchentry,1) < 3 && simlog("please check your map file for incomplete or faulty entries. \n
Each line must contain patch information with at least \n
\t - a unique integer ID, \n
\t - an integer x coordinate, \n
\t - an integer y coordinate, \n
separated by a whitespace character (<ID> <x> <y>).", 'e')
    # create the basic patch
    id = parse(Int, patchentry[1])
    xcord = parse(Int, patchentry[2])
    ycord = parse(Int, patchentry[3])
    defaultcapacity = setting("cellsize")
    # XXX the 'global' here is a hack so that I can use eval() later on
    # (eval() always works on the global scope)
    global newpatch = Patch(id, (xcord, ycord), defaultcapacity)
    @simlog("Creating patch $id at $xcord/$ycord", 'd')
    # parse other parameter options
    for p in patchentry[4:end]
        varval = split(p, '=')
        var = varval[1]
        if !(var in map(string, fieldnames(Patch)))
            simlog("Unrecognized patch parameter $var.", 'w')
            continue
        elseif length(varval) < 2
            # if no value is specified, assume 'true'
            # (unless the variable is prepended with an exclamation mark, then take 'false')
            if var[1] == '!'
                var = var[2:end]
                val = false
            else
                val = true
            end
        else
            val = Meta.parse(varval[2])
        end
        # check for correct type and modify the new patch
        vartype = typeof(eval(Meta.parse("newpatch."*var)))
        if !isa(val, vartype)
            try
                val = convert(vartype, val)
            catch
                simlog("Invalid patch parameter type $var: $val", 'w')
                continue
            end
        end
        eval(Meta.parse("newpatch."*string(var)*" = $val"))
    end
    newpatch
end

"""
    createworld(maptable)

Use a parsed map file (as returned by `readmapfile`) to create the world. 
Initialises each patch with its parameters and a new community, then returns
an array of patches.
"""
function createworld(maptable::Array{Array{String,1},1})
    simlog("Creating world...")
    world = Array{Patch}(undef, length(maptable))
    for entry in eachindex(maptable)
        newpatch = createpatch(maptable[entry])
        if newpatch.initpop
            if setting("mode") == "zosterops"
                append!(newpatch.community, zgenesis(newpatch))
            elseif setting("indsize") != "seed"
                append!(newpatch.community, genesis(newpatch.capacity))
            else
                append!(newpatch.seedbank, genesis(newpatch.capacity))
            end
        end
        world[entry] = newpatch
    end
    global newpatch = nothing # remove variable used in `createpatch()`
    (setting("mode") == "zosterops") && findneighbours!(world)
    world
end

"""
    updateworld(world, maptable, cellsize)

Reinitialise the world from another parsed map file. Works analogously to 
`createworld`. Intended for use in scenarios where the model world changes
during a run (e.g. through global warming or island ontogeny).
If the ID of an old patch matches the ID of a new patch, its community and
seed bank are transferred to the new patch.
"""
function updateworld(oldworld::Array{Patch,1}, maptable::Array{Array{String,1},1})
    simlog("Updating world...")
    newworld = Array{Patch}(undef, length(maptable))
    for entry in eachindex(maptable)
        newpatch = createpatch(maptable[entry])
        updates = findfirst(p -> p.id==newpatch.id, oldworld)
        if !isnothing(updates) # did this patch exist in the old world?
            newpatch.community = oldworld[updates].community
            newpatch.seedbank = oldworld[updates].seedbank
        end
        newworld[entry] = newpatch
    end
    global newpatch = nothing # remove variable used in `createpatch()`
    (setting("mode") == "zosterops") && findneighbours!(newworld)
    return newworld
end
