#!/usr/bin/env julia
#Robin - copy of rungemm.jl for debugging in VScode
using BenchmarkTools 

thisDir = joinpath(pwd(), "src")
any(path -> path == thisDir, LOAD_PATH) || push!(LOAD_PATH, thisDir)
using Pkg
Pkg.activate(".")
using GeMM

# remove old folder with results
<<<<<<< Updated upstream
remove_old_results = `rm -r results/islsim_test`
run(remove_old_results)

#run gemm directly from .config file
rungemm("studies/islandradiation/islsim_highmut.config", 0)
=======
rm("results/islsim_test/", recursive=true, force=true)

#run gemm directly from .config file
rungemm("studies/islandradiation/islsim_test.config")
>>>>>>> Stashed changes
