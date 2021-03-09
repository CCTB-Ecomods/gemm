#!/usr/bin/python3
##
## A script to set up and launch the Zosterops habitat fragmentation experiments.
##
## Daniel Vedder, 16/02/2021
##

# NOTE: make sure to copy/symlink this to the model root folder before running

import os, sys, shutil, time, subprocess

# See `zosterops.config` for details
default_settings = {
    # input/output settings
    "outfreq":5,
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
    "tolerance":0.1
}

alternate_tolerances = [0, 0.1, 0.5, 1.0]

alternate_maps = ["taita_hills.map", "taita_hills_plantations.map",
                  "taita_hills_corridor.map", "taita_hills_deforestation.map"]

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

def write_config(config, dest, seed, simmap=None, tolerance=None):
    "Write out a config file with the given values"
    cf = open(config, 'w')
    cf.write("# GeMM Zosterops: Taita Hills study\n")
    cf.write("# This config file was generated automatically by `habitatstudy.py`.\n")
    cf.write("# "+time.asctime()+"\n")
    cf.write("\ndest "+dest+"\n")
    cf.write("seed "+str(seed)+"\n")
    for k in default_settings.keys():
        value = default_settings[k]
        if simmap != None and k == "maps": value = simmap
        if tolerance != None and k == "tolerance": value = tolerance
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

def run_hybridisation_study(seed1, seedN):
    """
    Launch a set of replicate simulations for the hybridisation study.
    Starts one run for each tolerance setting for each replicate seed from 1 to N.
    """
    print("Running "+str(seedN-seed1+1)+" replicates of the hybridisation study.")
    running_sims = []
    if default_settings["maps"] not in os.listdir():
        shutil.copy("examples/zosterops/"+default_settings["maps"], ".")
    seed = seed1
    while seed <= seedN:
        for t in alternate_tolerances:
            conf = "taita_hills_tol"+str(t)+"_"+str(seed)
            write_config(conf+".config", "results/"+conf, seed, None, t)
            sim = subprocess.Popen(["julia", "rungemm.jl", "--config", conf+".config"])
            running_sims.append(sim)
        seed = seed + 1
    for s in running_sims:
        s.wait()

def run_habitat_study(seed1, seedN):
    """
    Launch a set of replicate simulations for the habitat fragmentation study.
    Starts one run for each map scenario for each replicate seed from 1 to N.
    """
    print("Running "+str(seedN-seed1+1)+" replicates of the habitat fragmentation study.")
    running_sims = []
    seed = seed1
    while seed <= seedN:
        for m in alternate_maps:
            if m not in os.listdir():
                shutil.copy("examples/zosterops/"+m, ".")
            conf = m[:-4]+"_"+str(seed)
            write_config(conf+".config", "results/"+conf, seed, m)
            sim = subprocess.Popen(["julia", "rungemm.jl", "--config", conf+".config"])
            running_sims.append(sim)
        seed = seed + 1
    for s in running_sims:
        s.wait()

    
## USAGE OPTIONS:
## ./habitatstudy.py [archive/default]
## ./habitatstudy.py [hybrid/habitat] <seed1> <seedN>
if __name__ == '__main__':
    archive_code()
    if len(sys.argv) < 2 or sys.argv[1] == "default":
        run_default()
    elif sys.argv[1] == "archive":
        pass #only archive the code
    elif "hybrid" in sys.argv[1]:
        run_hybridisation_study(int(sys.argv[2]), int(sys.argv[3]))
    elif "habitat" in sys.argv[1]:
        run_habitat_study(int(sys.argv[2]), int(sys.argv[3]))
