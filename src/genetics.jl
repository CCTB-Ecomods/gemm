# Functions related to an individual's genome:
# - meiosis
# - mutation
# - genome creation
# - auxiliary functions

"""
    meiosis(genome, maternal)

Carry out meiosis on a genome (marked as maternal or not). Returns a haploid
gamete genome. (genome => array of chromosomes)
"""
function meiosis(genome::Array{Chromosome,1}, maternal::Bool, heterozygosity::Bool)
    #NOTE This function assumes that a genome is sorted, with all paternal chromosomes
    # in the first half and all maternals in the second (or vice versa).
    gametelength = Int(length(genome)/2)
    gamete = Array{Chromosome,1}(undef, gametelength)
    i = 1
    while i <= gametelength
        rand(Bool) ? g = i : g = i+gametelength
        # We do not deepcopy parental genes for performance reasons. However, that
        # means that if these genes are to be mutated, they must be deepcopied first.
        gamete[i] = heterozygosity ? LineageChromosome(genome[g].genes, maternal, genome[g].lineage) :
            DefaultChromosome(genome[g].genes, maternal)
        i += 1
    end
    gamete
end

"""
    gettraitdict(chromosomes, traitnames)

Convert a genome (an array of chromosomes) into a dict of traits and their values.
Seed size is calculated from adult size if allometric relationship is turned on.
"""
function gettraitdict(chrms::Array{Chromosome, 1}, traitnames::Array{String, 1})
    #TODO can this be made more efficient? It's called really often...
    traitdict = Dict{String, Float64}()
    traits = Array{Trait,1}()
    nchrms = 0
    ngenes = 0
    for chrm in chrms
        nchrms += 1
        for gene in chrm.genes
            ngenes += 1
            append!(traits, gene.codes)
        end
    end
    for traitidx in eachindex(traitnames)
        wantedtraits = skipmissing(map(x -> x.value, filter(x -> x.nameindex == traitidx, traits)))
        traitdict[traitnames[traitidx]] = mean(wantedtraits)
        traitdict[traitnames[traitidx] * "sd"] = std(wantedtraits)
    end
    traitdict["ngenes"] = ngenes
    traitdict["nlnkgunits"] = nchrms
    setting("allometry") && (traitdict["repsize"] = calcadltsize(traitdict["seedsize"]))
    traitdict
end

"""
    gettraitdictfast(chromosomes, traitnames)

Convert a genome (an array of chromosomes) into a dict of traits and their values.
This is an optimised version that can be run if `degpleiotropy` is 0 and `linkage` is "none".
Seed size is calculated from adult size if allometric relationship is turned on.
"""
function gettraitdictfast(chrms::Array{Chromosome, 1}, traitnames::Array{String, 1})
    # Makes use of the fact that with `degpleiotropy == 0` and `linkage == "none"`,
    # there is exactly one trait per chromosome (one gene per chromosome and one trait per gene),
    # and the chromosomes are arranged in trait-order.
    genomesize = length(chrms)
    traitdict = Dict{String, Float64}()
    haploidlength = Int(genomesize/2)
    values = Array{Float64,}(undef,genomesize)
    for c in eachindex(chrms)
        @inbounds values[c] = chrms[c].genes[1].codes[1].value
    end
    for traitidx in eachindex(traitnames)
        wantedtraits = (values[traitidx], values[traitidx+haploidlength])
        traitdict[traitnames[traitidx]] = mean(wantedtraits)
        traitdict[traitnames[traitidx] * "sd"] = std(wantedtraits)
    end
    traitdict["ngenes"] = genomesize
    traitdict["nlnkgunits"] = genomesize
    setting("allometry") && (traitdict["repsize"] = calcadltsize(traitdict["seedsize"]))
    traitdict
end

"""
    getseqsimilarity(seqone, seqtwo)

Compare two strings and return similarity.
"""
function getseqsimilarity(indgene::AbstractString, mategene::AbstractString)
    basediffs = 0
    for i in eachindex(indgene)
        try
            indgene[i] != mategene[i] && (basediffs += 1) # alternatively use bioinformatics tools
        catch # e.g., in case of differently long genes
            basediffs += 1
        end
    end
    seqidentity = 1 - (basediffs / length(indgene))
end

"""
    getseqs(genome, traitname)

Find and return the sequences of genes that code for the given trait.
"""
function getseqs(genome::Array{Chromosome, 1}, traitname::String)
    seqs = String[]
    traitidx = findfirst(x -> x == traitname, setting("traitnames"))
    for chrm in genome
        for gene in chrm.genes
            if any(x -> x.nameindex == traitidx, gene.codes)
                setting("compressgenes") ? push!(seqs, num2seq(gene.sequence)) : push!(seqs, gene.sequence)
            end
        end
    end
    seqs
end

"""
    iscompatible(mate, individual)

Check to see whether two individual organisms are reproductively compatible by
comparing gene sequences (which sequence depends on setting("speciation")).
"""
function iscompatible(mate::Individual, ind::Individual)
    mate.lineage != ind.lineage && return false
    indgenes, mategenes = "", ""
    if setting("speciation") == "off"
        return true # all conspecifics are compatible, no speciation can happen
    elseif setting("speciation") == "neutral"
        # default, use a non-coding sequence for mutation-order speciation
        indgenes = join(getseqs(ind.genome, "compat"))
        mategenes = join(getseqs(mate.genome, "compat"))
    elseif setting("speciation") == "ecological"
        # use all coding sequences for ecological speciation
        for tr in setting("traitnames")
            (tr == "compat") && continue
            indgenes *= join(getseqs(ind.genome, tr))
            mategenes *= join(getseqs(mate.genome, tr))
        end
    end
    seqidentity = getseqsimilarity(indgenes, mategenes)
    seqidentity >= ind.traits["seqsimilarity"]
end

"""
    seq2num(sequence)

Convert a DNA base sequence (a string) into binary and then into an integer.
This saves memory.
"""
#XXX Actually, this hardly seems to make a difference :-(
function seq2num(sequence::String)
    # This function effectively uses the same technique as seq2bignum, but it skips the
    # intermediate allocations and should therefore be more efficient.
    num::Int64 = 0  # Int64 allows for max length of 21bp
    for b in eachindex(sequence)
        if sequence[end+1-b] == 'a'
            num += 2^(3*(b-1)) * 4 # b'100'
        elseif sequence[end+1-b] == 'c'
            num += 2^(3*(b-1)) * 5 # b'101'
        elseif sequence[end+1-b] == 'g'
            num += 2^(3*(b-1)) * 6 # b'110'
        elseif sequence[end+1-b] == 't'
            num += 2^(3*(b-1)) * 7 # b'111'
        end
    end
    num
end

function intseq(n::Int)
    #XXX doesn't seem to work either? I'm starting to think I'm optimising in the wrong place :-(
    num::Int64 = 0  # Int64 allows for max length of 21bp
    for b in 0:(n-1)
        # basically like seq2bignum(), but skips all intermediate allocations
        num += 2^(3*b) * rand(4:7)
    end
    num
end

"""
    seq2bignum(sequence)

Convert a DNA base sequence (a string) into binary and then into a BigInt (for
larger genes). This saves memory.
"""
function seq2bignum(sequence::String)
    bases = "acgt"
    binary = ""
    for base in sequence
        binary *= string(findfirst(x -> x == base, bases) + 3, base = 2)
    end
    parse(BigInt, binary, base = 2) # BigInt allows arbitrary-length sequences
end

"""
    num2seq(n)

Convert an integer into binary and then into a DNA base sequence string.
"""
function num2seq(n::Integer)
    bases = "acgt"
    binary = string(n, base = 2)
    sequence = ""
    for i in 1:3:(length(binary) - 2)
        sequence *= string(bases[parse(Int, binary[i:(i + 2)], base = 2) - 3])
    end
    sequence
end

"""
    createtraits()

Create an array of trait objects generated from the default trait values (with a
random offset).
"""
function createtraits()
    #XXX this is all very ugly. (case/switch w/ v. 2.0+?)
    traitnames = setting("traitnames")
    traits = Array{Trait,1}(undef,length(traitnames))
    # exponential distributions of body sizes:
    repoffset = setting("maxrepsize") - setting("minrepsize")
    seedoffset = setting("maxseedsize") - setting("minseedsize")
    tempoffset = setting("maxtemp") - setting("mintemp")
    precoffset = setting("maxprec") - setting("minprec")
    #FIXME this needs to be changed to account for allometric relationships
    repsize, seedsize = 0, 0
    while true 
        repsize = exp(setting("minrepsize") + repoffset * rand())
        seedsize = exp(setting("minseedsize") + seedoffset * rand())
        repsize > seedsize && break
    end
    for idx in eachindex(traitnames)
        if occursin("dispshape", traitnames[idx])
            traits[idx] = Trait(idx, rand() * setting("dispshape"))
        elseif occursin("dispmean", traitnames[idx])
            traits[idx] = Trait(idx, rand() * setting("dispmean"))
        elseif occursin("precopt", traitnames[idx])
            traits[idx] = Trait(idx, setting("minprec") + rand() * precoffset)
        elseif occursin("prectol", traitnames[idx])
            traits[idx] = Trait(idx, rand() * setting("maxbreadth"))
        elseif occursin("repsize", traitnames[idx])
            traits[idx] = Trait(idx, repsize)
        elseif occursin("seqsimilarity", traitnames[idx]) && setting("fixtol")
            traits[idx] = Trait(idx, setting("tolerance"))
        elseif occursin("seqsimilarity", traitnames[idx]) && !setting("fixtol")
            traits[idx] = Trait(idx, rand()) # assortative mating might evolve
        elseif occursin("seedsize", traitnames[idx])
            traits[idx] = Trait(idx, seedsize)
        elseif occursin("tempopt", traitnames[idx])
            traits[idx] = Trait(idx, setting("mintemp") + rand() * tempoffset)
        elseif occursin("temptol", traitnames[idx])
            traits[idx] = Trait(idx, rand() * setting("maxbreadth"))
        else
            traits[idx] = Trait(idx, rand())
        end
    end
    traits
end

"""
    creategenes(ngenes, traits)

Randomly create a given number of gene objects, with their base sequence and
associated traits. Returns the result as an array of AbstractGenes.
"""
function creategenes(ngenes::Int, traits::Array{Trait,1})
    genes = Array{AbstractGene,1}(undef, ngenes)
    bases = ['a','c','g','t']
    compatidx = findfirst(x -> x == "compat", setting("traitnames"))
    # initialise each gene with an arbitrary sequence
    for i in 1:ngenes
        if setting("compressgenes") #default
            genes[i] = Gene(intseq(setting("smallgenelength")), Trait[])
        else
            sequence = String(rand(bases, setting("smallgenelength")))
            genes[i] = StringGene(sequence, Trait[])
        end
    end
    # assign traits to the genes
    if setting("degpleiotropy") == 0
        # Disable polygenic inheritance and pleiotropy: make sure one gene codes for one trait.
        for tr in eachindex(traits)
            (tr == compatidx) && (genes[tr] = createcompatgene(bases, compatidx))
            genes[tr].codes = [traits[tr]]
        end
    else # allow for pleiotropy as well as polygenic inheritance
        for trait in traits
            (trait.nameindex == compatidx) && continue
            # We're actually setting polygenic inheritance here, rather than pleiotropy.
            # Pleiotropy is introduced indirectly, because a higher number of coding genes
            # increases the likelihood of picking a gene that already codes for other traits.
            ncodinggenes = rand(Geometric(1 - setting("degpleiotropy"))) + 1
            codinggenes = rand(genes,ncodinggenes)
            for gene in codinggenes
                push!(gene.codes,deepcopy(trait))
            end
        end
        push!(genes, createcompatgene(bases, compatidx))
    end
    genes
end

"""
    createcompatgene(bases, compatidx)

Create the gene that is used to determine reproductive compatibility.
"""
function createcompatgene(bases::Array{Char,1}, compatidx::Int)::AbstractGene
    # Note: we only need big genes for the compatibility gene, because we need a longer base
    # sequence than offered by `smallgenelength` if we want to do phylogenetic analyses.
    setting("usebiggenes") ? seql = setting("biggenelength") : seql = setting("smallgenelength")
    cseq = String(rand(bases, seql))
    ctrait = [Trait(compatidx, 0.5)]
    if setting("compressgenes")
        if setting("usebiggenes")
            return BigGene(seq2bignum(cseq), ctrait)
        else
            return Gene(seq2num(cseq), ctrait)
        end
    else
        return StringGene(cseq, ctrait)
    end
end

"""
    createchrms(nchrms, genes)

Randomly distribute the passed genes into the given number of haploid chromosomes.
Returns a diploid genome (array of chromosome objects).
"""
function createchrms(nchrms::Int,genes::Array{AbstractGene,1},lineage::String)::Array{Chromosome,1}
    chromosomes = Array{Chromosome,1}(undef,nchrms*2)
    if nchrms == 1 # linkage == "full"
        chromosomes[1] = @Chromosome(genes, true, lineage)
        chromosomes[2] = @Chromosome(deepcopy(genes),false, lineage)
    elseif nchrms == length(genes) # linkage == "none"
        for g in eachindex(genes)
            chromosomes[g] = @Chromosome([genes[g]], true, lineage)
            chromosomes[nchrms+g] = @Chromosome([deepcopy(genes[g])], false, lineage)
        end
    else # linkage == "random"
        chrmsplits = sort(rand(1:length(genes), nchrms-1))
        for chr in 1:nchrms
            if chr==1 # first chromosome
                cgenes = genes[1:chrmsplits[chr]]
            elseif chr==nchrms # last chromosome
                cgenes = genes[(chrmsplits[chr-1]+1):end]
            else
                cgenes = genes[(chrmsplits[chr-1]+1):chrmsplits[chr]]
            end
            chromosomes[chr] = @Chromosome(cgenes, true, lineage)
            chromosomes[nchrms+chr] = @Chromosome(deepcopy(cgenes), false, lineage)
        end
    end
    chromosomes
end

"""
    varyalleles!(genes, locivar)

Mutate gene traits in the passed array of genes.
"""
function varyalleles!(genes::Array{AbstractGene, 1}, locivar::Float64)
    locivar == 0 && return
    for gene in genes
        mutate!(gene.codes, locivar)
    end
end

"""
    varyalleles!(chromosomes, locivar)

Mutate gene traits in the passed array of chromosomes.
"""
function varyalleles!(chrms::Array{Chromosome, 1}, locivar::Float64)
    locivar == 0 && return
    for chrm in chrms
        varyalleles!(chrm.genes, locivar)
    end
end

"""
    mutate!(traits, locivar)

Loop over an array of traits, mutating each value in place along a normal distribution.
`locivar` can be used to scale the variance of the normal distribution used to draw new
trait values (together with `setting(phylconstr]`).
"""
function mutate!(traits::Array{Trait, 1}, locivar::Float64 = 1.0)
    setting("phylconstr") * locivar == 0 && return
    for trait in traits
        traitname = setting("traitnames")[trait.nameindex]
        occursin("seqsimilarity", traitname) && setting("fixtol") && continue
        oldvalue = trait.value
        occursin("tempopt", traitname) && (oldvalue -= 273)
        while oldvalue <= 0 # make sure sd of Normal dist != 0
            oldvalue = abs(rand(Normal(0,0.01)))
        end
        newvalue = rand(Normal(oldvalue, oldvalue * setting("phylconstr") * locivar))
        #FIXME there are no traits with "prob" in their name?!
        # Is this meant to cap compat/seqsimilarity/selfing?
        (newvalue > 1 && occursin("prob", traitname)) && (newvalue=1.0)
        while newvalue <= 0
            newvalue = rand(Normal(oldvalue, oldvalue * setting("phylconstr") * locivar))
        end
        occursin("tempopt", traitname) && (newvalue += 273)
        trait.value = newvalue
    end
end

"""
    mutate!(individual, temp)

Mutate an individual's genome (sequence and traits) in place.
"""
function mutate!(ind::Individual, temp::Float64)
    muts = setting("mutationrate") * exp(-act/(boltz*temp))
    nmuts = rand(Poisson(muts))
    nmuts == 0 && return
    chrmidcs = rand(eachindex(ind.genome), nmuts)
    for c in chrmidcs
        # We need to deepcopy genes here, because they are not automatically deepcopied during
        # reproduction for performance reasons
        ind.genome[c] = deepcopy(ind.genome[c])
        length(ind.genome[c].genes) == 0 && continue
        g = rand(eachindex(ind.genome[c].genes))
        gseq = ind.genome[c].genes[g].sequence
        setting("compressgenes") ? charseq = collect(num2seq(gseq)) : charseq = collect(gseq)
        i = rand(eachindex(charseq))
        newbase = rand(collect("acgt"),1)[1]
        while newbase == charseq[i]
            newbase = rand(collect("acgt"),1)[1]
        end
        charseq[i] = newbase
        mutate!(ind.genome[c].genes[g].codes)
        if setting("compressgenes")
            if length(charseq) > 21
                ind.genome[c].genes[g].sequence = seq2bignum(String(charseq))
            else
                ind.genome[c].genes[g].sequence = seq2num(String(charseq))
            end
        else
            ind.genome[c].genes[g].sequence = String(charseq)
        end
    end
    if setting("degpleiotropy") == 0 && setting("linkage") == "none"
        ind.traits = gettraitdictfast(ind.genome, setting("traitnames"))
    else
        ind.traits = gettraitdict(ind.genome, setting("traitnames"))
    end
end

"""
    mutate!(patch)

Mutate all seed individuals in a patch.
"""
function mutate!(patch::Patch)
    setting("mode") == "zosterops" ? temp = setting("bodytemp") : temp = patch.temp
    for ind in patch.seedbank
        mutate!(ind, temp)
    end
end

"""
    mutate!(world)

Mutate the world. (That sounds scary!)
"""
function mutate!(world::Array{Patch, 1})
    for patch in world
        (patch.isisland || !setting("static")) && mutate!(patch)
    end
end
