#!/usr/bin/env julia
# A very thin wrapper to start a GeMM simulation. If you need something fancier,
# have a look at `rungemmparallel.jl`, or import the GeMM module into your own
# wrapper script.

using Pkg
Pkg.activate(".")
using GeMM

rungemm()
