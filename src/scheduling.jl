# Scheduling of processes in GeMM

"""
    simulate!(world, timesteps)

This is the central function of the model with the main event loop. It defines
the scheduling for all submodels and output functions.
"""
function simulate!(world::Array{Patch,1}, timesteps::Int=1000, timeoffset::Int = 0)
    simlog("Starting simulation.")
    checkviability!(world)
    for t in (timeoffset + 1):(timeoffset + timesteps)
        simlog("UPDATE $t")
        # ecological processes are outsourced to specialised methods below
        if setting("mode") == "default"
            defaultexperiment(world)
        elseif setting("mode") == "invasion"
            invasionexperiment(world, t)
        elseif setting("mode") == "zosterops"
            zosteropsexperiment(world)
        else
            simlog("Mode setting not recognised: $(setting("mode"))", 'e')
        end
        if iszero(mod(t, setting("outfreq")))
            writedata(world, t)
        end
    end
end

"""
    defaultexperiment(world)

The standard annual update procedure, designed primarily for plant communities.
"""
function defaultexperiment(world::Array{Patch,1})
    establish!(world)
    survive!(world)
    grow!(world)
    compete!(world)
    reproduce!(world)
    if setting("mutate")
        mutate!(world)
    end
    disperse!(world)
    changehabitat!(world) # model output
end

"""
    invasionexperiment(world)

The annual update procedure for the invasion experiments.
"""
function invasionexperiment(world::Array{Patch,1}, t::Int)
    establish!(world)
    survive!(world)
    grow!(world)
    compete!(world)
    reproduce!(world)
    if 0 < setting("burn-in") < t
        disturb!(world)
        invade!(world)
    end
    disperse!(world)
end

"""
    zosteropsexperiment(world)

The annual update procedure for the Zosterops experiments, this time for bird populations.
"""
function zosteropsexperiment(world::Array{Patch,1})
    # The first four processes are patch-internal and can therefore be parallelised
    # Note: multithreading requires calling Julia with the -p parameter
    Threads.@threads for patch in world
        establish!(patch)
        survive!(patch)
        zreproduce!(patch)
        if setting("mutate")
            mutate!(patch)
        end
    end
    zdisperse!(world)
end
