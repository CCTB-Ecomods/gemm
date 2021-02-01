#!/bin/bash
# A quick-and-dirty script to launch a simulation run
# Daniel Vedder, 1/2/21

sed -e "s/$1_small/$1_small_$2/" $1_small.conf > $1_small_$2.conf

rungemm.jl -c $1_small_$2.conf
