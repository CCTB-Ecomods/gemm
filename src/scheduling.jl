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
        if iszero(mod(t, setting("fastaoutfreq"))) && (setting("fasta") != "off")
            writefasta(world, t)
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
"""
    runsim(config, seed, prerun)

Performs a simulation run using configuration file `config`, random seed `seed`
and other settings provided via commandline, configuration file or the defaults.
"""
function runsim(config::String = "", seed::Integer = 0)
    initsettings(defaultSettings()) #needed for log calls during `getsettings()`
    initsettings(getsettings(config, seed))
    Random.seed!(setting("seed"))
    setupdatadir()
    world = Patch[]
    timesteps = 0
    timeoffset = 0
    correctmode!()
    for m in 1:length(setting("maps"))
        timeoffset += timesteps
        timesteps, maptable = readmapfile(setting("maps")[m])
        if m == 1
            world = createworld(maptable)
            writedata(world, timeoffset)
            setting("fasta") != "off" && writefasta(world, timeoffset)
        else
            world = updateworld(world, maptable)
        end
        simulate!(world, timesteps, timeoffset)
    end
    world
end


"""
    rungemm(config, seed)

Wrapper for `runsim()`
Runs a simulation using configuration file `config`, random seed `seed`
and other settings provided via commandline, configuration file or the defaults.
"""
function rungemm(config::String = "", seed::Integer = 0)
    @time world = runsim(config, seed)
end

"""
    correctmode!()

A heuristic function to keep backward compatibility. (The `mode` setting was
only introduced after several different experiments had already been carried
out with GeMM, so old config files don't include it.)
"""
function correctmode!()
    if setting("mode") == "default"
        # detect invasion mode
        if setting("global-species-pool") > 0 || setting("propagule-pressure") > 0
            simlog("Detected implicit invasion mode, updated settings.", 'w')
            updatesetting("mode", "invasion")
        end
        # XXX further modes?
    end
    if setting("precrange") != 0
        updatesetting("maxprec", setting("precrange"))
        simlog("`precrange` is deprecated, use `maxprec` instead.", 'w')
    end
end

let settings::Dict{String, Any}
    """
        initsettings(newsettings)

    Define a new settings dict.
    """
    global function initsettings(newsettings::Dict{String, Any})
        settings = newsettings
    end

    """
        setting(param)

    Return a configuration parameter from the settings.
    """
    global function setting(param::String)
        settings[param]
    end

    """
        updatesetting(param, value)

    Change the value of an individual config parameter.
    Use with caution!
    """
    global function updatesetting(param::String, value::Any)
        settings[param] = value
    end

    """
        settingkeys()

    Return all keys in the settings dict.
    """
    global function settingkeys()
        keys(settings)
    end
end
