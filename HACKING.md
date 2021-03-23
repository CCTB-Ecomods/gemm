# Hacking GeMM

**Note: this is specifically intended for development of the *Zosterops* project**

*Daniel Vedder, 19/01/2021*

## Important branches

- `master` This should only be updated when there is a new stable (i.e. correctly working) version.

- `zosterops` This is the primary development branch. This doesn't have to be bug-free, but should
  be able to run the model code without crashing.
  
  
## Development Workflow

1. If you're working on a larger feature, create a feature branch on Github. Otherwise, just use
   the local branch on your own computer.

2. Pull the current development version from [`zosterops`](https://github.com/lleiding/gemm/tree/zosterops).

3. Implement your changes.

4. Run `zrun.sh` (a symlink to `examples/zosterops/run.sh`) to make sure the model executes without crashing.

5. Commit your work frequently.

6. If you're using a local branch, push back to `zosterops` at intervals. Make sure the model runs
   before you do so. Also, do another pull before pushing in case somebody else changed the branch
   in the meantime.
   
7. If you're using a feature branch, push to it as often as you like. When you're done with the
   feature, merge any new developments from `zosterops` into it, then submit a merge request
   back into `zosterops`.
   
8. Repeat :-)

9. Don't break anything important!


## Profiling

If you want to test the model performance, there are two easy ways to do so:

1. Simply run the model via `zrun.sh`. It is already set up to print the output of the `@time`
   macro at the end of the run. This gives you execution time as well as the amount of memory
   allocations for a quick overview.
   
2. Open a Julia interpreter, then run `include("rungemmprofile.jl")` (twice!). This uses Julia's 
   [inbuilt profiler](https://docs.julialang.org/en/v1/manual/profile/) to give a more detailed
   insight into which functions are called how often. Output is saved to `profile_flat.txt` and
   `profile_tree.txt`. (The former gives cumulative function call frequencies, the latter a
   representation of the execution tree.)


## Hybridisation experiments

This is the procedure for running the hybridisation experiments (a.k.a. Daniel's master thesis):

1. **Map creation:** Place a GeoTIFF file with the environmental variable (typically above-ground
   carbon, or forest cover) in the `examples/zosterops` folder. The modify the `map_creator.R`
   script so that the variable `above_ground_carbon_file` reflects the name of your input file,
   and `map_output_file` gives the name of your desired output file. Tweak `simlength` if you
   need a different simulation run length. Start an R session, `source()` the map creator script, 
   and execute `runMap()`. This will produce a `.map` file that GeMM can read in.
   
2. **Running the experiment:** Copy the script `habitatstudy.py` from `examples/zosterops` to
   the model top-level directory. Make sure the `alternate_*` variables reflect the scenarios
   you want to run, and that the `default_settings` are as you wish them to be. All needed
   map files must be located in `examples/zosterops`. Then launch a batch of simulations with
   the bash command `./habitstudy.py <experiment> <seed1> <seedN>`. `<experiment>` can be
   one of "hybrid", "habitat", "mutation", or "linkage". The seeds specify the range of replicates
   to be run. (Simulations are assigned their replicate number as the RNG seed, so all simulations
   in the same replicate start with identical conditions.) The script launches one simulation run
   of each scenario of the given experiment for each seed. Runs are launched in parallel with one
   run per processor core, so make sure you have enough cores! (For example, running
   `./habitatstudy.py hybrid 6 10` will launch six scenarios with 5 replicates (6 through 10),
   making for a total of 30 cores.) The script waits until all runs have completed, then terminates.
   
3. **Analysing the data:** By default, model output data is stored in `results`, with one folder
   per simulation run. The folder name designates the experiment, scenario, and replicate number.
   Model output includes the simulation log file, copies of the configuration and map files, and,
   most importantly, the `pops_s*.tsv` file. This includes data on all populations over the
   course of the simulation. (Warning: big file!) To analyse a complete experiment, launch
   an R session and `source()` the script `examples/zosterops/analyse_fragmentation_study.R`.
   Set the `experiment` variable to the name of the experiment you are analysing, then execute
   `results = loadData()` to load all output files from that experiment. This can take a *long*
   time. Once it's finished, you can run `plotAll(results)`, or whatever individual function you 
   wish to call. To analyse a species other than "silvanus", either change the `defaultspecies`
   variable, or pass the species name as the second function argument to the plotting function
   (after `results`). To run the analysis script in batch mode, set `autorun` to `TRUE`,
   then execute `examples/zosterops/analyse_fragmentation_study.R <experiment>` in your shell.
