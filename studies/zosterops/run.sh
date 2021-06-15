#!/bin/bash

echo "Copying input files."

cp studies/zosterops/zosterops.config .
#TODO change back to real simulation map
cp studies/zosterops/taita_hills_test.map .
#cp studies/zosterops/taita_hills.map .
rm -r results/taita_test #remove after testing

echo "Starting simulation run."

date
time julia -t auto rungemm.jl --config zosterops.config
date

echo "Deleting input files."

rm zosterops.config
#TODO change back to real simulation map
rm taita_hills_test.map
#rm taita_hills.map

echo "Done."
