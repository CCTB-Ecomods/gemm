# initialisation functions for GeMM

function genesis(settings::Dict{String, Any})
    community = Individual[]
    totalmass = 0.0
    ttl = 50
    while true
        # Create a new species and calculate its population size
        newind = createind(settings)
        if occursin("metabolic", settings["initpopsize"]) || occursin("single", settings["initpopsize"])
            # population size determined by adult size and temperature niche optimum
            popsize = round(fertility * newind.traits["repsize"]^(-1/4) *
                            exp(-act/(boltz*newind.traits["tempopt"])))
        elseif occursin("bodysize", settings["initpopsize"])
            # population size up to 25% of the maximum possible in this cell
            quarterpopsize = Integer(floor((settings["cellsize"] / newind.traits["repsize"]) / 4))
            popsize = rand(0:quarterpopsize)
        elseif occursin("minimal", settings["initpopsize"])
            popsize = 2 #Takes two to tangle ;-) #XXX No reproduction occurs!
        else
            simlog("Invalid value for `initpopsize`: $(settings["initpopsize"])", settings, 'e')
        end
        # prevent an infinity loop when the cellsize is very small
        if popsize < 2
            if ttl == 0
                simlog("This cell might be too small to hold a community.", settings, 'w')
                break
            else
                ttl -= 1
                continue
            end
        end
        # Check the cell capacity
        popmass = popsize * newind.size
        if totalmass + popmass > settings["cellsize"] # stop loop if cell is full
            if totalmass >= settings["cellsize"]*0.75 || occursin("single", settings["initpopsize"]) #make sure the cell is full enough
                simlog("Cell is now $(round((totalmass/settings["cellsize"])*100))% full.", settings, 'd') #DEBUG
                break
            else
                continue
            end
        end
        # Initialize the new population
        totalmass += popmass
        simlog("Initializing lineage $(newind.lineage) with $popsize individuals.", settings, 'd') #DEBUG
        for i in 1:popsize
            !settings["static"] && (newind = deepcopy(newind))
            push!(community, newind)
        end
        occursin("single", settings["initpopsize"]) && break
    end
    simlog("Patch initialized with $(length(community)) individuals.", settings, 'd') #DEBUG
    community
end

function createworld(maptable::Array{Array{String,1},1}, settings::Dict{String, Any})
    simlog("Creating world...", settings)
    world = Patch[]
    for entry in maptable
        size(entry,1) < 3 && simlog("please check your map file for incomplete or faulty entries. \n
Each line must contain patch information with at least \n
\t - a unique integer ID, \n
\t - an integer x coordinate, \n
\t - an integer y coordinate, \n
separated by a whitespace character (<ID> <x> <y>).", settings, 'e')
        # create the basic patch
        id = parse(Int, entry[1])
        xcord = parse(Int, entry[2])
        ycord = parse(Int, entry[3])
        area = settings["cellsize"]
        simlog("Creating patch $id at $xcord/$ycord, size $area", settings, 'd') #DEBUG
        # XXX the 'global' here is a hack so that I can use eval() later on
        # (this always works on the global scope)
        global newpatch = Patch(id, (xcord, ycord), area)
        # parse other parameter options
        for p in entry[4:end]
            varval = split(p, '=')
            var = varval[1]
            if !(var in map(string, fieldnames(Patch)))
                simlog("Unrecognized patch parameter $var.", settings, 'w')
                continue
            elseif length(varval) < 2
                val = true # if no value is specified, assume 'true'
            else
                val = parse(varval[2])
            end
            # check for correct type and modify the new patch
            vartype = typeof(eval(parse("newpatch."*var)))
            if !isa(val, vartype)
                try
                    val = convert(vartype, val)
                catch
                    simlog("Invalid patch parameter type $var: $val", settings, 'w')
                    continue
                end
            end
            eval(parse("newpatch."*string(var)*" = $val"))
        end
        if newpatch.initpop && settings["initadults"]
            append!(newpatch.community, genesis(settings))
        elseif newpatch.initpop && !newpatch.isisland && settings["static"]
            append!(newpatch.seedbank, genesis(settings))
            lineage = ""
            for ind in newpatch.seedbank # store one sample individual for recording purposes
                if ind.lineage != lineage
                    push!(newpatch.community, ind)
                    lineage = ind.lineage
                end
            end
        elseif newpatch.initpop
            append!(newpatch.seedbank, genesis(settings))
        end
        push!(world, newpatch)
        global newpatch = nothing #clear memory
    end
    world
end

function updateworld!(world::Array{Patch,1},maptable::Array{Array{String,1},1},cellsize::Float64)
    #TODO: add functionality to remove patches!
    simlog("Updating world...", settings)
    for entry in maptable
        size(entry,1) < 3 && error("please check your map file for incomplete or faulty entries. \n
                            Each line must contain patch information with at least \n
                            \t - a unique integer ID, \n
                            \t - an integer x coordinate, \n
                            \t - an integer y coordinate, \n
                            separated by a whitespace character (<ID> <x> <y>).")
        id = parse(Int, entry[1])
        xcord = parse(Int, entry[2])
        ycord = parse(Int, entry[3])
        # XXX the 'global' here is a hack so that I can use eval() later on
        # (this always works on the global scope)
        idx = findall(x -> x.id == id, world)
        if length(idx) == 0
            marked = true
            global newpatch = Patch(id, (xcord, ycord), cellsize)
        else
            marked = false
            global newpatch = world[idx[1]]
        end
        # parse other parameter options
        for p in entry[4:end]
            varval = split(p, '=')
            var = varval[1]
            if !(var in map(string, fieldnames(Patch)))
                simlog("Unrecognized patch parameter $var.", settings, 'w')
                continue
            elseif length(varval) < 2
                val = true # if no value is specified, assume 'true'
            else
                val = parse(varval[2])
            end
            # check for correct type and modify the new patch
            vartype = typeof(eval(parse("newpatch."*var)))
            if !isa(val, vartype)
                try
                    val = convert(vartype, val)
                catch
                    simlog("Invalid patch parameter type $var: $val", settings, 'w')
                    continue
                end
            end
            eval(parse("newpatch."*string(var)*" = $val"))
        end
        if marked
            push!(world, newpatch)
            global newpatch = nothing #clear memory
        end
    end
    world
end
