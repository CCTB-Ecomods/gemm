# Unit tests for some functions in zosterops

using Test
include("../src/entities.jl")
include("../src/output.jl")
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

@testset "zosterops" begin
    xlim, ylim = 75, 200
    w = mktestworld(xlim,ylim,10)

    @testset "coordinate()" begin 
        for x in 1:xlim, y in 1:ylim
            idx = coordinate(x, y, w)
            @test w[idx].location == (x, y)
        end
    end
    @testset "findneighbours" begin
        @testset "assert number neighbours" begin
            for p in w
                neighbour_length = 0
                x_edge = p.location[1] in [1, xlim]
                y_edge = p.location[2] in [1, ylim]
                if x_edge & y_edge
                    neighbour_length = 3
                elseif x_edge | y_edge
                    neighbour_length = 5
                else
                    neighbour_length = 8
                end
                @test length(p.neighbours) == neighbour_length
            end
        end
        @testset "has neighbours" begin
            for p in w
                @test !isempty(p.neighbours)
        
            end
        end
        @testset "mutual neighbours" begin
            for p in w
                all_mutual = true
                    for neighbour in p.neighbours
                        all_mutual = all_mutual && p.id in w[neighbour].neighbours
                    end
                @test all_mutual
            end
        end
    end
end


