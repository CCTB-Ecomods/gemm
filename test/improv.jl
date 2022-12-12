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

    include("testutils.jl") #somehow including is weird here

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

    fig = Figure(resolution = (600, 800)) 
    ax1 = Axis(fig[1,2], 
        title = "Map of precipitation \n \n")
    world_map = heatmap!(ax1, -xloc, -yloc, prec,
        colormap = :speed)
    ax1.aspect = 0.25
    Colorbar(fig[1,1], world_map)

    ax2 = Axis(fig[1,3], 
        xticksvisible = false, 
        yticksvisible = false, 
        backgroundcolor = :grey, 
        title = "Visited tiles of 1000 repeated \n movements from ($x, $y),\n "*
        "of a bird with optimum \n precipitation of "
        *string(ind.traits["precopt"]))
    mov_map = heatmap!(ax2, -x_point, -y_point, count, 
        colormap = :imola)
    limits!(ax2, -xloc[end], -xloc[1], -yloc[end] , -yloc[1])
    ax2.aspect = 0.25
    Colorbar(fig[1,4], mov_map)

    set_theme!(backgroundcolor = :lightgrey)
        
    return fig
end

CairoMakie.activate!()

## Testing on completely plane map
testsettings("test.config")
world = testworld("map100.map", true)
#make bird like the ones in simulation
testind = testspawn(male)
testind.traits["dispmean"] = 40
testind.traits["dispshape"] = 0.04

plotfromspot(50, 50, world, testind)

## Testing on sloped map no noise
testsettings("test.config")
world = testworld("studies/zosterops/Phylogeny_study/maptest.map", true)

#test and plot world
#make bird like the ones in simulation
testind = testspawn(male)
testind.traits["dispmean"] = 40
testind.traits["dispshape"] = 0.04

plotfromspot(37,100, world, testind)

#this is coordinate 37, 100 use `coordinate()`

plotfromspot(37,100, world, testind)

testind.traits["dispmean"] = 40
testind.traits["precopt"] = 40.0
plotfromspot(50,180, world, testind)

## Testing on Taita Map
testsettings("test.config")
world = testworld("studies/zosterops/Phylogeny_study/Chyulu_Taita_Maps/Chyulu_750.map", true)
for p in world
    p.capacity = 0
end
#test and plot world
#make bird like the ones in simulation
testind = testspawn(male)
testind.traits["dispmean"] = 100
testind.traits["dispshape"] = 0.04

plotfromspot(37, 100, world, testind)