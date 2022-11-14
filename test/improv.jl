# this is basically a playground to look at the program and debug/
#test features that can't really be looked at 

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

    include("testutils.jl") #somehow including is fucky here

function plotfromspot(x, y, world::Array{Patch, 1}, ind::Individual)
    id = coordinate(x,y,world)
    
    world[id].seedbank = [ind]

    routes = Vector{Vector{Tuple{Int64, Int64}}}()
    for i in 1:1000
        local r = zdisperse!(world[id].seedbank[1], world[id], world)
        push!(routes, r)
    end

    pathpoints = Vector{Tuple{Int64, Int64}}()
    for x in routes
        append!(pathpoints, x)
    end
    epamount = counter(pathpoints)
    x_point = [first(x) for x in keys(epamount)]
    y_point = [last(x) for x in keys(epamount)]
    count = [x for x in values(epamount)]
    heatmap(x_point, y_point, count)

    xloc = [w.location[1] for w in world] 
    yloc = [w.location[2] for w in world]
    prec = [w.prec for w in world]

    # fig = Figure(resolution = (5000, 5000))
    fig, ax1, world_map = heatmap(-xloc, -yloc, prec,
        colormap = :speed)
    ax1.aspect = DataAspect()
    ax2, mov_map = heatmap(fig[1, end+1], -x_point, -y_point, count)
    limits!(ax2, -xloc[end], -xloc[1], -yloc[end] , -yloc[1])
    ax2.aspect = 0.25
    return fig
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
for i in 1:10000
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
spotidx = coordinate(37, 100, world)
world[spotidx].seedbank = [hubert] #this is coordinate 37, 100 use `coordinate()`

CairoMakie.activate!()
plotfromspot(37,100, world, hubert)

hubert.traits["dispmean"] = 40
hubert.traits["precopt"] = 40.0
plotfromspot(50,180, world, hubert)

## Testing on Taita Map
testsettings("test.config")
world = testworld("studies/zosterops/Phylogeny_study/Chyulu_Taita_Maps/Chyulu_750.map", true)
for p in world
    p.capacity = 0
end
#test and plot world
#make bird like the ones in simulation
hubert = testspawn(male)
hubert.traits["dispmean"] = 100
hubert.traits["dispshape"] = 0.04

world[4492].seedbank = [hubert] #this is coordinate 37, 100 use `coordinate()`

#call the movement function a large number of times
routes = Vector{Vector{Tuple{Int64, Int64}}}()
for i in 1:100
    local r = zdisperse!(world[4492].seedbank[1], world[4492], world)
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
epamount = counter(pathpoints)
x_point = [first(x) for x in keys(epamount)]
y_point = [last(x) for x in keys(epamount)]
count = [x for x in values(epamount)]
heatmap(x_point, y_point, count)
hist(length.(routes), bins = 50)

df = DataFrame(Idx = [w.id for w in world],
    XLoc = [w.location[1] for w in world], 
    YLoc = [w.location[2] for w in world],
    Prec = [w.prec for w in world])

fig, ax1, taita_map = heatmap(-df.XLoc, -df.YLoc, df.Prec,
    colormap = :speed)
ax1.aspect = DataAspect()
ax2, mov_map = heatmap(fig[1, end+1], -x_point, -y_point, count)
limits!(ax2, -1, -45, -1 , -171)
ax2.aspect = 0.25
fig