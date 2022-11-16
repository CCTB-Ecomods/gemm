#File for setting up and benchmarking single functions

using 
    ArgParse,
    Dates,
    Distributions,
    Random,
    Statistics,
    DataFrames,

    BenchmarkTools

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

    include("testutils.jl")

#Benchmark zdisperse
testsettings("test.config")
world = mktestworld(100, 100, 10)
hubert = testspawn(male)
hubert.traits["dispmean"] = 50
hubert.traits["precopt"] = 10.0
world[4950].seedbank = [hubert] #this is coordinate 50,50 use `coordinates()`

    
Random.seed!(0)
@benchmark zdisperse!($world[4950].seedbank[1], $world[4950], $world)
@benchmark zdisperse!($world)