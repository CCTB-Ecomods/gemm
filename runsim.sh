#!/bin/bash
# A quick-and-dirty script to launch a simulation run
# Daniel Vedder, 1/2/21

# Usage: `./runsim.sh <scenario> <setting> <replicate>`, where:
#        scenario: "constant", "variable"
#        setting: "small", "reflecting", "absorbing", "constrained"
#        replicate: an integer determining the random seed


# produce a new config file for this run, updating its output directory and seed
sed -e "s/$1_$2/$1_$2_$3/" \
	-e "s/seed 0/seed $3/" \
	examples/gradient/$1_$2.conf > $1_$2_$3.conf

# run the simulation
./rungemm.jl -c $1_$2_$3.conf