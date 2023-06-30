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

initsettings(defaultSettings())

@testset "TraitCreation" begin
    @test typeof(createtraits()) == Vector{Trait}
    @test length(traits) == length(setting("traitnames"))
end

@testset "GeneCreation" begin
    @test typeof(creategenes(12, createtraits())) == Vector{AbstractGene}
end