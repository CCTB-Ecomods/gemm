```@meta
CurrentModule = GeMM
```

# Introduction

This is the function documentation for the Genetically explicit Metacommunity Model (GeMM).

The aim of this model is to create a virtual (island) ecosystem that can be used to
explore ecological and evolutionary hypotheses *in silico*. It is genetically
and spatially explicit, with discrete space and time.

This documentation is generated from the source code using Julia's inbuilt
`Documenter` module. It is sorted first by functionality, second by source code
file.

## Using the model as a library

The functions in the `run_simulation.jl` file are used to start a simulation run:

```@autodocs
Modules = [GeMM]
Pages = ["run_simulation.jl"]
```

## Using the model as a stand-alone application

To run a single experiment, execute:

```
./rungemm.jl -c <CONFIG>
```

Other commandline arguments are:

```
usage: rungemm.jl [-s SEED] [-m MAPS] [-c CONFIG] [-d DEST] [--debug]
                  [--quiet] [-h]

optional arguments:
  -s, --seed SEED      inital random seed (type: Int64)
  -m, --maps MAPS      list of map files, comma separated
  -c, --config CONFIG  name of the config file
  -d, --dest DEST      output directory. Defaults to current date
  --debug              debug mode. Turns on output of debug
                       statements.
  --quiet              quiet mode. Don't print output to screen.
  -h, --help           show this help message and exit
```

There's a separate script to run several replicates of a given experiment
in parallel. This is used as follows:

```
julia -p <NPROCS> rungemmparallel.jl -s <SEED> -n <NREPS> -c <CONFIG>
```

where `<NPROCS>` = number of cores, `<SEED>` = integer value to set a random seed, 
`<NREPS>` = number of replicates and `<CONFIG>` the configuration file.

*Last updated: 2021-04-03 (commit 7457dd7)*  
