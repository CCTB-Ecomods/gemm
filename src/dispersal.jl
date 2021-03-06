# All functions related to dispersal:
# - dispersal
# - establishment
# - viability checking

"""
    disperse!(world, static)

Dispersal of individuals within the world.
"""
function disperse!(world::Array{Patch,1}, static::Bool)
    static && updatesetting("borders", "mainland") #backward compatibility
    for patch in world
        idx = 1
        while idx <= length(patch.seedbank) # disperse each juvenile
            dispmean = patch.seedbank[idx].traits["dispmean"]
            dispshape = patch.seedbank[idx].traits["dispshape"]
            # scaling so that geometric mean follows original distribution (?)
            xdir = rand([-1,1]) * rand(Logistic(dispmean,dispshape))/sqrt(2) 
            ydir = rand([-1,1]) * rand(Logistic(dispmean,dispshape))/sqrt(2)
            xdest = patch.location[1] + Int(round(xdir))
            ydest = patch.location[2] + Int(round(ydir))
            target = (xdest, ydest)
            (setting("borders") != "absorbing") && (target = checkborderconditions(world, xdest, ydest))
            possdest = findfirst(x -> x.location==target, world)
            # Note: the following section allows for a mainland/island scenario in which the
            # mainland is static (i.e. mainland individuals are treated as archetypes from
            # an infinitely large source population).
            if static
                if !world[possdest].isisland
                    idx += 1 # disperse only to islands
                    continue
                end
                if !patch.isisland
                    indleft = deepcopy(patch.seedbank[idx])
                end
            end
            if !static || patch.isisland
                # only remove individuals from islands / non-static mainland
                indleft = splice!(patch.seedbank,idx) 
                idx -= 1
            end
            # Add the dispersed individual to the new community. If no there is no
            # viable target patch, the individual dies.
            (!isnothing(possdest)) && push!(world[possdest].community, indleft)
            idx += 1
        end
    end
end

"""
    establish!(patch, nniches)

Establishment of individuals in patch `p`: Sets the adaptation parameters (~fitness)
according to an individual's adaptation to the niches of the surrounding environment.

A maximum of two niches (temperature and "precipitation") is currently supported.
"""
function establish!(patch::Patch, nniches::Int=1)
    temp = patch.temp
    idx = 1
    while idx <= size(patch.community,1)
        if patch.community[idx].marked
            opt = patch.community[idx].traits["tempopt"]
            tol = patch.community[idx].traits["temptol"]
            fitness = gausscurve(opt, tol, temp, 0.0)
            fitness > 1 && (fitness = 1) # should be obsolete
            fitness < 0 && (fitness = 0) # should be obsolete
            patch.community[idx].tempadaptation = fitness
            if nniches >= 2
                opt = patch.community[idx].traits["precopt"]
                tol = patch.community[idx].traits["prectol"]
                fitness = gausscurve(opt, tol, patch.prec, 0.0)
                fitness > 1 && (fitness = 1) # should be obsolete
                fitness < 0 && (fitness = 0) # should be obsolete
                patch.community[idx].precadaptation = fitness
            end
            patch.community[idx].marked = false
        end
        idx += 1
    end
end

"""
    establish!(world, nniches, static)

Carry out establishment for each patch in the world.
"""
function establish!(world::Array{Patch,1}, nniches::Int=1, static::Bool = true)
    for patch in world
        (patch.isisland || !static) && establish!(patch, nniches) # pmap(!,patch) ???
    end
end

"""
    checkviability!(community)

Check whether all individuals in the passed community conform to a basic set of
constraints (i.e. all traits are present and certain properties are >= 0).
Individuals that fail the test are removed from the community.
"""
function checkviability!(community::Array{Individual, 1})
    idx=1
    while idx <= size(community,1)
        reason = ""
        dead = false
        itraits = community[idx].traits
        community[idx].size <= 0 && (dead = true) && (reason *= "size ")
        any(collect(values(itraits)) .< 0) && (dead = true) && (reason *= "traitvalues ")
        itraits["repsize"] < itraits["seedsize"] && (dead = true) && (reason *= "seed/rep ")
        community[idx].tempadaptation < 0 && (dead = true) && (reason *= "fitness ")
        community[idx].precadaptation < 0 && (dead = true) && (reason *= "fitness ")
        in("selfing", keys(itraits)) && itraits["selfing"] > 1 && (dead = true) && (reason *= "selfing ")
        itraits["seqsimilarity"] > 1 && (dead = true) && (reason *= "seqsimilarity ")
        !traitsexist(itraits) && (dead = true) && (reason *= "missingtrait ")
        if dead
            simlog("Individual not viable: $reason. Being killed.", 'w')
            splice!(community,idx)
            continue
        end
        idx += 1
    end
end

"""
    checkviability(world)

Check the viability of all individuals.
"""
function checkviability!(world::Array{Patch,1})
    for patch in world
        #XXX pmap(checkviability!,patch) ???
        checkviability!(patch.community)
    end
end


"""
    traitsexist(traits)

Check a trait dict to make sure it contains the full set of traitnames required
by the model (as defined in the settings).
"""
function traitsexist(traits::Dict{String, Float64})
    missingtraits = setdiff(setting("traitnames"), keys(traits))
    if length(missingtraits) > 0
        simlog("Missing trait $missingtraits. Individual might be killed.", 'w')
        return false
    end
    true
end

"""
    traitsexist(individual)

Make sure an individual organism has the full set of traits required by the model
(as defined in the settings).
"""
function traitsexist(ind::Individual)
    traitnames = setting("traitnames")
    for trait in traitnames
        if !haskey(ind.traits, trait)
            simlog("Individual is missing trait $trait. Might be killed.", 'e')
            return false
        end
    end
    true
end


"""
    gausscurve(b, c, x, a=1.0)

Calculate the value of the Gauss function ("bell curve") at point x; with
a being the maximum height of the curve, b the position of the curve center and
c the standard deviation ("width").
"""
function gausscurve(b, c, x, a = 1.0)
    if c != 0 && a != 1.0
        a = 1 / (c * sqrt(2 * pi))
        y = a * exp(-(x-b)^2/(2*c^2))
    elseif c != 0
        y = a * exp(-(x-b)^2/(2*c^2))
    else
        y = 0.0
    end
end


"""
    findisland(w)

Within world `w`, find out in which direction from the continent the island lies.
"""
function findisland(world::Array{Patch,1})
    # Context: this function is one of the oldest pieces of code in the model.
    # It was created when GeMM was still targeted at island/mainland studies,
    # and assumes a lot of things that we do differently now. It has been kept
    # for backward compatibility, but is only used when setting("borders") == "mainland".
    xmin, xmax = extrema(map(x->x.location[1],world))
    ymin, ymax = extrema(map(x->x.location[2],world))
    westernborder = filter(x->x.location[1]==xmin,world)
    northernborder = filter(x->x.location[2]==ymax,world)
    easternborder = filter(x->x.location[1]==xmax,world)
    southernborder = filter(x->x.location[2]==ymin,world)
    if all(map(x->x.isisland,westernborder))
        return "west"
    elseif all(map(x->x.isisland,northernborder))
        return "north"
    elseif all(map(x->x.isisland,easternborder))
        return "east"
    elseif all(map(x->x.isisland,southernborder))
        return "south"
    else
        return "none"
    end
end

"""
    checkborderconditions!(w, x, y)

Check if the coordinates `x` and `y` lie within world `w` and correct if not,
considering the user-defined border conditions.
"""
function checkborderconditions(world::Array{Patch,1}, xdest::Int, ydest::Int)
    # First, figure out whether and by how much a destination coordinate overshoots
    # the world borders
    xmin, xmax = extrema(map(x->x.location[1],world))
    ymin, ymax = extrema(map(x->x.location[2],world))
    xrange = xmax  - xmin + 1 # we're counting cells!
    yrange = ymax  - ymin + 1 # we're counting cells!
    xshift = xdest - xmin + 1 # 1-based count of cells
    yshift = ydest - ymin + 1 # 1-based count of cells
    xshift > 0 ? outofx = abs(xshift) : outofx = abs(xshift) + 1
    while outofx > xrange
        outofx -= xrange
    end
    outofx -= 1
    yshift > 0 ? outofy = abs(yshift) : outofy = abs(yshift) + 1
    while outofy > yrange
        outofy -= yrange
    end
    outofy -= 1
    # If a coordinate lies outside the world, correct it depending on the border conditions
    if setting("borders") == "mainland"
        # Ye who come after: see the comment at `findisland()` to
        # understand the history of this dark place...
        islanddirection = findisland(world::Array{Patch,1})
        if islanddirection == "west"
            xdest > xmax && (xdest = xmax - outofx) # east: reflective
            ydest < ymin && (ydest = ymax - outofy) # south: periodic
            ydest > ymax && (ydest = ymin + outofy) # north: periodic
        elseif islanddirection == "north"
            ydest < ymin && (ydest = ymin + outofy) # south: reflective
            xdest < xmin && (xdest = xmax - outofx) # west: periodic
            xdest > xmax && (xdest = xmin + outofx) # east: periodic
        elseif islanddirection == "east"
            xdest < xmin && (xdest = xmin + outofx) # west: reflective
            ydest < ymin && (ydest = ymax - outofy) # south: periodic
            ydest > ymax && (ydest = ymin + outofy) # north: periodic
        elseif islanddirection == "south"
            ydest > ymax && (ydest = ymax - outofy) # north: reflective
            xdest < xmin && (xdest = xmax - outofx) # west: periodic
            xdest > xmax && (xdest = xmin + outofx) # east: periodic
        else
            ydest > ymax && (ydest = ymin + outofy) # north: periodic
            xdest > xmax && (xdest = xmin + outofx) # east: periodic
            ydest < ymin && (ydest = ymax - outofy) # south: periodic
            xdest < xmin && (xdest = xmax - outofx) # west: periodic
        end
    elseif setting("borders") == "reflective"
        ydest > ymax && (ydest = ymax - outofy) # north: reflective
        xdest > xmax && (xdest = xmax - outofx) # east: reflective
        ydest < ymin && (ydest = ymin + outofy) # south: reflective
        xdest < xmin && (xdest = xmin + outofx) # west: reflective
    end
    xdest, ydest
end
