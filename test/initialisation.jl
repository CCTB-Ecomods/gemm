using 
    Test,

    ArgParse,
    Dates,
    Distributions,
    Random,
    Statistics

include("../src/run_simulation.jl")
include("../src/defaults.jl")
include("../src/entities.jl")
include("../src/genetics.jl")
include("../src/output.jl")
include("../src/initialisation.jl")

initsettings(defaultSettings())

@testset "CreateInd" begin
    ind = createind()
    @test typeof(ind) == Individual
end
