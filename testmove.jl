# testscript to check whether movement function is unbiased
# Robin Rölz - 2022/10/26

using
    ArgParse,
    Dates,
    Distributions,
    Random,
    Statistics
    
include("src/defaults.jl")

include("src/entities.jl")

include("src/input.jl")

include("src/output.jl")

include("src/constants.jl")

include("src/initialisation.jl")

include("src/genetics.jl")

include("src/reproduction.jl")

include("src/dispersal.jl")

include("src/survival.jl")

include("src/habitatchange.jl")

include("src/invasion.jl")

include("src/zosterops.jl")

include("src/scheduling.jl")

include("src/run_simulation.jl")

# seed = 2
# initsettings(defaultSettings()) #needed for log calls during `getsettings()`
# initsettings(getsettings("test.config", seed))
# setupdatadir()
# world = Patch[]
# timesteps = 0
# timeoffset = 0
# readmapfile("map100.map")
# print(map)

map = basicparser("map100.map")
# Patch[]
# world = Patch[]
#append!(world[5000].community, zgenesis(5000))
print(world[5000])

function testworld(map::Array{Array{String,1},1})
    #simlog("Creating world...")
    world = Array{Patch}(undef, length(map))
    for entry in eachindex(map)
        newpatch = createpatch(map[entry])
        if newpatch.initpop
                append!(newpatch.community, zgenesis(newpatch))
        end
        world[entry] = newpatch
    end
    global newpatch = nothing # remove variable used in `createpatch()`
    findneighbours!(world)
    world
end