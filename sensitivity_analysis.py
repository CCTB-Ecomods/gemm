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
    "outfreq":100,
    "fastaoutfreq":1000,
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
    "perfecttol":10.0,
    # species parameters
    "species":'[Dict("lineage"=>"archetype","precopt"=>20,"prectol"=>20,"tempopt"=>293,"temptol"=>2)]',
    "traitnames":'["compat","dispmean","dispshape","numpollen","precopt","prectol","repsize","seqsimilarity","seedsize","tempopt","temptol"]',
    # variable parameters
    "speciation":"ecological"
}

alternate_speciations = ["ecological","neutral"]
alternate_perfecttol=[5.0, 15.0]
alternate_phylconstr=[0.01, 0.05]
alternate_mutationrate=[2.5e6, 2.5e8, 2.5e10]
alternate_dispmean=[14,16,20]
alternate_dispshape=[1.0, 1.5, 2.5, 3.0]
alternate_tolerance=[0.6, 0.4]

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
    cf.write("# This config file was generated automatically by `sensitivity_analysis.py`.\n")
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

        
def run_sensitivity_analysis(seed1, seedN):
    """
    Launch a set of replicate simulations for the trait space experiment.
    Starts one run for each speciation scenario for each replicate seed from 1 to N.
    """
    print("Running "+str(seedN-seed1+1)+" replicates of the trait space exploration experiment.")
    running_sims = []
    seed = seed1
    species_no=0
    shutil.copy("/home/charlotte/Zosterops/gemm/studies/zosterops/Phylogeny_study/Chyulu_Taita_Maps2/Chyulu_025.map", ".")
    while seed <= seedN:
        for s in alternate_speciations:
            for pt in alternate_perfecttol:
                for pc in alternate_phylconstr:
                    for m in alternate_mutationrate:
                        for dm in alternate_dispmean:
                            for ds in alternate_dispshape:
                                for t in alternate_tolerance:
                                    conf = str(s)+"_"+str(seed)+"_phyl"+str(pc)+"_pertol"+str(pt)+"_mutate"+str(m)+"_dispm"+str(dm)+"_dispsh"+str(ds)+"_comtol"+str(t)
                                    write_config(conf+".config", "results/"+conf, seed, speciation=m, perfecttol=pt, phylconstr=pc, mutationrate=m, dispmean=dm, dispshape=ds, tolerance=t)
                                    sim = subprocess.Popen(["julia", "rungemm.jl", "--config", conf+".config"])
                                    running_sims.append(sim)
        seed = seed + 1
    for s in running_sims:
        s.wait()

## RUNTIME SCRIPT
        
## USAGE OPTIONS:
## ./habitatstudy.py [archive/default]
## ./habitatstudy.py [tolerance/habitat/mutation/linkage/phylogeny/traitspace] <seed1> <seedN> [tolerance]
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
    elif sys.argv[1] == "traitspace":
        run_traitspace_experiment(int(sys.argv[2]), int(sys.argv[3]))    
    elif sys.argv[1] == "sensitivity":
        run_sensitivity_analysis(int(sys.argv[2]), int(sys.argv[3]))     
        
