#!/bin/bash

echo "Copying input files."

cp studies/islandradiation/islsim_test.config .
#TODO Does this map work for short tests
cp studies/islandradiation/islsim_test.map .
#cp studies/islandradiation/islsim.map .
rm -r results/islsim_test #remove after testing

echo "Starting simulation run."

date
julia rungemm.jl --config islsim_test.config
date

echo "Deleting input files."

rm islsim_test.config
#TODO change back to real simulation map
rm islsim_test.map
#rm islsim.map

echo "Done."