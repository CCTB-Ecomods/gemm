#!/usr/bin/python3
##
## A script for setting up a folder with experiment configuration files to then be slurmed or run
## Robin Rölz 01/12/2022

# NOTE: make sure to copy/symlink this to the model root folder before running

import os, sys, shutil, time, subprocess

## PARAMETERS AND VARIABLES

# See `zosterops.config` for details
default_settings = {
    # input/output settings
    "maps":"Chyulu_25.map",
    "outfreq":1000,
    "fastaoutfreq":10000,
    "logging":"true",
    "debug":"false",
    "stats":"true",
    "lineages":"true",
    "fasta":"all",
    "raw":"false",
    "dumpindforfasta":"true",
    # general model parameters
    "linkage":"none",
    "nniches":2,
    "static":"false",
    "mutate":"true",
    "phylconstr":0.1,
    "mutationrate":"2.5e9",
    "usebiggenes":"true",
    "compressgenes":"false",
    "indsize":"adult",
    "capgrowth":"true",
    "degpleiotropy":0,
    # Zosterops-specific parameters
    "mode":"zosterops",
    "tolerance":0.3,
    "perfecttol":10.0,
    "bodytemp":313.0,
    "cellsize":8,
    "fertility":2,
    "dispmean":20,
    "dispshape":2,
    "dispfactor":20,
    "dispmortality":"true", 
    "maxrepsize":2.5,
    "minrepsize":2.3,
    "maxtemp":303,
    "mintemp":283,
    "mortalitytype":"habitat",
    "mortality":0.125,
    "heterozygosity":"true",
    # species parameters
    "species":'[Dict("lineage"=>"archetype","precopt"=>10,"prectol"=>10,"tempopt"=>293,"temptol"=>2)]',
    "traitnames":'["compat","dispmean","dispshape","numpollen","precopt","prectol","repsize","seqsimilarity","seedsize","tempopt","temptol"]',
    "traitsforecospec":'["dispmean","dispshape","precopt","prectol"]',
    # variable parameters
    "speciation":"ecological"
}

alternate_speciations = ["ecological","neutral"]
slope_map = "maptest.map"
chyulu_src = "studies/zosterops/Phylogeny_study/Chyulu_Taita_Maps"
chyulu_maps = [
    "Chyulu_25.map",
    "Chyulu_50.map",
    "Chyulu_75.map",
    "Chyulu_100.map",
    "Chyulu_125.map",
    "Chyulu_150.map",
    "Chyulu_175.map",
    "Chyulu_200.map",
    "Chyulu_225.map",
    "Chyulu_250.map",
    "Chyulu_275.map",
    "Chyulu_300.map",
    "Chyulu_325.map",
    "Chyulu_350.map",
    "Chyulu_350.map",
    "Chyulu_375.map",
    "Chyulu_400.map",
    "Chyulu_425.map",
    "Chyulu_450.map",
    "Chyulu_475.map",
    "Chyulu_500.map",
    "Chyulu_525.map",
    "Chyulu_550.map",
    "Chyulu_575.map",
    "Chyulu_600.map",
    "Chyulu_625.map",
    "Chyulu_650.map",
    "Chyulu_675.map",
    "Chyulu_700.map",
    "Chyulu_725.map",
    "Chyulu_750.map"
]


## AUXILIARY FUNCTIONS

def archive_code(experiment_folder = "."):
    
    if experiment_folder == "":
        raise ValueError("Please enter an appropriate name for a folder")

    "Save the current codebase in a tar archive."
    tarname = time.strftime(experiment_folder+"/GeMM_source_%d%b%y.tar.gz")
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
    cf.write("# This config file was generated automatically by `phyloslurm.py`.\n")
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
    shutil.copy("studies/zosterops/Phylogeny_study/Chyulu_Taita_Maps/Chyulu_25.map", ".")
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
## def setup_experiment(configs)

def setup_experiment(expname, seed1, seedN, maps, mapsource):
    """
    Create a set of configuration files for the phylogenetic experiment
    Creates one folder for all the configurations and to be then run with a batch script
    """
    exp = "exp_"+expname
    print("Creating configs for "+str(seedN-seed1+1)+" replicates of the phylogeny experiment in "+exp+"/.")
    os.mkdir(exp)

    archive_code(experiment_folder=exp)
    
    seed = seed1

    #copy maps into gemm working directory (makes easier to load in)
    for m in maps:
        full_file_name = os.path.join(mapsource, m)
        if os.path.isfile(full_file_name):
            shutil.copy(full_file_name, ".")
        else:
            raise FileNotFoundError(full_file_name+" not found")

    mapstring = "\""+",".join(maps)+"\""

    #Create Configuration files
    while seed <= seedN:
        for m in alternate_speciations:
            conf = expname+"_"+str(m)+"_"+str(seed)
            write_config(exp+"/"+conf+".config", "results/"+exp+"/"+conf, seed, speciation=m, maps=mapstring)
        seed = seed + 1



def setup_chyulu_experiment(seed1, seedN, maps=chyulu_maps):
    """
    Launch a set of replicate simulations for the Chyulu-Taita phylogeny experiment.
    Starts one run for each speciation scenario for each replicate seed from 1 to N.
    """
    print("Running "+str(seedN-seed1+1)+" replicates of the phylogeny experiment.")
    running_sims = []
    seed = seed1
    
   # dir_src = ("/studies/zosterops/Chyulu_Taita_Maps/")
   # dir_dst = (' .')

   # for filename in os.listdir(dir_src):
    #    if filename.endswith('.map'):
     #       shutil.copy( dir_src + filename, dir_dst)
      #      print(filename)
    source = ("studies/zosterops/Phylogeny_study/Chyulu_Taita_Maps/")
    #destination = " . "
    for files in os.listdir(source):
        full_file_name = os.path.join(source, files)
        if full_file_name.endswith(".map"):
            shutil.copy(full_file_name, ".")
    while seed <= seedN:
        for m in alternate_speciations:
            conf = "savannah"+"_"+str(m)+"_"+str(seed)
            write_config(conf+".config", "results/"+conf, seed, speciation=m, maps=all_maps)
            sim = subprocess.Popen(["julia", "rungemm.jl", "--config", conf+".config"])
            running_sims.append(sim)
        seed = seed + 1
    for s in running_sims:
        s.wait()

## RUNTIME SCRIPT
        
## USAGE OPTIONS:
## ./habitatstudy.py [archive/default]
## ./habitatstudy.py [chyulu] <seed1> <seedN>
if __name__ == '__main__':
    if len(sys.argv) < 2 or sys.argv[1] == "default":
        archive_code()
        run_default()
    else:
        setup_experiment(expname=sys.argv[1], 
        seed1=int(sys.argv[2]), 
        seedN=int(sys.argv[3]),
        maps=chyulu_maps,
        mapsource=chyulu_src
        )