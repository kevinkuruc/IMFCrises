##This function runs the synthetic control function and creates 

using CSV 
using DataFrames

include(joinpath(code_directory, "GenSynthetics_NLopt.jl"))

function RunningPlacebos(matchon, W, bounds, predict, Pool::DataFrame)

    N = size(Pool, 1)
    i = collect(1:1:N)
    Pool[!, :i] = .5*2*i

    ###Before Running want to ensure Pooled group has no missings for necessary values
    bigp = size(Pool, 1)
    Pool[!, :ID] = collect(1:1:bigp)
    completecheck = [:ID; matchon; predict]
    tempPool = Pool[:, completecheck]
    tempPool = tempPool[completecases(tempPool),:]
    PoolCompleteID = DataFrame(ID = tempPool[!, :ID])
    Pool = innerjoin(Pool, PoolCompleteID, on=:ID)
    relevant = [:Country; :year; matchon; predict]
    SynthRelevant = Pool[:, relevant]

    ##Now making two empty DataFrames to populate with results as I go
    SyntheticPlacebos = SynthRelevant[1:1, :]
    SyntheticPlacebos[!, :SqError] = [2.]
    SyntheticPlacebos = delete!(SyntheticPlacebos,1)
    TreatPlaceb = SyntheticPlacebos[SyntheticPlacebos[!, :LGrowth5].<Inf,:]  #arbitrary to just copy it
    TreatPlaceb[!, :ID] = []
    global SyntheticPlacebos
    global TreatPlaceb

    #Loops over and runs the Synthetic Controls for each placebo against all others given specification
    SquareError_formerge = DataFrame(SqError = [0.])
    for j = 1:size(Pool, 1)
        placebo = Pool[Pool[!, :i].==j, relevant] 
        if size(placebo, 1)>0
            dropplaceb              = Pool[Pool[!, :i].!=j, relevant]
            (Placebt, Placebj, w)   = GenSynthetics(placebo, dropplaceb, matchon, predict, localtol= bounds, matchweights=W)
            if size(Placebj, 1) >0  #Push if non-empty synthetic generated
                Placebt = hcat(Placebt, SquareError_formerge)
                push!(SyntheticPlacebos, Placebj[1,:])
                push!(TreatPlaceb, Placebt[1,:])
            end
        end
    end

    for z = (SyntheticPlacebos, TreatPlaceb)
        z[!, :PostGrowth1] = map((x1) -> 100*(1+x1/100 -1), z[!, :FGrowth1])
        z[!, :PostGrowth2] = map((x1,x2) -> 100*((1+x1/100)*(1+x2/100) -1), z[!, :FGrowth1], z[!, :FGrowth2])
        z[!, :PostGrowth3] = map((x1,x2,x3) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100) -1), z[!, :FGrowth1], z[!, :FGrowth2], z[!, :FGrowth3])
        z[!, :PostGrowth4] = map((x1,x2,x3,x4) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100)*(1+x4/100) -1), z[!, :FGrowth1], z[!, :FGrowth2], z[!, :FGrowth3], z[!, :FGrowth4])
        z[!, :PostGrowth5] = map((x1,x2,x3,x4,x5) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100)*(1+x4/100)*(1+x5/100) -1), z[!, :FGrowth1], z[!, :FGrowth2], z[!, :FGrowth3], z[!, :FGrowth4], z[!, :FGrowth5])
        z[!, :PostGrowth6] = map((x1,x2,x3,x4,x5, x6) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100)*(1+x4/100)*(1+x5/100)*(1+x6/100) -1), z[!, :FGrowth1], z[!, :FGrowth2], z[!, :FGrowth3], z[!, :FGrowth4], z[!, :FGrowth5], z[!, :FGrowth6])
        #z[!, :PostGrowth7] = map((x1,x2,x3,x4,x5, x6, x7) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100)*(1+x4/100)*(1+x5/100)*(1+x6/100)*(1+x7/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3], z[:FGrowth4], z[:FGrowth5], z[:FGrowth6], z[:FGrowth7])
    end
return TreatPlaceb, SyntheticPlacebos
end


