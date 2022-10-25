#!/usr/bin/env julia
#Robin - copy of rungemm.jl for debugging in VScode
using BenchmarkTools 

thisDir = joinpath(pwd(), "src")
any(path -> path == thisDir, LOAD_PATH) || push!(LOAD_PATH, thisDir)
using Pkg
Pkg.activate(".")
using GeMM

# remove od folder with results
remove_old_results = `rm -r results/islsim_test`
run(remove_old_results)

#run gemm directly from .config file
rungemm("studies/islandradiation/islsim_test.config", 0)