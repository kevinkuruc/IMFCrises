using Plots
using Statistics
using ColorTypes
using DataFrames
using CSV
using Ipopt
using NLopt
using LinearAlgebra
using StatsPlots
include("LinearRegression.jl")
include("RunningPlacebosFunction.jl")

CurrentPath = "C:\\Users\\Admin\\OneDrive\\IMF\\AERInsights\\"

#############################################################
# Things to define for entire paper                         #
#############################################################
t = collect(-5:1:6)
growths = [:LGrowth5, :LGrowth4, :LGrowth3, :LGrowth2, :LGrowth1, :DWDI, :FGrowth1, :FGrowth2, :FGrowth3, :FGrowth4, :FGrowth5, :FGrowth6]
treatedblue = :black
controlred = RGB(120/255, 120/255, 120/255)

AllData					= CSV.read(string(CurrentPath,"Data\\MasterData.csv"))
NAllCrises 				= size(AllData)[1]
println("Number of total crises for path is $NAllCrises")
		for z in (:Banking, :Currency, :Debt)
       		AllData[z] = AllData[z]*.5*2
		end
IMFCrises 				= AllData[AllData[:, :IMF].==1, :]
IMFCrises[:i]			= collect(1:1:size(IMFCrises)[1])
IMFCrisesGrowths		= IMFCrises[:,[growths; :i]]
IMFCrisesGrowths 		= IMFCrises[completecases(IMFCrisesGrowths), :]
IMFCrises 				= join(IMFCrises, IMFCrisesGrowths, on=:i, kind=:inner, makeunique=true)

NoIMFCrises				= AllData[AllData[:, :IMF].==0, :]
NoIMFCrises[:i]			= collect(1:1:size(NoIMFCrises)[1])
NoIMFCrisesGrowths 		= NoIMFCrises[:,[growths; :i]]
NoIMFCrisesGrowths 		= NoIMFCrises[completecases(NoIMFCrisesGrowths), :]
NoIMFCrises 			= join(NoIMFCrises, NoIMFCrisesGrowths, on=:i, kind=:inner, makeunique=true)


## FIRST DEFINE MAIN SPECIFICATION FOR CONSTRUCTING SYNTHETIC CONTROLS
W 		= ones(10,1)  #diaganol of weighting matrix (equal weights in baseline)
matchon = [:LGrowth5, :LGrowth4, :LGrowth3, :LGrowth2, :LGrowth1, :DWDI, :Banking, :Currency, :Debt]
predict = [:FGrowth1, :FGrowth2, :FGrowth3, :FGrowth4, :FGrowth5, :FGrowth6]
matchtol= Inf	  ### For if I want to throw away bad matches 
bounds  = [7, 7, 7, 7, 7, 7, .5, .5, .5]
(TreatedMatched, Synthetics, DonorWeights) = GenSynthetics(IMFCrises, NoIMFCrises, matchon, predict, localtol=bounds, matchweights=W)
TreatedMatched[:Matched] = 1
IMFCrisesForTable = join(IMFCrises, TreatedMatched, on=:ID, kind=:outer, makeunique=true)
IMFCrisesForTable = IMFCrisesForTable[:, [:Country :year :Banking :Currency :Debt :Matched]]

WeightsArray = convert(Array, DonorWeights[:,4:end])
synthtot = size(WeightsArray)[1]
TotalWeight = zeros(synthtot)
Matched 	= zeros(synthtot)
for i = 1:synthtot
    TotalWeight[i] = sum(WeightsArray[i,:])
    if TotalWeight[i]>.2
    	Matched[i] =1
    end
end
DonorWeights[:TotalWeight] = TotalWeight
DonorWeights[:Matched]	   = Matched
NoIMFCrisesForTable = join(NoIMFCrises, DonorWeights, on=[:Country :year], kind=:outer)
IMFNoCrisesForTable = IMFNoCrisesForTable[:, :Country :year :Banking :Currency :Debt :Matched]]


NoIMFCrisesForTable = join(NoIMFCrises, DonorWeights, on=[:Country :year], kind=:outer)


println("Number of crises with IMF lending is $NIMF")
NoIMFCrises				= AllData[AllData[:, :IMF].==0, :]
NoIMFCrisesGrowths 		= NoIMFCrises[:,growths]
NoIMFCrisesGrowths 		= NoIMFCrises[completecases(NoIMFCrisesGrowths), :]
NNoIMF 					= size(NoIMFCrisesGrowths)[1]
println("Number of crises without IMF lending is $NNoIMF")
AllCrises				= AllData[:, :]
AllCrisesGrowths 		= AllCrises[:,growths]
AllCrisesGrowths 		= AllCrises[completecases(AllCrisesGrowths), :]
NAllCrises 				= size(AllCrisesGrowths)[1]
println("Number of total crises for path is $NAllCrises")