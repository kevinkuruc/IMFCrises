#############################################################
# This file runs various placebo exercise to compar         #
# their forecast errors.                                    #
# Results here form the basis of Table A2					#
#############################################################
using Plots
using Statistics
using ColorTypes
using DataFrames
using CSV
CurrentPath = "C:\\Users\\kevin\\OneDrive\\IMF\\"

#############################################################
# DEFINE OUTPUT												#
#############################################################
bounds = [6; 7; 8; 9; 10; 11; Inf]
Vars   = ["GrowthOnly" "CAB" "EXDEBT" "Infl" "All" "AllCrises"]
TableA2 = zeros(length(Vars), length(bounds))
TableA2 = [bounds'; TableA2]
TableA2_3H = zeros(length(Vars), length(bounds))
TableA2_3H = [bounds'; TableA2_3H]
NsForA2 = zeros(length(Vars), length(bounds))
NsForA2 = [bounds'; TableA2]
#############################################################
# BRING IN DATA 											#
#############################################################

AllData					= CSV.read(string(CurrentPath, "Data\\created\\MasterData.csv"))
		for z in (:Banking, :Currency, :Debt)
       		AllData[z] = AllData[z]*.5*2
		end
NoIMFCrises				= AllData[AllData[:, :IMF].==0, :]

#############################################################
# RUN SYNTHETIC CONTROLS ON UNTREATED						#
#############################################################
println("Checkpoint 1")
## Loop over bounds for a given 'matchon'
for (j, b) in enumerate(bounds)
	W 		= ones(10,1)  #diaganol of weighting matrix (equal weights in baseline)
	matchon = [:LGrowth5, :LGrowth4, :LGrowth3, :LGrowth2, :LGrowth1, :DWDI, :Banking, :Currency, :Debt]
	predict = [:FGrowth1, :FGrowth2, :FGrowth3, :FGrowth4, :FGrowth5, :FGrowth6]
	matchtol= Inf	  ### For if I want to throw away bad matches 
	
	bounds  = [b, b, b, b, b, b, .5, .5, .5]
	## PLACEBO GROUP COMES FIRST IN ORDER TO GENERATE VARIANCE UNDER THE NULL
	include("RunningPlacebosFunction.jl")
	(Placebos, SyntheticPlacebos) = RunningPlacebos(matchon, W, bounds, predict, NoIMFCrises);

	NullErrors = DataFrame()
	NullErrors[:PostError1] = map((x,y) -> x-y, Placebos[:PostGrowth1], SyntheticPlacebos[:PostGrowth1])
	NullErrors[:PostError2] = map((x,y) -> x-y, Placebos[:PostGrowth2], SyntheticPlacebos[:PostGrowth2])
	NullErrors[:PostError3] = map((x,y) -> x-y, Placebos[:PostGrowth3], SyntheticPlacebos[:PostGrowth3])
	NullErrorsArray			= convert(Array, [NullErrors[:PostError1] NullErrors[:PostError2] NullErrors[:PostError3]])
	N 						= size(NullErrorsArray)[1]
	NullCovariance 			= (1/N)*NullErrorsArray'*NullErrorsArray  #calculate variance by hand assuming mean zero
	TableA2[2, j]			= NullCovariance[2,2]
	TableA2_3H[2,j]			= NullCovariance[3,3]
	NsForA2[2, j]			= N
	print(TableA2_3H)
	print(NsForA2)
end

for (j, b) in enumerate(bounds)
	W 		= ones(10,1)  #diaganol of weighting matrix (equal weights in baseline)
	matchon = [:LGrowth5, :LGrowth4, :LGrowth3, :LGrowth2, :LGrowth1, :DWDI, :Banking, :Currency, :Debt, :CAB]
	predict = [:FGrowth1, :FGrowth2, :FGrowth3, :FGrowth4, :FGrowth5, :FGrowth6]
	
	bounds  = [b, b, b, b, b, b, .5, .5, .5, Inf]
	## PLACEBO GROUP COMES FIRST IN ORDER TO GENERATE VARIANCE UNDER THE NULL
	include("RunningPlacebosFunction.jl")
	(Placebos, SyntheticPlacebos) = RunningPlacebos(matchon, W, bounds, predict, NoIMFCrises);

	NullErrors = DataFrame()
	NullErrors[:PostError1] = map((x,y) -> x-y, Placebos[:PostGrowth1], SyntheticPlacebos[:PostGrowth1])
	NullErrors[:PostError2] = map((x,y) -> x-y, Placebos[:PostGrowth2], SyntheticPlacebos[:PostGrowth2])
	NullErrors[:PostError3] = map((x,y) -> x-y, Placebos[:PostGrowth3], SyntheticPlacebos[:PostGrowth3])
	NullErrorsArray			= convert(Array, [NullErrors[:PostError1] NullErrors[:PostError2] NullErrors[:PostError3]])
	N 						= size(NullErrorsArray)[1]
	NullCovariance 			= (1/N)*NullErrorsArray'*NullErrorsArray  #calculate variance by hand assuming mean zero
	TableA2[3, j]			= NullCovariance[2,2]
	TableA2_3H[3,j]			= NullCovariance[3,3]
	NsForA2[3, j]			= N
	print(TableA2_3H)
	print(NsForA2)
end

for (j, b) in enumerate(bounds)
	W 		= ones(10,1)  #diaganol of weighting matrix (equal weights in baseline)
	matchon = [:LGrowth5, :LGrowth4, :LGrowth3, :LGrowth2, :LGrowth1, :DWDI, :Banking, :Currency, :Debt, :EXDEBT]
	predict = [:FGrowth1, :FGrowth2, :FGrowth3, :FGrowth4, :FGrowth5, :FGrowth6]
	
	bounds  = [b, b, b, b, b, b, .5, .5, .5, Inf]
	## PLACEBO GROUP COMES FIRST IN ORDER TO GENERATE VARIANCE UNDER THE NULL
	include("RunningPlacebosFunction.jl")
	(Placebos, SyntheticPlacebos) = RunningPlacebos(matchon, W, bounds, predict, NoIMFCrises);

	NullErrors = DataFrame()
	NullErrors[:PostError1] = map((x,y) -> x-y, Placebos[:PostGrowth1], SyntheticPlacebos[:PostGrowth1])
	NullErrors[:PostError2] = map((x,y) -> x-y, Placebos[:PostGrowth2], SyntheticPlacebos[:PostGrowth2])
	NullErrors[:PostError3] = map((x,y) -> x-y, Placebos[:PostGrowth3], SyntheticPlacebos[:PostGrowth3])
	NullErrorsArray			= convert(Array, [NullErrors[:PostError1] NullErrors[:PostError2] NullErrors[:PostError3]])
	N 						= size(NullErrorsArray)[1]
	NullCovariance 			= (1/N)*NullErrorsArray'*NullErrorsArray  #calculate variance by hand assuming mean zero
	TableA2[4, j]			= NullCovariance[2,2]
	TableA2_3H[4,j]			= NullCovariance[3,3]
	NsForA2[4, j]			= N
	print(TableA2_3H)
	print(NsForA2)
end


for (j, b) in enumerate(bounds)
	W 		= ones(10,1)  #diaganol of weighting matrix (equal weights in baseline)
	matchon = [:LGrowth5, :LGrowth4, :LGrowth3, :LGrowth2, :LGrowth1, :DWDI, :Banking, :Currency, :Debt, :Infl]
	predict = [:FGrowth1, :FGrowth2, :FGrowth3, :FGrowth4, :FGrowth5, :FGrowth6]
	
	bounds  = [b, b, b, b, b, b, .5, .5, .5, Inf]
	## PLACEBO GROUP COMES FIRST IN ORDER TO GENERATE VARIANCE UNDER THE NULL
	include("RunningPlacebosFunction.jl")
	(Placebos, SyntheticPlacebos) = RunningPlacebos(matchon, W, bounds, predict, NoIMFCrises);

	NullErrors = DataFrame()
	NullErrors[:PostError1] = map((x,y) -> x-y, Placebos[:PostGrowth1], SyntheticPlacebos[:PostGrowth1])
	NullErrors[:PostError2] = map((x,y) -> x-y, Placebos[:PostGrowth2], SyntheticPlacebos[:PostGrowth2])
	NullErrors[:PostError3] = map((x,y) -> x-y, Placebos[:PostGrowth3], SyntheticPlacebos[:PostGrowth3])
	NullErrorsArray			= convert(Array, [NullErrors[:PostError1] NullErrors[:PostError2] NullErrors[:PostError3]])
	N 						= size(NullErrorsArray)[1]
	NullCovariance 			= (1/N)*NullErrorsArray'*NullErrorsArray  #calculate variance by hand assuming mean zero
	TableA2[5, j]			= NullCovariance[2,2]
	TableA2_3H[5,j]			= NullCovariance[3,3]
	NsForA2[5, j]			= N
	print(TableA2_3H)
	print(NsForA2)
end

for (j, b) in enumerate(bounds)
	W 		= ones(15,1)  #diaganol of weighting matrix (equal weights in baseline)
	matchon = [:LGrowth5, :LGrowth4, :LGrowth3, :LGrowth2, :LGrowth1, :DWDI, :Banking, :Currency, :Debt, :CAB, :EXDEBT, :Infl]
	predict = [:FGrowth1, :FGrowth2, :FGrowth3, :FGrowth4, :FGrowth5, :FGrowth6]
	bounds  = [b, b, b, b, b, b, .5, .5, .5, Inf, Inf, Inf]
	## PLACEBO GROUP COMES FIRST IN ORDER TO GENERATE VARIANCE UNDER THE NULL
	include("RunningPlacebosFunction.jl")
	(Placebos, SyntheticPlacebos) = RunningPlacebos(matchon, W, bounds, predict, NoIMFCrises);

	NullErrors = DataFrame()
	NullErrors[:PostError1] = map((x,y) -> x-y, Placebos[:PostGrowth1], SyntheticPlacebos[:PostGrowth1])
	NullErrors[:PostError2] = map((x,y) -> x-y, Placebos[:PostGrowth2], SyntheticPlacebos[:PostGrowth2])
	NullErrors[:PostError3] = map((x,y) -> x-y, Placebos[:PostGrowth3], SyntheticPlacebos[:PostGrowth3])
	NullErrorsArray			= convert(Array, [NullErrors[:PostError1] NullErrors[:PostError2] NullErrors[:PostError3]])
	N 						= size(NullErrorsArray)[1]
	NullCovariance 			= (1/N)*NullErrorsArray'*NullErrorsArray  #calculate variance by hand assuming mean zero
	TableA2[6, j]			= NullCovariance[2,2]
	TableA2_3H[6,j]			= NullCovariance[3,3]
	NsForA2[6, j]			= N
	print(TableA2_3H)
	print(NsForA2)
end

for (j, b) in enumerate(bounds)
	W 		= ones(10,1)  #diaganol of weighting matrix (equal weights in baseline)
	matchon = [:LGrowth5, :LGrowth4, :LGrowth3, :LGrowth2, :LGrowth1, :DWDI]
	predict = [:FGrowth1, :FGrowth2, :FGrowth3, :FGrowth4, :FGrowth5, :FGrowth6]
	bounds  = [b, b, b, b, b, b]
	## PLACEBO GROUP COMES FIRST IN ORDER TO GENERATE VARIANCE UNDER THE NULL
	include("RunningPlacebosFunction.jl")
	(Placebos, SyntheticPlacebos) = RunningPlacebos(matchon, W, bounds, predict, NoIMFCrises);

	NullErrors = DataFrame()
	NullErrors[:PostError1] = map((x,y) -> x-y, Placebos[:PostGrowth1], SyntheticPlacebos[:PostGrowth1])
	NullErrors[:PostError2] = map((x,y) -> x-y, Placebos[:PostGrowth2], SyntheticPlacebos[:PostGrowth2])
	NullErrors[:PostError3] = map((x,y) -> x-y, Placebos[:PostGrowth3], SyntheticPlacebos[:PostGrowth3])
	NullErrorsArray			= convert(Array, [NullErrors[:PostError1] NullErrors[:PostError2] NullErrors[:PostError3]])
	N 						= size(NullErrorsArray)[1]
	NullCovariance 			= (1/N)*NullErrorsArray'*NullErrorsArray  #calculate variance by hand assuming mean zero
	TableA2[7, j]			= NullCovariance[2,2]
	TableA2_3H[7,j]			= NullCovariance[3,3]
	NsForA2[7, j]			= N
	print(TableA2_3H)
	print(NsForA2)
end