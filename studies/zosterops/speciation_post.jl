"""This script is intended to do the post processing part of our speciation study
The end goal is to be able to split the .fa files according to timestep using the inds file and
the seqs file. It automatically takes the first half of the genome and concatenates it into a
"chromosome" for further analysis.
These are then loaded into a further tool (eg. FasTree)

Input parameters are the foldername of the replicate in results
Robin Rölz, 11/06/2021"""

"""
    split_fa(folder)

split the seqs.fa file in the folder according to the amount of individuals
in single fasta files to allow for post processing.
"""

using ArgParse

s = ArgParseSettings()
@add_arg_table! s begin
    "--fn", "--folderpath"
        help = "points to the results folder" #so far only puts it in wd
        arg_type = String
    "l"
        help = "genome length in genes"
        arg_type = Int
        default = 22 #current value for the Zosterops study
end

function split_fa(folderpath, n_genes)

    fa_length = n_genes*2 #number of lines the genome takes in the fasta file

    indtable = count_inds(folderpath)

    open(joinpath(folderpath, "seqs_s2.fa")) do seqs
        #iterating over the timesteps
        for n in 1:size(indtable, 1)
            outseqs = ""  
            #this is all the genes from one time step
            for m in 1:indtable[n,2]
                genome = []
                for o in 1:fa_length 
                    push!(genome, readline(seqs))
                end
                outseqs = outseqs*concat_chrs(genome)
            end

            filename_seqs = "chrs_"*string(indtable[n,1])*".fa" #labels files after the timestep
            filename_seqs = joinpath(folderpath, filename_seqs)
            open(filename_seqs, "w") do io
                write(io, outseqs)
            end
        end
    end    
end

""" 
    concat_genome(genome)

takes the genome of one individual in .fa format and takes the first half of
genes and then concatenates those into a single .fa entry such that each gene
is represented once
"""
function concat_chrs(genome)
    chrs_len = Int(length(genome)/2) #get number of genes in chromosome

    label = split(genome[1], "_") #split first line to get label
    label = join(label[1:2], "_") #label consists of species and id
    chrs = label*"\n" #the chromosome that is going to be printed

    i = 1 
    for l in genome[1:chrs_len]
        if i%2 == 0
            chrs = chrs*l
        end
        i+=1
    end
    
    return chrs*"\n"
end
"""
    count_inds(folderpath)

counts the individuals in an ind file
returns a tuple with the timestep and the number of individuals
"""

function count_inds(folderpath)
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
    return hcat(t_all, n_inds)
end

println("Starting Analysis")
arg = parse_args(s)
folderpath = arg["fn"]
n_genes = arg["l"]
println("Splitting .fa in "*folderpath)
split_fa(folderpath, n_genes)
println("Finished splitting .fa in "*folderpath)