#Testing and example for julia workflow
module Ngb
export findneighbours!, mktestworld
using 
    ArgParse,
    Dates,
    Distributions,
    Random,
    Statistics,
    DataFrames,

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

end