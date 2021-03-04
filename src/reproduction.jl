# All functions related to reproduction.

"""
    reproduce!(patch)

Reproduction of individuals in a patch (default function).
"""
function reproduce!(patch::Patch) #TODO: refactor!
    #TODO This is one of the most compute-intensive functions in the model - optimise?
    for ind in patch.community
        ind.marked && continue # individual might not have established yet
        ind.size < ind.traits["repsize"] && continue
        metaboffs = setting("fertility") * ind.size^(-1/4) * exp(-act/(boltz*patch.temp))
        noffs = rand(Poisson(metaboffs))
        noffs < 1 && continue
        partners = findmate(patch.community, ind)
        if length(partners) < 1 && rand() < ind.traits["selfing"]
            partners = [ind]
        elseif length(partners) < 1
            continue
        end
        numpartners = Integer(round(ind.traits["numpollen"]))
        if numpartners == 0
            #XXX happens really often?
            # `numpollen` not handled specifically in `createtraits()`?
            @simlog("Individual cannot reproduce, `numpollen` too low.", 'd')
            continue
        end
        for ptn in 1:numpartners
            partner = rand(partners)
            # subtract offspring mass from parent #XXX is that sensible, does it make a difference?
            parentmass = ind.size - noffs * ind.traits["seedsize"]
            if parentmass <= 0
                break
            else
                ind.size = parentmass
            end
            append!(patch.seedbank, createoffspring(noffs, ind, partner))
        end
    end
    @simlog("Patch $(patch.id): $(length(patch.seedbank)) offspring", 'd')
end

"""
    greproduce!(patch)

Reproduction of individuals in a patch with global mating.
"""
function greproduce!(patch::Patch)
    for ind in patch.community
        ind.marked && continue # individual might not have established yet
        ind.size < ind.traits["repsize"] && continue
        metaboffs = setting("fertility") * ind.size^(-1/4) * exp(-act/(boltz*patch.temp))
        noffs = rand(Poisson(metaboffs))
        noffs < 1 && continue
        partners = findmate([(map(x -> x.community, world)...)...], ind)
        if length(partners) < 1 && rand() < ind.traits["selfing"]
            partners = [ind]
        elseif length(partners) < 1
            continue
        end
        numpartners = Integer(round(ind.traits["numpollen"]))
        for ptn in 1:numpartners
            partner = rand(partners, 1)[1]
            parentmass = ind.size - noffs * ind.traits["seedsize"] # subtract offspring mass from parent
            if parentmass <= 0
                continue
            else
                ind.size = parentmass
            end
            append!(patch.seedbank, createoffspring(noffs, ind, partner))
        end
    end
    @simlog("Patch $(patch.id): $(length(patch.seedbank)) offspring", 'd')
end

"""
    reproduce!(world)

Carry out reproduction on all patches.
"""
function reproduce!(world::Array{Patch,1})
    for patch in world
        if setting("globalmating")
            greproduce!(patch)
        else
            (patch.isisland || !setting("static")) && reproduce!(patch) # pmap(!,patch) ???
        end
    end
end

"""
    findmate(population, individual)

Find a reproduction partner for the given individual in the given population.
"""
function findmate(population::AbstractArray{Individual, 1}, ind::Individual)
    #XXX This function is pretty expensive
    indstate = ind.marked
    ind.marked = true
    mates = Individual[]
    startidx = rand(eachindex(population))
    mateidx = startidx
    while true
        mate = population[mateidx]
        if !mate.marked && iscompatible(mate, ind)
            push!(mates, mate)
            break
        end
        mateidx += 1
        mateidx > length(eachindex(population)) && (mateidx = 1)
        mateidx == startidx && break
    end
    ind.marked = indstate
    mates
end

"""
    createoffspring(noffs, individual, partner, dimorphism)

The main reproduction function. Take two organisms and create the given number
of offspring individuals. Returns an array of individuals.
"""
function createoffspring(noffs::Integer, ind::Individual, partner::Individual, dimorphism::Bool=false)
    #TODO This is a very compute-intensive function - optimise?
    offspring = Individual[]
    heterozygosity = setting("heterozygosity")
    for i in 1:noffs # pmap? this loop could be factorized!
        # offspring have different genomes due to recombination
        partnergenome = meiosis(partner.genome, false, partner.lineage, heterozygosity)
        mothergenome = meiosis(ind.genome, true, ind.lineage, heterozygosity)
        (isempty(partnergenome) || isempty(mothergenome)) && continue
        genome = vcat(partnergenome,mothergenome)
        if setting("degpleiotropy") == 0 && setting("linkage") == "none"
            traits = gettraitdictfast(genome, setting("traitnames"))
        else
            traits = gettraitdict(genome, setting("traitnames"))
        end
        marked = true
        fitness = 0.0
        newpartner = 0
        newsize = ind.traits["seedsize"]
        newid = rand(UInt32) #XXX Is this collision-safe?
        sex = hermaphrodite
        if dimorphism
            rand(Bool) ? sex = male : sex = female
        end
        lineage = ind.lineage
        if lineage != partner.lineage
            # hybrids are assigned the lineage of the parent they are phenotypically most similar to
            idiff = sum(t -> abs(traits[t]-ind.traits[t]), keys(traits))
            pdiff = sum(t -> abs(traits[t]-partner.traits[t]), keys(traits))
            (pdiff < idiff) && (lineage = partner.lineage)
        end
        push!(offspring, Individual(lineage, genome, traits, marked, fitness,
                                    fitness, newsize, sex, newpartner, newid))
    end
    offspring
end
