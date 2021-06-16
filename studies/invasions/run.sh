#!/bin/bash

echo "Copying input files."

cp studies/invasions/invasion.config studies/invasions/invasion.map .
rm -r results/invasion_test #remove after testing

echo "Starting simulation run."

date
time julia rungemm.jl --config invasion.config
date

echo "Deleting input files."

rm invasion.config invasion.map

echo "Done."
