#Utility functions specifically for testing the model. These
#are not needed in the main source code but sometimes do call on those
#functions

"""
    mktestworld(xdim, ydim, prec)

Creates a fully uniform world for testing functions
"""
function mktestworld(xdim, ydim, prec)
    testworld = Array{Patch, 1}()
    i = 1
    for y in 1:ydim, x in 1:xdim
            p = Patch(i, (x, y), prec)
            push!(testworld, p)
            i+=1
    end
    findneighbours!(testworld)
    return testworld
end
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