# All functions specific to the Zosterops experiments.
# Initialise predefined species and redefine dispersal and reproduction

# IMPORTANT NOTES (when using `zosterops` mode)
#
# 1. the second environmental niche is now `above-ground carbon` instead of
#    `precipitation` (unfortunately, we can't actually rename it everywhere)
# 2. the `cellsize` setting now determines the patch carrying capacity in
#    individuals, not grams
# 3. the `fertility` setting is the absolute number of offspring per breeding pair
#    (instead of a metabolic coefficient)
# 4. the `tolerance` setting now determines the probability that a mate of
#    another species is accepted, if no conspecific mate is available
# 5. `degpleiotropy` must be set to 0, otherwise the species initialisation will fail
# 6. the world must be a rectangle with patch coordinates in row-major order,
#    otherwise dispersal will show weird behaviour (see `coordinate()`)

let zosterops = Individual[] #holds the species archetypes
    """
        initzosteropsspecies()

    Initialise the predefined Zosterops species archetypes (silvanus/highland, jubaensis/lowland).
    """
    function initzosteropsspecies()
        # ensure that "one gene, one trait" is true and that we have species definitions
        (setting("degpleiotropy") != 0) && @simlog("degpleiotropy must be 0", 'e')
        (isnothing(setting("species"))) && @simlog("no species defined", 'e')
        # load per-species trait values from settings (especially AGC optimum and tolerance)
        for sp in setting("species")
            push!(zosterops, initzosteropsspecies(sp))
        end
    end

    """
        initzosteropsspecies(name, precopt, prectol)

    Create a new individual then modify its traits to create a Zosterops archetype.
    """
    function initzosteropsspecies(spectraits::Dict{String,Any})
        archetype = createind()
        archetype.lineage = spectraits["lineage"]
        # Find the genes that code for relevant traits and change their values
        for chromosome in archetype.genome
            setting("heterozygosity") && (chromosome.lineage = archetype.lineage)
            for gene in chromosome.genes
                isempty(gene.codes) && continue
                genetrait = setting("traitnames")[gene.codes[1].nameindex]
                if in(genetrait, keys(spectraits))
                    gene.codes[1].value = spectraits[genetrait]
                end
            end
        end
        # then recalculate the individual's trait dict and return the finished archetype
        if setting("linkage") == "none" # `degpleiotropy` is definitely 0 for zosterops mode
            archetype.traits = gettraitdictfast(archetype.genome, setting("traitnames"))
        else
            archetype.traits = gettraitdict(archetype.genome, setting("traitnames"))
        end
        return archetype
    end
    
    """
        getzosteropsspecies(name, sex)

    Return a new individual of the named species
    """
    global function getzosteropsspecies(name::String, sex::Sex)
        # This function has to be global to escape the let-block of the species list
        isempty(zosterops) && initzosteropsspecies()
        bird = nothing
        for z in zosterops
            if z.lineage == name
                bird = deepcopy(z)
                break
            end
        end
        (isnothing(bird)) && @simlog("Unknown species name: "*name, 'e')
        bird.id = rand(UInt32)
        varyalleles!(bird.genome, rand())
        if setting("linkage") == "none" # `degpleiotropy` is definitely 0 for zosterops mode
            bird.traits = gettraitdictfast(bird.genome, setting("traitnames"))
        else
            bird.traits = gettraitdict(bird.genome, setting("traitnames"))
        end
        bird.size = bird.traits["repsize"] # we need to fix the size after again after mutation
        bird.sex = sex
        return bird
    end
end

"""
    zgenesis(patch)

Create a new community of Zosterops breeding pairs (possibly of multiple species).
Returns an array of individuals.
"""
function zgenesis(patch::Patch)
    community = Array{Individual, 1}()
    (isnothing(setting("species"))) && @simlog("no species defined", 'e')
    # check which species can inhabit this patch
    species = Array{String, 1}()
    for s in setting("species")
        if abs(s["precopt"]-patch.prec) <= s["prectol"]
            push!(species, s["lineage"])
        end
    end
    (isempty(species)) && return community
    # calculate the number of initial breeding pairs and add a male and a female for each
    npairs = Integer(rand(0:round(setting("cellsize")/2)))
    for i in 1:npairs
        sp = rand(species)
        m = getzosteropsspecies(sp, male)
        f = getzosteropsspecies(sp, female)
        f.partner = m.id
        m.partner = f.id
        push!(community, m)
        push!(community, f)
        @simlog("Adding a pair of Z.$sp", 'd')
    end
    community
end
    
"""
    zdisperse!(world)

Disperse all juvenile individuals within the world. 
"""
function zdisperse!(world::Array{Patch,1})
    for patch in world
        for ind in patch.seedbank
            zdisperse!(ind, patch, world)
        end
        patch.seedbank = Array{Individual,1}()
    end
end

"""
    zdisperse!(bird, patch, world)

Dispersal of a single bird. Birds look patches with a suitable
habitat and a free territory or available mate. (Cf. Aben et al. 2016)
"""
function zdisperse!(bird::Individual, patch::Patch, world::Array{Patch,1})
    # keep track of where we've been and calculate the max dispersal distance
    route = [patch.location]
    #XXX disperse!() adds `/sqrt(2)`??
    #XXX sex-biased maximum dispersal?
    !(bird.traits["dispshape"] > 0) && @goto failure # Logistics() requires θ > zero(θ)
    maxdist = rand(Logistic(bird.traits["dispmean"], bird.traits["dispshape"]))
    while maxdist > 0
        # calculate the best habitat patch in the surroundings (i.e. the closest to AGC optimum)
        bestdest = nothing
        bestfit = nothing
        for pid in patch.neighbours
            neighbour = world[pid]
            (neighbour.location in route) && continue
            neighbourfit = abs(neighbour.prec - bird.traits["precopt"])
            if isnothing(bestdest) || neighbourfit < bestfit
                bestdest, bestfit = neighbour, neighbourfit
            end
        end
        (isnothing(bestdest)) && @goto failure
        # check if the patch is within the bird's AGC range and has free space
        if (bestfit <= bird.traits["prectol"] && length(bestdest.community) < setting("cellsize"))
            # can we settle here?
            partner = zfindmate(bestdest.community, bird)
            if !isnothing(partner)
                # if we've found a partner
                bird.partner = partner.id
                partner.partner = bird.id
                @goto success
            elseif length(bestdest.community) <= (setting("cellsize")-2)
                # if there's space for another breeding pair
                @label success
                bird.marked = true
                push!(bestdest.community, bird)
                @simlog("$(idstring(bird)) moved to $(bestdest.location).", 'd')
                return #if we've found a spot, we're done
            end
        end
        push!(route, bestdest.location)
        patch = bestdest
        maxdist -= 1
    end #if the max dispersal distance is reached, the individual simply dies
    @label failure #XXX this could be removed (and `@goto failure` replaced with a simple `return`)
    @simlog("A Z.$(bird.lineage) died after failed dispersal.", 'd')
end

"""
    zfindmate(population, bird)

Find an available breeding partner in the given population, preferring
conspecifics. Returns the partner individual, or nothing.
"""
function zfindmate(population::AbstractArray{Individual, 1}, bird::Individual)
    partner = nothing
    for b in population
        (b.lineage != bird.lineage) && continue
        if ziscompatible(bird, b)
            partner = b
            break
        end
    end
    if isnothing(partner) && setting("speciation") == "off"
        for b in population
            (b.lineage == bird.lineage) && continue
            if ziscompatible(bird, b)
                partner = b
                break
            end
        end                
    end
    return partner
end

"""
    ziscompatible(individual1, individual2)

Check to see whether two birds are reproductively compatible.
"""
function ziscompatible(i1::Individual, i2::Individual)
    (i1.sex == i2.sex) && return false
    !(i1.partner == 0 && i2.partner == 0) && return false
    if setting("speciation") == "off" #check for hybridisation
        (i1.lineage != i2.lineage && rand(Float64) > setting("tolerance")) && return false
    else #check for speciation
        (!iscompatible(i1, i2)) && return false
    end
    @simlog("Found a partner: $(idstring(i1)) and $(idstring(i2)).", 'd')
    return true
end
    
"""
    zreproduce!(patch)

Reproduction of Zosterops breeding pairs in a patch.
"""
function zreproduce!(patch::Patch)
    noffs = Integer(setting("fertility"))
    for bird in patch.community
        @simlog("$(idstring(bird)), $(bird.sex), partner: $(bird.partner)", 'd')
        if bird.partner != 0
            pt = findfirst(b -> b.id == bird.partner, patch.community)
            if isnothing(pt) # birds can find a new partner if one has died
                @simlog("$(idstring(bird)) no longer has a partner.", 'd')
                bird.partner = 0
            elseif bird.sex == female # only mate once per pair
                partner = patch.community[pt]
                @simlog("$(idstring(bird)) mated with $(idstring(partner)).", 'd')
                append!(patch.seedbank, createoffspring(noffs, bird, partner, true))
            end
        end
    end
end

let width = 0, height = 0
    """
        coordinate(x, y, world)

    A utility function to perform a fast look-up for the patch at coordinate x/y.
    Important: this assumes a rectangular world with coordinates in row-major order!
    Returns the index of the desired patch.
    """
    global function coordinate(x::Int, y::Int, world::Array{Patch,1})
        if iszero(width)
            width = maximum(p -> p.location[1], world)
            height = maximum(p -> p.location[2], world)
        end
        (x <= 0 || y <= 0 || x > width || y > height) && return
        i = ((y-1) * width) + x
        return i
    end
end

"""
    findneighbours(world)

Construct a list of neighbours for each patch in the world, for faster lookup
later on. (Must be called during initialisation.)
"""
function findneighbours!(world::Array{Patch,1})
    for patch in world
        for x in (patch.location[1]-1):(patch.location[1]+1)
            for y in (patch.location[2]-1):(patch.location[2]+1)
                ((x,y) == patch.location) && continue
                neighbour = coordinate(x,y,world)
                (isnothing(neighbour)) && continue
                push!(patch.neighbours, neighbour)
            end
        end
    end
end

"""
    idstring(individual)

A small utility function that returns a string identifier for a given individual.
"""
function idstring(bird::Individual)
    return "Z."*bird.lineage*" "*string(bird.id)
end

