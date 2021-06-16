"""This script is intended to do the post processing part of our speciation study
The end goal is to be able to split the .fa files according to timestep using the inds file and
the seqs file. 
Additional goal (will this be in this script, I don't know) is to recreate the individuals genetically
and try and cluster them into species.

Input parameters are the foldername of the replicate in results
Robin Rölz, 11/06/2021"""

"""
    split_fa(folder)

split the seqs.fa file in the folder according to the amount of individuals
in single fasta files to allow for post processing.
"""

function split_fa(folderpath)
    #individuals in each timestep
    #count the amount of individuals in each timestep
    n_inds = []
    i=0
    first = true
    t_index = String
    t_all = []
    for line in eachline(joinpath(folderpath, "indcoord_s2.tsv"))
        if first == true 
            first = false
            continue
        end
        t = split(line, "\t")[1] #this gets me the time
        if t != t_index #is this a new time index?
            t_index = t #set new indexed timestep
            push!(t_all, t_index) #collect all t
            i+=1 # increment counter
            push!(n_inds, 0) #make a new space at the end of the n_vector
        end
        n_inds[i] +=1
    end
    i = 1 #set i to 1 to allow for naming of the files
    open(joinpath(folderpath, "seqs_s2.fa")) do seqs
        for n in n_inds  
            filename_seqs = "seqs_s2_"*string(t_all[i])*".fa"
            i+=1  
            filename_seqs = joinpath(folderpath, filename_seqs)
            open(filename_seqs, "w") do outseqs 
                for line in 1:n*22 #it's 22 here because there's 22 chromosomes per individual
                    print(outseqs, readline(seqs)*"\n") 
                end
            end
        end
    end    
end