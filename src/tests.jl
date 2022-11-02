# custom tests and utility functions to work on the program. 
# this file shouldn't be included it is just a helper.

using
    ArgParse,
    Dates,
    Distributions,
    Random,
    Statistics

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
    
#TODO: OOF the settings think is needed sadly :upsidedownface:
function testmap(mapfilename::String) 
    maptable = basicparser(mapfilename)[2:end]
    world = Array{Patch}(undef, length(maptable))
    for entry in eachindex(maptable)
        newpatch = createpatch(maptable[entry])
        world[entry] = newpatch
    end
    return world

#create a world completely in here
#populate it fully
#return it
end

```
create an individual in a specific patch
```
function testspawn() #take settings from where?
    # make an individual in a place
end