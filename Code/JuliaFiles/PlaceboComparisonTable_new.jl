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

#############################################################
# DEFINE OUTPUT												#
#############################################################
bounds = [7; 9; 11; 13; 15; 50]
Vars   = ["GrowthOnly" "CAB" "EXDEBT" "Infl" "All" "AllCrises"]
TableA2 = zeros(length(Vars), length(bounds))
TableA2 = [bounds'; TableA2]
TableA2_3H = zeros(length(Vars), length(bounds))
TableA2_3H = [bounds'; TableA2_3H]
NsForA2 = zeros(length(Vars), length(bounds))
NsForA2 = [bounds'; NsForA2]

MatchonOrig = [:LGrowth5, :LGrowth4, :LGrowth3, :LGrowth2, :LGrowth1, :DWDI, :Banking, :Currency, :Debt]
MatchonCAB = [:LGrowth5, :LGrowth4, :LGrowth3, :LGrowth2, :LGrowth1, :DWDI, :Banking, :Currency, :Debt, :CAB]
MatchonInfl = [:LGrowth5, :LGrowth4, :LGrowth3, :LGrowth2, :LGrowth1, :DWDI, :Banking, :Currency, :Debt, :Infl]
MatchonDebt = [:LGrowth5, :LGrowth4, :LGrowth3, :LGrowth2, :LGrowth1, :DWDI, :Banking, :Currency, :Debt, :EXDEBT]
MatchonAll  = [:LGrowth5, :LGrowth4, :LGrowth3, :LGrowth2, :LGrowth1, :DWDI, :Banking, :Currency, :Debt, :CAB, :EXDEBT, :Infl]
MatchonNone = [:LGrowth5, :LGrowth4, :LGrowth3, :LGrowth2, :LGrowth1, :DWDI]
MetaMatchOn = [MatchonOrig, MatchonCAB, MatchonInfl, MatchonDebt, MatchonAll, MatchonNone]

#############################################################
# RUN SYNTHETIC CONTROLS ON UNTREATED						#
#############################################################
for (k, m) in enumerate(MetaMatchOn)
## Loop over bounds for a given 'matchon'
	for (j, b) in enumerate(bounds)
		matchon = m
		W 		= ones(10,1)  #diaganol of weighting matrix (equal weights in baseline)
			if length(m)==10
				if m[10]==:CAB
					W[10] = Growth_variance/CAB_variance  #These are computed in RobustnessRuns.jl
				elseif m[10]==:Infl
					W[10] = Growth_variance/Infl_variance
				elseif m[10]==:EXDEBT
					W[10] = Growth_variance/Debt_variance
				end
			elseif length(m)>10
				W = ones(12)
				W[10] = Growth_variance/CAB_variance
				W[11] = Growth_variance/Infl_variance 
				W[12] = Growth_variance/Debt_variance
			end
		matchon = [:LGrowth5, :LGrowth4, :LGrowth3, :LGrowth2, :LGrowth1, :DWDI, :Banking, :Currency, :Debt]
		predict = [:FGrowth1, :FGrowth2, :FGrowth3, :FGrowth4, :FGrowth5, :FGrowth6]
		matchtol= Inf	  ### For if I want to throw away bad matches 
	
		bounds  = [b, b, b, b, b, b, .5, .5, .5]
		## PLACEBO GROUP COMES FIRST IN ORDER TO GENERATE VARIANCE UNDER THE NULL
		include("RunningPlacebosFunction.jl")
		(Placebos, SyntheticPlacebos) = RunningPlacebos(matchon, W, bounds, predict, NoIMFCrises);

		NullErrors = DataFrame()
		PostErrors = [:PostError1, :PostError2, :PostError3, :PostError4, :PostError5, :PostError6]
		PostGrowths = [:PostGrowth1, :PostGrowth2, :PostGrowth3, :PostGrowth4, :PostGrowth5, :PostGrowth6]
		for (pe, pg) in zip(PostErrors, PostGrowths)
			NullErrors[pe] = map((x,y) -> x-y, Placebos[pg], SyntheticPlacebos[pg])
		end
		NullErrorsArray			= convert(Array, [NullErrors[:PostError1] NullErrors[:PostError2] NullErrors[:PostError3]]);
		N 						= size(NullErrorsArray)[1]
		NullCovariance 			= (1/N)*NullErrorsArray'*NullErrorsArray  #calculate variance by hand assuming mean zero
		TableA2[k+1, j]			= NullCovariance[2,2]
		TableA2_3H[k+1,j]		= NullCovariance[3,3]
		NsForA2[k+1, j]			= N
	end
end
