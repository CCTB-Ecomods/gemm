#!/bin/bash
#original daniel Vedder, modified for testing by Robin Rölz 

echo "Copying input files."

cp studies/zosterops/Phylogeny_study/eco_test.config .
#TODO change back to real simulation map
cp studies/zosterops/Phylogeny_study/maptest.map .
#cp studies/zosterops/taita_hills.map .
rm -r results/phylo_test #remove after testing

echo "Starting simulation run."

date
time julia -t auto rungemm.jl --config eco_test.config
date

echo "Deleting input files."

rm eco_test.config
#TODO change back to real simulation map
rm maptest.map
#rm taita_hills.map

echo "Done."