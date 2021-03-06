#!/usr/bin/env julia
# A very thin wrapper to start a GeMM simulation. If you need something fancier,
# have a look at `rungemmparallel.jl`, or import the GeMM module into your own
# wrapper script.

thisDir = joinpath(pwd(), "src")
any(path -> path == thisDir, LOAD_PATH) || push!(LOAD_PATH, thisDir)
using Pkg
Pkg.activate(".")
using GeMM

using Profile
Profile.clear()

rm("results/taita_test", recursive=true, force=true)

@profile rungemm("zosterops.config")

open("profile_flat.txt", "w") do s
    Profile.print(IOContext(s, :displaysize=>(300,145)), format=:flat, mincount=10, sortedby=:count)
end

open("profile_tree.txt", "w") do s
    Profile.print(IOContext(s, :displaysize=>(300,300)), mincount=10)
end

