# custom tests and utility functions to work on the program. 

using 
    ArgParse,
    Dates,
    Distributions,
    Random,
    Statistics,

    DataFrames,
    DataStructures,
    CairoMakie

    include("../src/defaults.jl")

    include("../src/entities.jl")
    
    include("../src/input.jl")
    
    include("../src/output.jl")
    
    include("../src/constants.jl")
    
    include("../src/initialisation.jl")
    
    include("../src/genetics.jl")
    
    include("../src/reproduction.jl")
    
    include("../src/dispersal.jl")
    
    include("../src/survival.jl")
    
    include("../src/habitatchange.jl")
    
    include("../src/invasion.jl")
    
    include("../src/zosterops.jl")
    
    include("../src/scheduling.jl")
    
    include("../src/run_simulation.jl")

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

df = DataFrame(Loc = [w.location for w in world], 
    Nghb = [w.neighbours for w in world])


## Testing on sloped map no noise
testsettings("test.config")
world = testworld("studies/zosterops/Phylogeny_study/maptest.map", true)

#test and plot world
#make bird like the ones in simulation
hubert = testspawn(male)
hubert.traits["dispmean"] = 40
hubert.traits["dispshape"] = 0.04
world[5000].seedbank = [hubert] #this is coordinate 37, 100 use `coordinate()`

#call the movement function a large number of times
routes = Vector{Vector{Tuple{Int64, Int64}}}()
for i in 1:100000
    local r = zdisperse!(world[5000].seedbank[1], world[5000], world)
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

df = DataFrame(Idx = [w.id for w in world],
    Loc = [w.location for w in world], 
    Nghb = [w.neighbours for w in world],
    NumNghb = [length(w.neighbours) for w in world])

emptynghb = filter(p -> isempty(p.Nghb), df)

## Testing on Taita Map
testsettings("test.config")
world = testworld("studies/zosterops/Phylogeny_study/Chyulu_Taita_Maps/Chyulu_750.map", true)

#test and plot world
#make bird like the ones in simulation
hubert = testspawn(male)
hubert.traits["dispmean"] = 40
hubert.traits["dispshape"] = 0.04
world[5000].seedbank = [hubert] #this is coordinate 37, 100 use `coordinate()`

#call the movement function a large number of times
routes = Vector{Vector{Tuple{Int64, Int64}}}()
for i in 1:100000
    local r = zdisperse!(world[5000].seedbank[1], world[5000], world)
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

df = DataFrame(Idx = [w.id for w in world],
    Loc = [w.location for w in world], 
    Nghb = [w.neighbours for w in world],
    NumNghb = [length(w.neighbours) for w in world])

emptynghb = filter(p -> isempty(p.Nghb), df)

for n in world[5000].neighbours #oops, not great
    println(world[n].location)
end