#############################################################
# This is a master file that runs all analysis for          #
# extra robustness for an appendix robustness figure.		#
# Note: allocate 6-7 hours to running this if you want      #
# the code to reoptimize weights in CAB, Infl, and Debt     #
#############################################################

CurrentPath = "C:\\Users\\kevin\\OneDrive\\IMF\\"

using Plots
using Statistics
using ColorTypes
using DataFrames
using CSV
using ColorTypes
using Ipopt
using NLopt
using LinearAlgebra
using StatPlots
using Distributions
include(string(CurrentPath,"Code\\JuliaFiles\\LinearRegression.jl"))
include(string(CurrentPath,"Code\\JuliaFiles\\GenSynthetics_NLopt.jl"))

ExtraRobustBetas = zeros(7,8)

W 		= ones(10,1)  #diaganol of weighting matrix (equal weights in baseline)
matchon = [:LGrowth5, :LGrowth4, :LGrowth3, :LGrowth2, :LGrowth1, :DPWT, :Banking, :Currency, :Debt]
predict = [:FGrowth1, :FGrowth2, :FGrowth3, :FGrowth4, :FGrowth5, :FGrowth6]
matchtol= Inf	  ### For if I want to throw away bad matches 
bounds  = [7, 7, 7, 7, 7, 7, .5, .5, .5]

## PWT First
AllData					= CSV.read(string(CurrentPath, "Data\\created\\MasterData_PWT.csv"))
		for z in (:Banking, :Currency, :Debt)
       		AllData[z] = AllData[z]*.5*2
		end
IMFCrises 				= AllData[AllData[:, :IMF].==1, :]
NoIMFCrises				= AllData[AllData[:, :IMF].==0, :]
(TreatedMatched_PWT, Synthetics_PWT, DonorWeights_PWT) = GenSynthetics(IMFCrises, NoIMFCrises, matchon, predict, localtol=bounds, matchweights=W);

##Rest on WDI Variables so load that in
AllData					= CSV.read(string(CurrentPath, "Data\\created\\MasterData.csv"))
		for z in (:Banking, :Currency, :Debt)
       		AllData[z] = AllData[z]*.5*2
		end
IMFCrises 				= AllData[AllData[:, :IMF].==1, :]
NoIMFCrises				= AllData[AllData[:, :IMF].==0, :]

# Local Projection
LPVars = [:LGrowth5, :LGrowth4, :LGrowth3, :LGrowth2, :LGrowth1, :DWDI, :FGrowth1, :FGrowth2, :FGrowth3, :FGrowth4, :FGrowth5, :FGrowth6, :Banking, :Currency, :Debt, :IMF]
LPData = AllData[:, LPVars]
LPData = LPData[completecases(LPData), :]
# REGRESSIONS HERE
controlvars = [:IMF, :LGrowth5, :LGrowth4, :LGrowth3, :LGrowth2, :LGrowth1, :DWDI, :Banking, :Currency, :Debt]
ControlMatrix = convert(Array, LPData[:, controlvars])
FGrowths = [:FGrowth1, :FGrowth2, :FGrowth3, :FGrowth4, :FGrowth5, :FGrowth6]
for (h, g) in enumerate(FGrowths)
		Y = convert(Array, LPData[g])
		(Bhat, Varhat) = Regress(Y, ControlMatrix)
		ExtraRobustBetas[h+1, 1] = Bhat[2]
end


## Optimize Weights for Infl/CAB/DEBT
include("SolveForWeights.jl")
bounds  = [7, 7, 7, 7, 7, 7, Inf, .5, .5, .5]

##CAB
matchon = [:LGrowth5, :LGrowth4, :LGrowth3, :LGrowth2, :LGrowth1, :DWDI, :CAB, :Banking, :Currency, :Debt]
#(solCAB, WeightsCAB) = MinimizeForWeights(matchon, bounds, predict, NoIMFCrises)
WeightsCAB= [1, .039, 1.24, 1.98, 2.16, .90, 1.02, 1., 1., 1.]
W = ones(size(matchon)[1])
for i = 1:size(matchon)[1]-3
	W[i] = WeightsCAB[i]
end
(TreatedMatched_CAB, Synthetics_CAB, DonorWeights_CAB) = GenSynthetics(IMFCrises, NoIMFCrises, matchon, predict, localtol=bounds, matchweights=W);


matchon = [:LGrowth5, :LGrowth4, :LGrowth3, :LGrowth2, :LGrowth1, :DWDI, :Infl, :Banking, :Currency, :Debt]
#(solInfl, WeightsInfl) = MinimizeForWeights(matchon, bounds, predict, NoIMFCrises)
WeightsInfl = [1, 2.13, 0.1875, 1.38, 0.0, 1., 1., 1., 1., 1.]
W = ones(size(matchon)[1])
for i = 1:size(matchon)[1]-3
	W[i] = WeightsInfl[i]
end
(TreatedMatched_Infl, Synthetics_Infl, DonorWeights_Infl) = GenSynthetics(IMFCrises, NoIMFCrises, matchon, predict, localtol=bounds, matchweights=W);

matchon = [:LGrowth5, :LGrowth4, :LGrowth3, :LGrowth2, :LGrowth1, :DWDI, :EXDEBT, :Banking, :Currency, :Debt]
#(solDebts, WeightsDebt) = MinimizeForWeights(matchon, bounds, predict, NoIMFCrises)
WeightsDebt= [1, 1.38, 0.0, 3.25, 1.38, 1., 1., 1., 1., 1.]
W = ones(size(matchon)[1])
for i = 1:size(matchon)[1]-3
	W[i] = WeightsDebt[i]
end
(TreatedMatched_Debt, Synthetics_Debt, DonorWeights_Debt) = GenSynthetics(IMFCrises, NoIMFCrises, matchon, predict, localtol=bounds, matchweights=W);

##Drop Advanced Economies
DroppedAdvanced = NoIMFCrises[NoIMFCrises[:advecon].!=1, :]
W 		= ones(10,1)  #diaganol of weighting matrix (equal weights in baseline)
matchon = [:LGrowth5, :LGrowth4, :LGrowth3, :LGrowth2, :LGrowth1, :DWDI, :Banking, :Currency, :Debt]
predict = [:FGrowth1, :FGrowth2, :FGrowth3, :FGrowth4, :FGrowth5, :FGrowth6]
matchtol= Inf	  ### For if I want to throw away bad matches 
bounds  = [7, 7, 7, 7, 7, 7, .5, .5, .5]
(TreatedMatched_NoAdv, Synthetics_NoAdv, DonorWeights_NoAdv) = GenSynthetics(IMFCrises, DroppedAdvanced, matchon, predict, localtol=bounds, matchweights=W);

##Drop Bad Matches
(TreatedMatched_DropBadMatch, Synthetics_DropBadMatch, DonorWeights_DropBadMatch) = GenSynthetics(IMFCrises, NoIMFCrises, matchon, predict, localtol=bounds, matchweights=W);

TreatedMatched_DropBadMatch[:tempID] = collect(1:1:size(TreatedMatched_DropBadMatch)[1])
Synthetics_DropBadMatch[:tempID]     = collect(1:1:size(TreatedMatched_DropBadMatch)[1])
Synthetics_DropBadMatch     = sort(Synthetics_DropBadMatch, :SqError, rev=true)
Synthetics_DropBadMatch		= Synthetics_DropBadMatch[6:end,:]
TreatedMatched_DropBadMatch = join(TreatedMatched_DropBadMatch, Synthetics_DropBadMatch, on=[:tempID], kind=:inner)

##No Bounds
bounds  = [Inf, Inf, Inf, Inf, Inf, Inf, .5, .5, .5]
(TreatedMatched_NoBounds, Synthetics_NoBounds, DonorWeights_NoBounds) = GenSynthetics(IMFCrises, NoIMFCrises, matchon, predict, localtol=bounds, matchweights=W);


for z = (TreatedMatched_PWT, Synthetics_PWT, TreatedMatched_CAB, Synthetics_CAB, TreatedMatched_Infl, Synthetics_Infl, TreatedMatched_Debt, Synthetics_Debt, TreatedMatched_NoAdv, Synthetics_NoAdv, TreatedMatched_DropBadMatch, Synthetics_DropBadMatch, TreatedMatched_NoBounds, Synthetics_NoBounds)
      z[:PostGrowth1] = map((x1) -> 100*(1+x1/100 -1), z[:FGrowth1])
      z[:PostGrowth2] = map((x1,x2) -> 100*((1+x1/100)*(1+x2/100) -1), z[:FGrowth1], z[:FGrowth2])
      z[:PostGrowth3] = map((x1,x2,x3) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3])
      z[:PostGrowth4] = map((x1,x2,x3,x4) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100)*(1+x4/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3], z[:FGrowth4])
      z[:PostGrowth5] = map((x1,x2,x3,x4,x5) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100)*(1+x4/100)*(1+x5/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3], z[:FGrowth4], z[:FGrowth5])
      z[:PostGrowth6] = map((x1,x2,x3,x4,x5, x6) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100)*(1+x4/100)*(1+x5/100)*(1+x6/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3], z[:FGrowth4], z[:FGrowth5], z[:FGrowth6])
end

pgrowths = [:PostGrowth1; :PostGrowth2; :PostGrowth3; :PostGrowth4; :PostGrowth5; :PostGrowth6]
for (h, k) in enumerate(pgrowths)
	TempDiff = convert(Array, TreatedMatched_PWT[k] - Synthetics_PWT[k])
	ExtraRobustBetas[h+1, 2] = mean(TempDiff) 
	TempDiff = convert(Array, TreatedMatched_CAB[k] - Synthetics_CAB[k])
	ExtraRobustBetas[h+1, 3] = mean(TempDiff) 
	TempDiff = convert(Array, TreatedMatched_Infl[k] - Synthetics_Infl[k])
	ExtraRobustBetas[h+1, 4] = mean(TempDiff) 
	TempDiff = convert(Array, TreatedMatched_Debt[k] - Synthetics_Debt[k])
	ExtraRobustBetas[h+1, 5] = mean(TempDiff) 
	TempDiff = convert(Array, TreatedMatched_NoAdv[k] - Synthetics_NoAdv[k])
	ExtraRobustBetas[h+1, 6] = mean(TempDiff) 
	TempDiff = convert(Array, TreatedMatched_DropBadMatch[k] - Synthetics_DropBadMatch[k])
	ExtraRobustBetas[h+1, 7] = mean(TempDiff)  
	TempDiff = convert(Array, TreatedMatched_NoBounds[k] - Synthetics_NoBounds[k])
	ExtraRobustBetas[h+1, 8] = mean(TempDiff)  
end

#plot(collect(0:1:6), ExtraRobustBetas[:, 1], linewidth=1.5, color=:red, style=:dashdot, label="")
plot(collect(0:1:6), ExtraRobustBetas[:, 2], linewidth=1.5, color=:green, style=:dot, label="PWT", legend=:bottomleft, ylims=(-3.5, 4.5))
plot!(collect(0:1:6), ExtraRobustBetas[:, 3], linewidth=1.5, color=:blue, style=:dot, label="CAB")
plot!(collect(0:1:6), ExtraRobustBetas[:, 4], linewidth=1.5, color=:pink, style=:dashdot, label="Infl")
plot!(collect(0:1:6), ExtraRobustBetas[:, 5], linewidth=1.5, color=:gold, style=:dot, label="Debt")
plot!(collect(0:1:6), ExtraRobustBetas[:, 6], linewidth=1.5, color=:brown, style=:dashdot, label="No Adv. Econ." )
plot!(collect(0:1:6), ExtraRobustBetas[:, 7], linewidth=1.5, color=:black, style=:dot, label="Drop Bad Matches" )
plot!(collect(0:1:6), ExtraRobustBetas[:, 8], linewidth=1.5, color=:purple, style=:dashdot, label="No Local Bounds" )
hline!([0], color=:black, style=:dot, label="")
savefig(string(CurrentPath, "Figures\\ExtraRobustIRF.pdf"))