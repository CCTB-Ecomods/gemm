#!/usr/bin/python3
##
## A script to set up and launch the Zosterops habitat fragmentation experiments.
##
## Daniel Vedder, 16/02/2021
##

# NOTE: make sure to copy/symlink this to the model root folder before running

import os, sys, shutil, time, subprocess

## PARAMETERS AND VARIABLES

# See `zosterops.config` for details
default_settings = {
    # input/output settings
    "outfreq":10,
    "logging":"true",
    "debug":"false",
    "stats":"true",
    "lineages":"true",
    "fasta":"off",
    "raw":"false",
    # general model parameters
    "linkage":"none",
    "nniches":2,
    "static":"false",
    "mutate":"false",
    "phylconstr":0.1,
    "mutationrate":"3.6e10",
    "usebiggenes":"false",
    "compressgenes":"false",
    "indsize":"adult",
    "capgrowth":"true",
    "degpleiotropy":0,
    # Zosterops-specific parameters
    "mode":"zosterops",
    "speciation":"off",
    "cellsize":8,
    "fertility":2,
    "dispmean":18,
    "dispshape":2,
    "maxrepsize":2.5,
    "minrepsize":2.3,
    "maxtemp":303,
    "mintemp":283,
    "mortalitytype":"global",
    "mortality":0.125,
    "heterozygosity":"true",
    # species parameters
    "species":'[Dict("lineage"=>"silvanus","precopt"=>180,"prectol"=>90,"tempopt"=>293,"temptol"=>2),Dict("lineage"=>"flavilateralis","precopt"=>50,"prectol"=>47,"tempopt"=>293,"temptol"=>2)]',
    "traitnames":'["compat","dispmean","dispshape","numpollen","precopt","prectol","repsize","seqsimilarity","seedsize","tempopt","temptol"]',
    # variable parameters
    "maps":"taita_hills.map",
    "tolerance":0.01
}

alternate_tolerances = [0, 0.01, 0.05, 0.1, 0.5, 1.0]

alternate_maps = ["taita_hills_default.map", "taita_hills_plantations.map",
                  "taita_hills_corridors.map", "taita_hills_edgedepletion.map",
                  "taita_hills_patchclearing.map"]

alternate_mutationrates = ["0", "3.6e09", "3.6e10", "3.6e11"]

alternate_linkages = ["none", "random", "full"]


## AUXILIARY FUNCTIONS

def archive_code():
    "Save the current codebase in a tar archive."
    tarname = time.strftime("GeMM_source_%d%b%y.tar.gz")
    print("Archiving codebase in "+tarname)
    os.system("git log -1 > current_commit.txt")
    cmd = "tar czhf " + tarname + " README.md current_commit.txt rungemm.jl src/* " +\
        "examples/zosterops/*.py examples/zosterops/*.R examples/zosterops/*.map " +\
        "examples/zosterops/*.config"
    subprocess.run(cmd, shell=True)
    os.remove("current_commit.txt")
    return tarname

def write_config(config, dest, seed, **params):
    "Write out a config file with the given values"
    cf = open(config, 'w')
    cf.write("# GeMM Zosterops: Taita Hills study\n")
    cf.write("# This config file was generated automatically by `habitatstudy.py`.\n")
    cf.write("# "+time.asctime()+"\n")
    cf.write("\ndest "+dest+"\n")
    cf.write("seed "+str(seed)+"\n")
    for k in default_settings.keys():
        value = default_settings[k]
        if k in params.keys(): value = params[k]
        cf.write(k + " " + str(value) + "\n")
    cf.close()
    
def run_default():
    "Launch a single run with the default values."
    print("Running a default simulation.")
    conf = "zosterops_default.config"
    dest = "results/taita_hills"
    shutil.copy("examples/zosterops/"+default_settings["maps"], ".")
    if os.path.exists(dest):
        if input("Delete old test data? (y/n) ") == 'y':
            shutil.rmtree(dest)
        else:
            print("Aborting.")
            return
    write_config(conf, dest, 0)
    subprocess.run(["julia", "rungemm.jl", "--config", conf])


## EXPERIMENT FUNCTIONS

## TODO write a generic experiment function
## def run_experiment(configs)

def run_hybridisation_experiment(seed1, seedN):
    """
    Launch a set of replicate simulations for the hybridisation experiment.
    Starts one run for each tolerance setting for each replicate seed from 1 to N.
    """
    print("Running "+str(seedN-seed1+1)+" replicates of the hybridisation experiment.")
    running_sims = []
    shutil.copy("examples/zosterops/"+default_settings["maps"], ".")
    seed = seed1
    while seed <= seedN:
        for t in alternate_tolerances:
            conf = "tolerance_"+str(t)+"_"+str(seed)
            write_config(conf+".config", "results/"+conf, seed, tolerance=t)
            sim = subprocess.Popen(["julia", "rungemm.jl", "--config", conf+".config"])
            running_sims.append(sim)
        seed = seed + 1
    for s in running_sims:
        s.wait()
        
def run_habitat_experiment(seed1, seedN, tolerance=default_settings["tolerance"]):
    """
    Launch a set of replicate simulations for the habitat fragmentation experiment.
    Starts one run for each map scenario for each replicate seed from 1 to N.
    """
    print("Running "+str(seedN-seed1+1)+" replicates of the habitat fragmentation experiment.")
    running_sims = []
    seed = seed1
    while seed <= seedN:
        for m in alternate_maps:
            shutil.copy("examples/zosterops/"+m, ".")
            conf = "habitat_tol"+str(tolerance)+"_"+m.split("_")[2][:-4]+"_"+str(seed)
            write_config(conf+".config", "results/"+conf, seed, maps=m, tolerance=tolerance)
            sim = subprocess.Popen(["julia", "rungemm.jl", "--config", conf+".config"])
            running_sims.append(sim)
        seed = seed + 1
    for s in running_sims:
        s.wait()

def run_mutation_experiment(seed1, seedN):
    """
    Launch a set of replicate simulations for the mutation experiment.
    Starts one run for each mutation setting for each replicate seed from 1 to N.
    """
    print("Running "+str(seedN-seed1+1)+" replicates of the mutation experiment.")
    running_sims = []
    if default_settings["maps"] not in os.listdir():
        shutil.copy("examples/zosterops/"+default_settings["maps"], ".")
    seed = seed1
    while seed <= seedN:
        for m in alternate_mutationrates:
            conf = "mutation_"+str(m)+"_"+str(seed)
            write_config(conf+".config", "results/"+conf, seed, tolerance=0,
                         mutate="true", mutationrate=m)
            sim = subprocess.Popen(["julia", "rungemm.jl", "--config", conf+".config"])
            running_sims.append(sim)
        seed = seed + 1
    for s in running_sims:
        s.wait()

def run_linkage_experiment(seed1, seedN):
    """
    Launch a set of replicate simulations for the linkage experiment.
    Starts one run for each linkage setting for each replicate seed from 1 to N.
    """
    print("Running "+str(seedN-seed1+1)+" replicates of the linkage experiment.")
    running_sims = []
    shutil.copy("examples/zosterops/"+default_settings["maps"], ".")
    seed = seed1
    while seed <= seedN:
        for l in alternate_linkages:
            conf = "linkage_"+str(l)+"_"+str(seed)
            write_config(conf+".config", "results/"+conf, seed, linkage=l)
            sim = subprocess.Popen(["julia", "rungemm.jl", "--config", conf+".config"])
            running_sims.append(sim)
        seed = seed + 1
    for s in running_sims:
        s.wait()

def run_long_experiment(seed1, seedN):
    """
    Launch a set of replicate simulations for the long experiment (= hybridisation
    experiment with 1000 timesteps).
    """
    print("Running "+str(seedN-seed1+1)+" replicates of the long experiment.")
    running_sims = []
    mapfile = "taita_hills_long.map"
    shutil.copy("examples/zosterops/"+default_settings["maps"], mapfile)
    os.system('sed -e "4s/300/1000/" -i '+mapfile)
    seed = seed1
    while seed <= seedN:
        for t in alternate_tolerances:
            conf = "tolerance_long_"+str(t)+"_"+str(seed)
            write_config(conf+".config", "results/"+conf, seed, tolerance=t,
                         maps=mapfile, outfreq=25)
            sim = subprocess.Popen(["julia", "rungemm.jl", "--config", conf+".config"])
            running_sims.append(sim)
        seed = seed + 1
    for s in running_sims:
        s.wait()

## RUNTIME SCRIPT
        
## USAGE OPTIONS:
## ./habitatstudy.py [archive/default]
## ./habitatstudy.py [tolerance/habitat/mutation/linkage] <seed1> <seedN> [tolerance]
if __name__ == '__main__':
    archive_code()
    if len(sys.argv) < 2 or sys.argv[1] == "default":
        run_default()
    elif sys.argv[1] == "archive":
        pass #only archive the code
    elif sys.argv[1] == "tolerance":
        run_hybridisation_experiment(int(sys.argv[2]), int(sys.argv[3]))
    elif sys.argv[1] == "habitat":
        if len(sys.argv) > 4: #if the tolerance is specified
            run_habitat_experiment(int(sys.argv[2]), int(sys.argv[3]), sys.argv[4])
        else: run_habitat_experiment(int(sys.argv[2]), int(sys.argv[3]))
    elif sys.argv[1] == "mutation":
        run_mutation_experiment(int(sys.argv[2]), int(sys.argv[3]))
    elif sys.argv[1] == "linkage":
        run_linkage_experiment(int(sys.argv[2]), int(sys.argv[3]))
    elif sys.argv[1] == "long":
        run_long_experiment(int(sys.argv[2]), int(sys.argv[3]))
