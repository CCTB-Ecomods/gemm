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
    "heterozygosity":"true",
    # species parameters
    "species":'[Dict("lineage"=>"silvanus","precopt"=>180,"prectol"=>90,"tempopt"=>293,"temptol"=>2),Dict("lineage"=>"jubaensis","precopt"=>50,"prectol"=>47,"tempopt"=>293,"temptol"=>2)]',
    "traitnames":'["compat","dispmean","dispshape","numpollen","precopt","prectol","repsize","seqsimilarity","seedsize","tempopt","temptol"]',
    # variable parameters
    "maps":"taita_hills.map",
    "tolerance":0.1 #TODO is this sensible?
}

alternate_tolerances = [0, 0.01, 0.05, 0.1, 0.5, 1.0]

alternate_maps = ["taita_hills_default.map", "taita_hills_plantations.map",
                  "taita_hills_corridors.map", "taita_hills_edgedepletion.map",
                  "taita_hills_patchclearing.map"]

alternate_mutationrates = ["0", "3.6e9", "3.6e10", "3.6e11"]

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
    if not os.path.exists(default_settings["maps"]):
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
    
def run_hybridisation_experiment(seed1, seedN):
    """
    Launch a set of replicate simulations for the hybridisation experiment.
    Starts one run for each tolerance setting for each replicate seed from 1 to N.
    """
    print("Running "+str(seedN-seed1+1)+" replicates of the hybridisation experiment.")
    running_sims = []
    if default_settings["maps"] not in os.listdir():
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
    if default_settings["maps"] not in os.listdir():
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
        
def run_habitat_experiment(seed1, seedN):
    """
    Launch a set of replicate simulations for the habitat fragmentation experiment.
    Starts one run for each map scenario for each replicate seed from 1 to N.
    """
    print("Running "+str(seedN-seed1+1)+" replicates of the habitat fragmentation experiment.")
    running_sims = []
    seed = seed1
    while seed <= seedN:
        for m in alternate_maps:
            if m not in os.listdir():
                shutil.copy("examples/zosterops/"+m, ".")
            conf = "habitat_"+m.split("_")[2][:-4]+"_"+str(seed)
            write_config(conf+".config", "results/"+conf, seed, maps=m)
            sim = subprocess.Popen(["julia", "rungemm.jl", "--config", conf+".config"])
            running_sims.append(sim)
        seed = seed + 1
    for s in running_sims:
        s.wait()


## RUNTIME SCRIPT
        
## USAGE OPTIONS:
## ./habitatstudy.py [archive/default]
## ./habitatstudy.py [hybrid/habitat/mutation/linkage] <seed1> <seedN>
if __name__ == '__main__':
    archive_code()
    if len(sys.argv) < 2 or sys.argv[1] == "default":
        run_default()
    elif sys.argv[1] == "archive":
        pass #only archive the code
    elif "hybrid" in sys.argv[1]:
        run_hybridisation_experiment(int(sys.argv[2]), int(sys.argv[3]))
    elif "habitat" in sys.argv[1]:
        run_habitat_experiment(int(sys.argv[2]), int(sys.argv[3]))
    elif "mutation" in sys.argv[1]:
        run_mutation_experiment(int(sys.argv[2]), int(sys.argv[3]))
    elif "linkage" in sys.argv[1]:
        run_linkage_experiment(int(sys.argv[2]), int(sys.argv[3]))
