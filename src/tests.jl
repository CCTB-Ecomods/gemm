# custom tests and utility functions to work on the program. 
# this file shouldn't be included it is just a helper.

using
    ArgParse,
    Dates,
    Distributions,
    Random,
    Statistics,

    DataFrames,
    DataStructures,
    CairoMakie

    include("defaults.jl")

    include("entities.jl")
    
    include("input.jl")
    
    include("output.jl")
    
    include("constants.jl")
    
    include("initialisation.jl")
    
    include("genetics.jl")
    
    include("reproduction.jl")
    
    include("dispersal.jl")
    
    include("survival.jl")
    
    include("habitatchange.jl")
    
    include("invasion.jl")
    
    include("zosterops.jl")
    
    include("scheduling.jl")
    
    include("run_simulation.jl")
 

"""
    testworld(mapfilename)

Creating a world for testing from a file
"""
function testworld(mapfilename::String, full::Bool = false) 
    maptable = basicparser(mapfilename)[2:end]
    world = Array{Patch}(undef, length(maptable))
    for entry in eachindex(maptable)
        newpatch = createpatch(maptable[entry])
        if full && newpatch.initpop
           append!(newpatch.community, testfill(newpatch)) 
        end
        world[entry] = newpatch
    end
    global newpatch = nothing # remove variable used in `createpatch()`
    findneighbours!(world)
    return world
end
"""
    testfill(patch::Patch)

hacky version based on 'zgenesis' returns an array to fully fill a patch with pairs of zosterops
"""
function testfill(patch::Patch)
    community = Array{Individual, 1}()
    npairs = Integer(round(patch.capacity/2))
    for i in 1:npairs
        m = testspawn(male)
        f = testspawn(female)
        f.partner = m.id
        m.partner = f.id
        push!(community, m)
        push!(community, f)
    end
    return community
end
"""
    testspawn(sex)

create an individual in a specific patch
"""
function testspawn(sex::Sex) #take settings from where?
    species = setting("species")[1]["lineage"]
    bird = getzosteropsspecies(species, sex)
    return bird
end
"""
    testsettings(config, seed)

get the settings for the testing. logging is turned off by default to test in console
"""
function testsettings(config::String = "", seed::Integer = 0)
    initsettings(defaultSettings())
    initsettings(getsettings(config, seed))
    updatesetting("logging", false)
    Random.seed!(setting("seed"))
end

## Testing on completely plane map
testsettings("test.config")
world = testworld("map100.map", true)
#make bird like the ones in simulation
hubert = testspawn(male)
hubert.traits["dispmean"] = 40
hubert.traits["dispshape"] = 0.04
world[4950].seedbank = [hubert] #this is coordinate 50,50 use `coordinates()`

#call the movement function a large number of times
routes = Vector{Vector{Tuple{Int64, Int64}}}()
for i in 1:100000
    r = zdisperse!(world[4950].seedbank[1], world[4950], world)
    push!(routes, r)
end

#plot the results
CairoMakie.activate!()
endpoint = [last(x) for x in routes]
epamount = counter(endpoint)
x_point = [first(x) for x in keys(epamount)]
y_point = [last(x) for x in keys(epamount)]
count = [x for x in values(epamount)]
heatmap(x_point, y_point, count)

pathpoints = Vector{Tuple{Int64, Int64}}()
for x in routes
    append!(pathpoints, x)
end
epamount = counter(endpoint)
x_point = [first(x) for x in keys(epamount)]
y_point = [last(x) for x in keys(epamount)]
count = [x for x in values(epamount)]
heatmap(x_point, y_point, count)

## Testing on sloped map no noise
testsettings("test.config")
world = testworld("studies/zosterops/Phylogeny_study/maptest.map", true)

#test and plot world
#make bird like the ones in simulation
hubert = testspawn(male)
hubert.traits["dispmean"] = 40
hubert.traits["dispshape"] = 0.04
world[9937].seedbank = [hubert] #this is coordinate 37, 100 use `coordinate()`

#call the movement function a large number of times
routes = Vector{Vector{Tuple{Int64, Int64}}}()
for i in 1:100000
    local r = zdisperse!(world[9937].seedbank[1], world[9937], world)
    push!(routes, r)
end

#plot the results
CairoMakie.activate!()
endpoint = [last(x) for x in routes]
epamount = counter(endpoint)
x_point = [first(x) for x in keys(epamount)]
y_point = [last(x) for x in keys(epamount)]
count = [x for x in values(epamount)]
heatmap(x_point, y_point, count)

pathpoints = Vector{Tuple{Int64, Int64}}()
for x in routes
    append!(pathpoints, x)
end
epamount = counter(endpoint)
x_point = [first(x) for x in keys(epamount)]
y_point = [last(x) for x in keys(epamount)]
count = [x for x in values(epamount)]
heatmap(x_point, y_point, count)