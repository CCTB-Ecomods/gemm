#!/usr/bin/env julia
#Robin - copy of rungemm.jl for debugging in VScode
using BenchmarkTools 

thisDir = joinpath(pwd(), "src")
any(path -> path == thisDir, LOAD_PATH) || push!(LOAD_PATH, thisDir)
using Pkg
Pkg.activate(".")
using GeMM

# remove old folder with results
rm("results/islsim_test/", recursive=true, force=true)

#run gemm directly from .config file
rungemm("studies/islandradiation/islsim_test.config", 2)
