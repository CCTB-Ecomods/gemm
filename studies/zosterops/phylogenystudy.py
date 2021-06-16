#!/usr/bin/python3
##
## A script to set up and launch the Zosterops phylogeny experiments.
##
## following the script from Daniel Vedder, 16/02/2021
## Charlotte Sieger, 14/05/2021

# NOTE: make sure to copy/symlink this to the model root folder before running

import os, sys, shutil, time, subprocess

## PARAMETERS AND VARIABLES

# See `zosterops.config` for details
default_settings = {
    # input/output settings
    "maps":"Chyulu_025.map",
    "outfreq":1000,
    "fastaoutfreq":5000,
    "logging":"true",
    "debug":"false",
    "stats":"true",
    "lineages":"true",
    "fasta":"all",
    "raw":"false",
    # general model parameters
    "linkage":"none",
    "nniches":2,
    "static":"false",
    "mutate":"true",
    "phylconstr":0.1,
    "mutationrate":"2.5e11",
    "usebiggenes":"true",
    "compressgenes":"false",
    "indsize":"adult",
    "capgrowth":"true",
    "degpleiotropy":0,
    # Zosterops-specific parameters
    "mode":"zosterops",
    "tolerance":0.1,
    "bodytemp":313.0,
    "cellsize":8,
    "fertility":2,
    "dispmean":18,
    "dispshape":2,
    "maxrepsize":2.5,
    "minrepsize":2.3,
    "maxtemp":303,
    "mintemp":283,
    "mortalitytype":"habitat",
    "mortality":0.125,
    "heterozygosity":"true",
    # species parameters
    "species":'[Dict("lineage"=>"archetype","precopt"=>20,"prectol"=>20,"tempopt"=>293,"temptol"=>2)]',
    "traitnames":'["compat","dispmean","dispshape","numpollen","precopt","prectol","repsize","seqsimilarity","seedsize","tempopt","temptol"]',
    # variable parameters
    "speciation":"ecological"
}

alternate_speciations = ["ecological","neutral"]
all_maps = "Chyulu_025.map,Chyulu_050.map,Chyulu_075.map,Chyulu_100.map,Chyulu_125.map,Chyulu_150.map,Chyulu_175.map,Chyulu_200.map,Chyulu_225.map,Chyulu_250.map,Chyulu_275.map,Chyulu_300.map,Chyulu_325.map,Chyulu_350.map,Chyulu_350.map,Chyulu_375.map,Chyulu_400.map,Chyulu_425.map,Chyulu_450.map,Chyulu_475.map,Chyulu_500.map,Chyulu_525.map,Chyulu_550.map,Chyulu_575.map,Chyulu_600.map,Chyulu_625.map,Chyulu_650.map,Chyulu_675.map,Chyulu_700.map,Chyulu_725.map,Chyulu_750.map"


## AUXILIARY FUNCTIONS

def archive_code():
    "Save the current codebase in a tar archive."
    tarname = time.strftime("GeMM_source_%d%b%y.tar.gz")
    print("Archiving codebase in "+tarname)
    os.system("git log -1 > current_commit.txt")
    cmd = "tar czhf " + tarname + " README.md current_commit.txt rungemm.jl src/* " +\
        "studies/zosterops/*.py studies/zosterops/*.R studies/zosterops/*.map " +\
        "studies/zosterops/*.config"
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
    shutil.copy("studies/zosterops/Chyulu_Taita_Maps/Chyulu_025.map", ".")
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

        
def run_phylogeny_experiment(seed1, seedN, maps=all_maps):
    """
    Launch a set of replicate simulations for the phylogeny experiment.
    Starts one run for each speciation scenario for each replicate seed from 1 to N.
    """
    print("Running "+str(seedN-seed1+1)+" replicates of the habitat fragmentation experiment.")
    running_sims = []
    seed = seed1
    
   # dir_src = ("/studies/zosterops/Chyulu_Taita_Maps/")
   # dir_dst = (' .')

   # for filename in os.listdir(dir_src):
    #    if filename.endswith('.map'):
     #       shutil.copy( dir_src + filename, dir_dst)
      #      print(filename)
    source = ("/home/charlotte/Zosterops/gemm/studies/zosterops/Chyulu_Taita_Maps/")
    #destination = " . "
    for files in os.listdir(source):
        full_file_name = os.path.join(source, files)
        if full_file_name.endswith(".map"):
            shutil.copy(full_file_name, ".")
    while seed <= seedN:
        for m in alternate_speciations:
            conf = "phyl"+"_"+str(m)+"_"+str(seed)
            write_config(conf+".config", "results/"+conf, seed, speciation=m, maps=all_maps)
            sim = subprocess.Popen(["julia", "rungemm.jl", "--config", conf+".config"])
            running_sims.append(sim)
        seed = seed + 1
    for s in running_sims:
        s.wait()

## RUNTIME SCRIPT
        
## USAGE OPTIONS:
## ./habitatstudy.py [archive/default]
## ./habitatstudy.py [tolerance/habitat/mutation/linkage/phylogeny] <seed1> <seedN> [tolerance]
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
    elif sys.argv[1] == "phylogeny":
        run_phylogeny_experiment(int(sys.argv[2]), int(sys.argv[3]))    
