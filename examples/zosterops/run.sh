#!/bin/bash

echo "Copying input files."

cp examples/zosterops/zosterops.config .
#TODO change back to real simulation map
cp examples/zosterops/taita_hills_test.map .
#cp examples/zosterops/taita_hills.map .
rm -r results/taita_test #remove after testing

echo "Starting simulation run."

date
time julia rungemm.jl --config zosterops.config
date

echo "Deleting input files."

rm zosterops.config
#TODO change back to real simulation map
rm taita_hills_test.map
#rm taita_hills.map

echo "Done."
