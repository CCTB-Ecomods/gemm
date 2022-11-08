# Unit tests for some functions in zosterops

using Test
include("../src/entities.jl")
include("../src/zosterops.jl")

function mktestworld(xdim, ydim, prec)
    testworld = Array{Patch, 1}()
    i = 1
    for y in 1:ydim, x in 1:xdim
            p = Patch(i, (x, y), 10)
            push!(testworld, p)
            i+=1
    end
    findneighbours!(testworld)
    return testworld
end

@testset "findneighbours" begin
    w = mktestworld(100,200,10)
    @testset "corners" begin
        @test length(w[1].neighbours) == 3
        @test length(w[end].neighbours) == 3
    end
    @testset "assert neighbours" begin
        for p in w 
            @test !isempty(p.neighbours)
        end
    end
end


