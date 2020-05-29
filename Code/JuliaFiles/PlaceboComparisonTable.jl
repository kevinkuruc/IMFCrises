#############################################################
# This file runs various placebo exercise to compare        #
# their forecast errors.                                    #
# Results here form the basis of Table A3 and A4			#
#############################################################
using Plots
using Statistics
using ColorTypes
using DataFrames
using CSV

#############################################################
# DEFINE OUTPUT												#
#############################################################
bounds = [7; 9; 11; 13; 15; 25]
Vars   = ["GrowthOnly"; "CAB"; "Infl"; "EXDEBT"]
Variances_2H = zeros(length(Vars), length(bounds))
Variances_2H = [bounds'; Variances_2H]
Variances_3H = zeros(length(Vars), length(bounds))
Variances_3H = [bounds'; Variances_3H]
NsPlacebo = zeros(length(Vars), length(bounds))
NsPlacebo = [bounds'; NsPlacebo]

MatchonOrig = [:LGrowth5, :LGrowth4, :LGrowth3, :LGrowth2, :LGrowth1, :DWDI, :Banking, :Currency, :Debt]
MatchonCAB = [:LGrowth5, :LGrowth4, :LGrowth3, :LGrowth2, :LGrowth1, :DWDI, :Banking, :Currency, :Debt, :CAB]
MatchonInfl = [:LGrowth5, :LGrowth4, :LGrowth3, :LGrowth2, :LGrowth1, :DWDI, :Banking, :Currency, :Debt, :Infl]
MatchonDebt = [:LGrowth5, :LGrowth4, :LGrowth3, :LGrowth2, :LGrowth1, :DWDI, :Banking, :Currency, :Debt, :EXDEBT]
#MatchonNone = [:LGrowth5, :LGrowth4, :LGrowth3, :LGrowth2, :LGrowth1, :DWDI]
MetaMatchOn = [MatchonOrig, MatchonCAB, MatchonInfl, MatchonDebt]

#############################################################
# RUN SYNTHETIC CONTROLS ON UNTREATED						#
#############################################################
for (k, m) in enumerate(MetaMatchOn)
## Loop over bounds for a given 'matchon'
	for (j, b) in enumerate(bounds)
		W 		= ones(10,1)  #diaganol of weighting matrix (equal weights in baseline)
		bounds_inner  = [b, b, b, b, b, b, .5, .5, .5]
			if length(m)==10
				if m[10]==:CAB
					W[10] = Growth_variance/CAB_variance  #These are computed in RobustnessRuns.jl
				elseif m[10]==:Infl
					W[10] = Growth_variance/Infl_variance
				elseif m[10]==:EXDEBT
					W[10] = Growth_variance/Debt_variance
				end
			bounds_inner = [b, b, b, b, b, b, .5, .5, .5, Inf]
			end
		matchtol= Inf	  ### For if I want to throw away bad matches 
		## PLACEBO GROUP COMES FIRST IN ORDER TO GENERATE VARIANCE UNDER THE NULL
		include("RunningPlacebosFunction.jl")
		(Placebos, SyntheticPlacebos) = RunningPlacebos(m, W, bounds_inner, predict, NoIMFCrises);

		NullErrors = DataFrame()
		PostErrors = [:PostError1, :PostError2, :PostError3, :PostError4, :PostError5, :PostError6]
		PostGrowths = [:PostGrowth1, :PostGrowth2, :PostGrowth3, :PostGrowth4, :PostGrowth5, :PostGrowth6]
		for (pe, pg) in zip(PostErrors, PostGrowths)
			NullErrors[pe] = map((x,y) -> x-y, Placebos[pg], SyntheticPlacebos[pg])
		end
		NullErrorsArray			= convert(Array, [NullErrors[:PostError1] NullErrors[:PostError2] NullErrors[:PostError3]]);
		N 						= size(NullErrorsArray)[1]
		NullCovariance 			= (1/N)*NullErrorsArray'*NullErrorsArray  #calculate variance by hand assuming mean zero
		Variances_2H[k+1, j]			= NullCovariance[2,2]
		Variances_3H[k+1,j]		= NullCovariance[3,3]
		NsPlacebo[k+1, j]		= N
		println("N is $N")
	end
end

df2 = DataFrame(Runs=Vars)
df3 = DataFrame(Runs=Vars)
dfN = DataFrame(Runs=Vars)
dfs = (df2, df3, dfN)
Arrays = (Variances_2H, Variances_3H, NsPlacebo)
for (A, D) in zip(Arrays, dfs)
	D[:Seven] = A[2:end, 1]
	D[:Nine]  = A[2:end, 2]
	D[:Eleven]  = A[2:end, 3]
	D[:Thirteen]  = A[2:end, 4]
	D[:Fifteen]  = A[2:end, 5]
	D[:TwentyFive]  = A[2:end, 6]
end

CSV.write(joinpath(output_directory, "TableA3.csv"), df3)
CSV.write(joinpath(output_directory, "TableA4.csv"), dfN)

