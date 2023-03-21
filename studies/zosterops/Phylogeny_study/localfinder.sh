#!/bin/bash
#
#SBATCH --job-name=localfinder
#SBATCH --output=localfinder_%A.out
#
#SBATCH --ntasks=1
#SBATCH --time=48:00:00
#SBATCH --mem-per-cpu=50G
#SBATCH --array=1
#
#SBATCH --mail-type=ALL
#SBATCH --mail-user=robin.roelz@stud-mail.uni-wuerzburg.de

echo $(date)
find maresults/ -type d -name "savannah_*_3??" -exec ./localfinder.bash {} \;
echo $(date)
