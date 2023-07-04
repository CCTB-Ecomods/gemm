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


@testset "ChromosomeCreation" begin
    # check whether ploidy works
    @testset "Polyploidy" begin
        ngenes = 12
        genes = creategenes(ngenes, createtraits())
        @testset "One Chromosome" begin
            nchrms = 1
            @testset "ploidy 0" begin
                chrms = createchrms(nchrms, setting("ploidy"), genes, "x")
                @test length(chrms) == 2
                @test chrms[1].genes[1].sequence == chrms[2].genes[1].sequence
                @test chrms[1] !== chrms[2] #two seperate places in memory
            end
            @testset "ploidy 4" begin
                updatesetting("ploidy", 4)
                chrms = createchrms(nchrms, setting("ploidy"), genes, "x")
                @test length(chrms) == 4
                @test chrms[1].genes[1].sequence == chrms[2].genes[1].sequence
                @test chrms[1] !== chrms[3]
            end
        end
        @testset "degpleiotropy = 0" begin
            updatesetting("ploidy", 2)
            updatesetting("degpleiotropy", 0)
            nchrms = 12
            genes = creategenes(ngenes, createtraits())
            chrms = createchrms(nchrms, setting("ploidy"), genes, "x")
            @test length(chrms) == ngenes*2
            @testset "Duplicated genes" for n in 1:ngenes
                @test chrms[n].genes[1].sequence == chrms[n+nchrms].genes[1].sequence
            end
        end
    end
end

@testset "GeneCreation" begin
    @test typeof(creategenes(12, createtraits())) == Vector{AbstractGene}
end

@testset "TraitCreation" begin
    traits = createtraits()
    @test typeof(traits) == Vector{Trait}
    @test length(traits) == length(setting("traitnames"))
end