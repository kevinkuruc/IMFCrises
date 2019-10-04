#############################################################
# This is a master file that runs all analysis for          #
# "Are IMF Rescue Packages Effective? Evidence From Crises" #
#  All findings and figures can be produced by running this #
# code with the appropriate data and julia functions within #
# the folder.                                               #
#############################################################

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
include("LinearRegression.jl")

#############################################################
# Things to define for entire paper                         #
#############################################################
t = collect(-5:1:5)
growths = [:LGrowth5, :LGrowth4, :LGrowth3, :LGrowth2, :LGrowth1, :DPWT, :FGrowth1, :FGrowth2, :FGrowth3, :FGrowth4, :FGrowth5]
treatedblue = RGB(2/255, 82/255, 211/255)
controlred = RGB(255/255, 0/255,  0/255)


#############################################################
# Summary Stats												#
#############################################################

## LOAD IN ALL IMF LOAN GROWTH RATES CENTERED AROUND THEIR LOAN
LoanPath = CSV.read("Data\\AvgPathLoans.csv")
tempk = [:IMFsizeGDP, :year]
LoanSizes  = Loans[:, tempk]
LoanSizes  = LoanSizes[completecases(LoanSizes),:]
LoanSizes  = LoanSizes[LoanSizes[:IMFsizeGDP].>0,:]
AvgSize = mean(LoanSizes[:IMFsizeGDP])
MedSize = median(LoanSizes[:IMFsizeGDP])
println("Mean Loan Size is $AvgSize")
println("Median Loan Size is $MedSize")
LoanPath = LoanPath[:, growths]
LoanPath = LoanPath[completecases(LoanPath),:];

## COMPUTE MEAN/MEDIAN GROWTH RATES X YEARS AFTER LOAN
NShortTermComplete = size(LoanPath)[1]
println("Number of Short-Term Loans for Summary Path is $NShortTermComplete")
meanmedLoan = zeros(size(growths)[1],2)
    for (j,g) in enumerate(growths)
        meanmedLoan[j,1] = mean(LoanPath[g])
        meanmedLoan[j,2] = median(LoanPath[g])
    end

## MAKE PLOT
colorMean = :black
colorMed = RGB(120/255, 120/255, 120/255)
styleMed = :dashdot
plot(t[1:11], meanmedLoan[1:11,:], label= ["Mean" "Median"], legend=:bottomright, color=[colorMean colorMed], style=[:solid styleMed],
linewidth=[2.5 2.5])
vline!([0], color=:black, label="", style=:dot)
xticks!(t)
xlabel!("Years Since Loan")
ylabel!("GDP Growth (%)")
annotate!([(0, 3.8, text("IMF Loan", 9, :black, :left))])
savefig("C:\\Users\\kevin\\Desktop\\IMF\\AERInsights\\Figures\\SummaryPath.pdf")

#########################################################################################
#  Make Graph with Financial Crisis & Split to With/Without                             #
#########################################################################################

AllData					= CSV.read("Data\\MasterDataPWT.csv")
NAllCrises 				= size(AllData)[1]
println("Number of total crises for path is $NAllCrises")
		for z in (:Banking, :Currency, :Debt)
       		AllData[z] = AllData[z]*.5*2
		end
IMFCrises 				= AllData[AllData[:, :IMF].==1, :]
IMFCrisesGrowths		= IMFCrises[:,growths]
IMFCrisesGrowths 		= IMFCrises[completecases(IMFCrisesGrowths), :]
NIMF 					= size(IMFCrisesGrowths)[1]
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

CrisisPaths = zeros(size(growths)[1],3)
    for (j,g) in enumerate(growths)
        CrisisPaths[j,1] = mean(AllCrisesGrowths[g])
        CrisisPaths[j,2] = mean(IMFCrisesGrowths[g])
        CrisisPaths[j,3] = mean(NoIMFCrisesGrowths[g])
    end
plot(t, CrisisPaths[:,1], legend=:bottomright, label="", color=:black, style=:solid, linewidth=2, ylim=(0, 4.4))
vline!([0], color=:black, label="", style=:dot)
xticks!(t)
xlabel!("Years Since Crisis")
ylabel!("GDP Growth (%)")
annotate!([(0, 3.4, text("Crisis Date", 9, :black, :left))])
savefig("C:\\Users\\kevin\\Desktop\\IMF\\AERInsights\\Figures\\AvgPathCrises_AllCrises_PWT.pdf")

plot(t, CrisisPaths[:,2:3], legend=:bottomright, label=["W/ IMF" "W/o IMF"], color=[treatedblue controlred], style=[:solid :dash], linewidth=[2 2], ylim=(0, 4.4))
vline!([0], color=:black, label="", style=:dot)
xticks!(t)
xlabel!("Years Since Crisis")
ylabel!("GDP Growth (%)")
savefig("C:\\Users\\kevin\\Desktop\\IMF\\AERInsights\\Figures\\AvgPathCrises_WithWithout_PWT.pdf")


#########################################################################################
# Run Synthetic Control and Make Graphs (Both Main and Appendix)						#
#########################################################################################

## FIRST DEFINE MAIN SPECIFICATION FOR CONSTRUCTING SYNTHETIC CONTROLS
W 		= ones(10,1)  #diaganol of weighting matrix (equal weights in baseline)
matchon = [:LGrowth5, :LGrowth4, :LGrowth3, :LGrowth2, :LGrowth1, :DPWT, :Banking, :Currency, :Debt]
predict = [:FGrowth1, :FGrowth2, :FGrowth3, :FGrowth4, :FGrowth5]
matchtol= Inf	  ### For if I want to throw away bad matches 
bounds  = [7, 7, 7, 7, 7, 7, .5, .5, .5]

## PLACEBO GROUP COMES FIRST IN ORDER TO GENERATE VARIANCE UNDER THE NULL
include("RunningPlacebosFunction.jl")
(Placebos, SyntheticPlacebos) = RunningPlacebos(matchon, W, bounds, predict, NoIMFCrises);

NullErrors = DataFrame()
NullErrors[:PostError1] = map((x,y) -> x-y, Placebos[:PostGrowth1], SyntheticPlacebos[:PostGrowth1])
NullErrors[:PostError2] = map((x,y) -> x-y, Placebos[:PostGrowth2], SyntheticPlacebos[:PostGrowth2])
NullErrors[:PostError3] = map((x,y) -> x-y, Placebos[:PostGrowth3], SyntheticPlacebos[:PostGrowth3])
NullErrors[:PostError4] = map((x,y) -> x-y, Placebos[:PostGrowth4], SyntheticPlacebos[:PostGrowth4])
NullErrors[:PostError5] = map((x,y) -> x-y, Placebos[:PostGrowth5], SyntheticPlacebos[:PostGrowth5])

NullErrorsArray			= convert(Array, [NullErrors[:PostError1] NullErrors[:PostError2] NullErrors[:PostError3] NullErrors[:PostError4] NullErrors[:PostError5]])

###########################################
# AM I DOING THIS VARIANCE (BELOW) RIGHT? #
###########################################
NullCovariance 			= (1/size(NullErrorsArray)[1])*NullErrorsArray'*NullErrorsArray  #calculate variance by hand assuming mean zero

## APPENDIX GRAPH OF PLACEBOS VS THEIR SYNTHETICS FOR GROWTH RATES
PlaceboGrowthRatesArray = convert(Array, Placebos[growths])
SyntheticPlacebosGrowthRatesArray = convert(Array, SyntheticPlacebos[growths])
MeanPlaceboVsSynthetics	= zeros(size(growths)[1],2)
		for j = 1:size(growths)[1]
				MeanPlaceboVsSynthetics[j,1] = mean(PlaceboGrowthRatesArray[:,j])
				MeanPlaceboVsSynthetics[j,2] = mean(SyntheticPlacebosGrowthRatesArray[:,j])
		end
plot(t, MeanPlaceboVsSynthetics, linewidth=[2.5 2], color=[treatedblue controlred], label=["\"Treated\"" "Synthetic"],xticks=collect(-5:1:5), ylabel="Percentage Points", xlabel="Years Since Crisis", style=[:solid :dashdot], legend=:bottomleft)
vline!([0], linestyle=:dash, linewidth=.75, color=:black, label="")
savefig("C:\\Users\\kevin\\Desktop\\IMF\\AERInsights\\Figures\\PlaceboGrowthRates_PWT.pdf")


## NOW THAT I HAVE NULL VARIANCES I CAN MOVE TO RUNNING ACTUAL SYNTHETICS
(TreatedMatched, Synthetics, DonorWeights) = GenSynthetics(IMFCrises, NoIMFCrises, matchon, predict, localtol=bounds, matchweights=W);

## PRESENT SOME MATCH 'DIAGNOSTICS', i.e., WHO ACTUALLY CAN GET MATCHED WELL IN PRE-PERIOD
WeightsArray = convert(Array, DonorWeights[:,4:end])
synthtot = size(WeightsArray)[1]
TotalWeight = zeros(synthtot)
for i = 1:synthtot
    TotalWeight[i] = sum(WeightsArray[i,:])
end
histogram(TotalWeight, bins=30, xticks=collect(0:1:5), color=treatedblue, label="", ylabel="Frequency"
, xlabel="Total (Sum) of Weights in the 93 Synthetics", guidefont=9)
vline!([93/122], color=controlred, label="Equal Weights Baseline", style=:dot, linewidth=2)
savefig("C:\\Users\\kevin\\Desktop\\IMF\\AERInsights\\Figures\\Histogram_PWT.pdf")

## MAKE TABLE OF NON-TARGETED MOMENTS
#First keep any obs that have full growth rates
EligibleDonors = NoIMFCrises
EligibleDonors[:ID] = collect(1:1:size(EligibleDonors)[1])
tabletemp = [growths; :ID]
CompleteDonors = EligibleDonors[:, tabletemp]
CompleteDonors = CompleteDonors[completecases(CompleteDonors), :]
EligibleDonors = join(EligibleDonors, CompleteDonors, on=:ID, kind=:inner)

## NOW MAKE TABLE
foravg = [:EXDEBT, :CAB, :ToT, :GDPRank, :pop, :Gshare, :Infl]
k = length(foravg)
avg = ones(k,2)
dataset = (TreatedMatched, EligibleDonors)
for h = 1:k
	for (y,z) in enumerate(dataset)
		if y==1
		weightsforaverage = (1/size(TreatedMatched)[1])*ones(size(TreatedMatched)[1])
		else
		weightsforaverage = weightsum/sum(weightsum)
		end
	values = convert(Array, z[foravg[h]])
		for j = 1:size(z)[1]
			if typeof(z[j,foravg[h]])==Missing
			values[j] = 0
			weightsforaverage[j]=0
			end
		end
	weightsforaverage = weightsforaverage/sum(weightsforaverage)
	avg[h,y] = weightsforaverage'*values
	end
end 

AvgTable = ["" "Treated" "Synthetics"; foravg avg]

PreDiff = DataFrame(Country= TreatedMatched[:Country], year = TreatedMatched[:year], PreReal = TreatedMatched[:DWDI], PreSynth = Synthetics[:DWDI])
scatter(PreDiff[:PreReal], PreDiff[:PreSynth], xlabel="Actual t-2 Growth Rate", ylabel="Synthetic t-2 Growth Rate", label="", markersize=1.5, legend=:topleft)
tempx = collect(-10:.05:12)
tempy = tempx
ylo = tempx .- 2.5
yhi = tempx .+ 2.5
plot!(tempx, tempy, label="y=x", style=:solid, color=:black, ylims=(-15, 15))
savefig("C:\\Users\\kevin\\Desktop\\IMF\\AERInsights\\Figures\\Diagnostic.pdf")
plot!(tempx,[ylo yhi], label=["+/- 2.5" ""], style=[:dot :dot], color=:black, ylims=(-15,15))
savefig("C:\\Users\\kevin\\Desktop\\IMF\\AERInsights\\Figures\\DiagnosticRobustness_PWT.pdf")

## BEFORE/AFTER GROWTH RATES

TreatedGrowthRatesArray		= convert(Array, TreatedMatched[growths])
NMainRuns					= size(TreatedMatched)[1]
println("The number of treated observations with synthetic controls is $NMainRuns")
SyntheticsGrowthRatesArray 	= convert(Array, Synthetics[growths])
MeanTreatedVsSynthetics		= zeros(size(growths)[1],2)
		for j = 1:size(growths)[1]
				MeanTreatedVsSynthetics[j,1] = mean(TreatedGrowthRatesArray[:,j])
				MeanTreatedVsSynthetics[j,2] = mean(SyntheticsGrowthRatesArray[:,j])
		end
plot(t, MeanTreatedVsSynthetics, linewidth=[2.5 2], color=[treatedblue controlred], label=["Treated" "Synthetic"],xticks=collect(-5:1:5), ylabel="Percentage Points", xlabel="Years Since Crisis", style=[:solid :dashdot], legend=:bottomleft)
vline!([0], linestyle=:dash, linewidth=.75, color=:black, label="")
savefig("C:\\Users\\kevin\\Desktop\\IMF\\AERInsights\\Figures\\TreatedGrowthRates_PWT.pdf")


for z = (TreatedMatched, Synthetics)
      z[:PostGrowth1] = map((x1) -> 100*(1+x1/100 -1), z[:FGrowth1])
      z[:PostGrowth2] = map((x1,x2) -> 100*((1+x1/100)*(1+x2/100) -1), z[:FGrowth1], z[:FGrowth2])
      z[:PostGrowth3] = map((x1,x2,x3) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3])
      z[:PostGrowth4] = map((x1,x2,x3,x4) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100)*(1+x4/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3], z[:FGrowth4])
      z[:PostGrowth5] = map((x1,x2,x3,x4,x5) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100)*(1+x4/100)*(1+x5/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3], z[:FGrowth4], z[:FGrowth5])
end

MainDiffDataFrame = DataFrame(Country = TreatedMatched[:Country], year = TreatedMatched[:year])
MainDiffDataFrame[:LevelDiff1] = map((x1, x2) -> x1-x2, TreatedMatched[:PostGrowth1], Synthetics[:PostGrowth1])
MainDiffDataFrame[:LevelDiff2] = map((x1, x2) -> x1-x2, TreatedMatched[:PostGrowth2], Synthetics[:PostGrowth2])
MainDiffDataFrame[:LevelDiff3] = map((x1, x2) -> x1-x2, TreatedMatched[:PostGrowth3], Synthetics[:PostGrowth3])
MainDiffDataFrame[:LevelDiff4] = map((x1, x2) -> x1-x2, TreatedMatched[:PostGrowth4], Synthetics[:PostGrowth4])
MainDiffDataFrame[:LevelDiff5] = map((x1, x2) -> x1-x2, TreatedMatched[:PostGrowth5], Synthetics[:PostGrowth5])
MainBetas = zeros(5)
N = size(MainDiffDataFrame)[1]
LDs = [:LevelDiff1, :LevelDiff2, :LevelDiff3, :LevelDiff4, :LevelDiff5]
		for (z, w) in enumerate(LDs)
			MainBetas[z] = mean(MainDiffDataFrame[w])
		end
BetasWithStdErrors = zeros(5,2)
		for k = 1:5
			BetasWithStdErrors[k,1] = MainBetas[k] - sqrt(NullCovariance[k,k]/N)
			BetasWithStdErrors[k,2] = MainBetas[k] + sqrt(NullCovariance[k,k]/N)
		end

plot(collect(0:1:5), [0; MainBetas], linewidth=2.5, color=:black, label="", ylabel="Increase in Output (%)", xlabel="Years From Crisis", marker=([:circle], [:black], [2.5]))
plot!(collect(0:1:5), [[0; BetasWithStdErrors[:,1]] [0; BetasWithStdErrors[:,2]]], color=:gray, linestyle = :dot, label=["1 s.d." ""], legend=:bottomleft, ylims=(-2.75, 3.5))
hline!([0], color=:black, style=:dot, label="")
savefig("C:\\Users\\kevin\\Desktop\\IMF\\AERInsights\\Figures\\MainIRF_PWT.pdf")

density(MainDiffDataFrame[:LevelDiff1], color=treatedblue, style=:dot, label="t=1", linewidth=2, ylabel="Density")
density!(MainDiffDataFrame[:LevelDiff2], color=treatedblue, yticks=nothing, xlabel="Level Difference", label="t=2", legend=:topleft, style=:solid, linewidth=2)
density!(MainDiffDataFrame[:LevelDiff3], color=treatedblue, style=:dashdot, label="t=3", linewidth=2)
vline!([0], color=:black, style=:dot, label="")
savefig("C:\\Users\\kevin\\Desktop\\IMF\\AERInsights\\Figures\\MainDensity_PWT.pdf")

## HETEROGENEITY (IS IT IMPORTANT?)
#Institution = :CPIA
#MainDiffDataFrame[:Institution] = TreatedMatched[Institution]
#InstDataFrame = MainDiffDataFrame[completecases(MainDiffDataFrame),:]
#scatter(InstDataFrame[:Institution], [InstDataFrame[:LevelDiff2] InstDataFrame[:LevelDiff3]],
#marker = [:circle :triangle], color=treatedblue, markersize=2, smooth=true,
#ylabel="Growth Difference Between Actual\\Synthetic", xlabel="Institutional Quality", guidefont=9 )

#####################################################		
# FORECAST CHECKS							   		#
#####################################################
AllData[:ActualOneYrGrowth] = map((x1) -> 100*(1+x1/100 -1), AllData[:FGrowth1])
AllData[:ForecastedOneYrGrowth] = map((x1) -> 100*(1+x1/100 -1), AllData[:Fcast1])
AllData[:ActualTwoYrGrowth] = map((x1, x2) -> 100*((1+x1/100)*(1+x2/100) -1), AllData[:FGrowth1], AllData[:FGrowth2])
AllData[:ForecastedTwoYrGrowth] = map((x1, x2) -> 100*((1+x1/100)*(1+x2/100) -1), AllData[:Fcast1], AllData[:Fcast2])
AllData[:ActualThreeYrGrowth] = map((x1, x2, x3) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100) -1), AllData[:FGrowth1], AllData[:FGrowth2], AllData[:FGrowth3])
AllData[:ForecastedThreeYrGrowth] = map((x1, x2, x3) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100) -1), AllData[:Fcast1], AllData[:Fcast2], AllData[:Fcast3])
AllData[:ActualFourYrGrowth] = map((x1, x2, x3, x4) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100)*(1+x4/100) -1), AllData[:FGrowth1], AllData[:FGrowth2], AllData[:FGrowth3], AllData[:FGrowth4])
AllData[:ForecastedFourYrGrowth] = map((x1, x2, x3, x4) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100)*(1+x4/100) -1), AllData[:Fcast1], AllData[:Fcast2], AllData[:Fcast3], AllData[:Fcast4])

ForecastVars = [:IMF, :LGrowth5, :LGrowth4, :LGrowth3, :LGrowth2, :LGrowth1, :DPWT, :ActualOneYrGrowth, :ForecastedOneYrGrowth, :ActualTwoYrGrowth, :ForecastedTwoYrGrowth, :ActualThreeYrGrowth, :ForecastedThreeYrGrowth, :Banking, :Currency, :Debt]
ForecastData = AllData[ForecastVars]
ForecastData = AllData[completecases(ForecastData), :]

## RUN REGRESSIONS
fcontrols1 = [:ForecastedOneYrGrowth, :LGrowth4, :LGrowth2, :DPWT, :Banking, :Currency, :Debt, :IMF]
fcontrols2 = [:ForecastedTwoYrGrowth, :LGrowth4, :LGrowth2, :DPWT, :Banking, :Currency, :Debt, :IMF]
fcontrols3 = [:ForecastedThreeYrGrowth, :LGrowth4, :LGrowth2, :DPWT, :Banking, :Currency, :Debt, :IMF]
fcontrols4 = [:ForecastedFourYrGrowth, :LGrowth4, :LGrowth2, :DPWT, :Banking, :Currency, :Debt, :IMF]
ForecastBetas = ones(4)
sd 			  = ones(4)
tempcontrol 	= convert(Array, ForecastData[fcontrols1])
Y1 				= convert(Array, ForecastData[:ActualOneYrGrowth])
(b, v)			= Regress(Y1, tempcontrol)
tempRegressN    = length(Y1)
println("There are $tempRegressN in the horizon 1 Forecasting regression")
ForecastBetas[1] = b[2]
sd[1]				= sqrt(v[2,2])
tempcontrol 	= convert(Array, ForecastData[fcontrols2])
Y2 				= convert(Array, ForecastData[:ActualTwoYrGrowth])
tempRegressN    = length(Y2)
println("There are $tempRegressN in the horizon 2 Forecasting regression")
(b, v)			= Regress(Y2, tempcontrol)
ForecastBetas[2] = b[2]
sd[2]		= sqrt(v[2,2])
tempcontrol 	= convert(Array, ForecastData[fcontrols3])
Y3 				= convert(Array, ForecastData[:ActualThreeYrGrowth])
(b, v)			= Regress(Y3, tempcontrol)
ForecastBetas[3] = b[2] 
tempRegressN    = length(Y3)
println("There are $tempRegressN in the horizon 3 Forecasting regression")
sd[3]				= sqrt(v[2,2])
tempcontrol 	= convert(Array, ForecastData[fcontrols4])
Y4 				= convert(Array, ForecastData[:ActualFourYrGrowth])
tempRegressN    = length(Y4)
println("There are $tempRegressN in the horizon 4 Forecasting regression")
(b, v)			= Regress(Y4, tempcontrol)
ForecastBetas[4] = b[2] 
sd[4]		= sqrt(v[2,2])

######################################################
# IRF ROBUSTNESS SECTION 							##
######################################################

RobustnessChecks = ["LP" "CAB" "Infl" "Debt" "PWT" "WideBounds" "TightBounds" "GoodMatches" "Optimal Weights"]
Z = zeros(6,length(RobustnessChecks))
RobustnessChecks = [RobustnessChecks; Z]

## GOING TO NEED TO RE-RUN MANY TIMES, STORE BETAS, REPLOT IRF

## LOCAL PROJECTION
LPVars = [:LGrowth5, :LGrowth4, :LGrowth3, :LGrowth2, :LGrowth1, :DPWT, :FGrowth1, :FGrowth2, :FGrowth3, :FGrowth4, :FGrowth5, :Banking, :Currency, :Debt, :IMF]
LPData = AllData[:, LPVars]
LPData = LPData[completecases(LPData), :]
# REGRESSIONS HERE
controlvars = [:IMF, :LGrowth5, :LGrowth4, :LGrowth3, :LGrowth2, :LGrowth1, :DWDI, :Banking, :Currency, :Debt]
ControlMatrix = convert(Array, LPData[:, controlvars])
FGrowths = [:FGrowth1, :FGrowth2, :FGrowth3, :FGrowth4, :FGrowth5]
for (h, g) in enumerate(FGrowths)
		Y = convert(Array, LPData[g])
		(Bhat, Varhat) = Regress(Y, ControlMatrix)
		RobustnessChecks[h+2, 1] = Bhat[1]
end

## WITH CURRENT ACCOUNT BALANCE
matchon = [:LGrowth5, :LGrowth4, :LGrowth3, :LGrowth2, :LGrowth1, :DPWT, :Banking, :Currency, :Debt, :CAB]
bounds  = [7, 7, 7, 7, 7, 7, .5, .5, .5, Inf]
(Treated_CAB, Synthetics_CAB, Weights_CAB) = GenSynthetics(IMFCrises, NoIMFCrises, matchon, predict, localtol=bounds, matchweights=W);

for z = (Treated_CAB, Synthetics_CAB)
      z[:PostGrowth1] = map((x1) -> 100*(1+x1/100 -1), z[:FGrowth1])
      z[:PostGrowth2] = map((x1,x2) -> 100*((1+x1/100)*(1+x2/100) -1), z[:FGrowth1], z[:FGrowth2])
      z[:PostGrowth3] = map((x1,x2,x3) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3])
      z[:PostGrowth4] = map((x1,x2,x3,x4) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100)*(1+x4/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3], z[:FGrowth4])
      z[:PostGrowth5] = map((x1,x2,x3,x4,x5) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100)*(1+x4/100)*(1+x5/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3], z[:FGrowth4], z[:FGrowth5])
end

TempDiffDataFrame = DataFrame(Country = Treated_CAB[:Country], year = Treated_CAB[:year])
TempDiffDataFrame[:LevelDiff1] = map((x1, x2) -> x1-x2, Treated_CAB[:PostGrowth1], Synthetics_CAB[:PostGrowth1])
TempDiffDataFrame[:LevelDiff2] = map((x1, x2) -> x1-x2, Treated_CAB[:PostGrowth2], Synthetics_CAB[:PostGrowth2])
TempDiffDataFrame[:LevelDiff3] = map((x1, x2) -> x1-x2, Treated_CAB[:PostGrowth3], Synthetics_CAB[:PostGrowth3])
TempDiffDataFrame[:LevelDiff4] = map((x1, x2) -> x1-x2, Treated_CAB[:PostGrowth4], Synthetics_CAB[:PostGrowth4])
TempDiffDataFrame[:LevelDiff5] = map((x1, x2) -> x1-x2, Treated_CAB[:PostGrowth5], Synthetics_CAB[:PostGrowth5])
LDs = [:LevelDiff1, :LevelDiff2, :LevelDiff3, :LevelDiff4, :LevelDiff5]
		for (z, w) in enumerate(LDs)
			RobustnessChecks[z+2,2] = mean(TempDiffDataFrame[w])
		end

## WITH INFLATION
matchon = [:LGrowth5, :LGrowth4, :LGrowth3, :LGrowth2, :LGrowth1, :DPWT, :Banking, :Currency, :Debt, :Infl]
bounds  = [7, 7, 7, 7, 7, 7, .5, .5, .5, Inf]
(Treated_Infl, Synthetics_Infl, Weights_Infl) = GenSynthetics(IMFCrises, NoIMFCrises, matchon, predict, localtol=bounds, matchweights=W);

for z = (Treated_Infl, Synthetics_Infl)
      z[:PostGrowth1] = map((x1) -> 100*(1+x1/100 -1), z[:FGrowth1])
      z[:PostGrowth2] = map((x1,x2) -> 100*((1+x1/100)*(1+x2/100) -1), z[:FGrowth1], z[:FGrowth2])
      z[:PostGrowth3] = map((x1,x2,x3) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3])
      z[:PostGrowth4] = map((x1,x2,x3,x4) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100)*(1+x4/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3], z[:FGrowth4])
      z[:PostGrowth5] = map((x1,x2,x3,x4,x5) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100)*(1+x4/100)*(1+x5/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3], z[:FGrowth4], z[:FGrowth5])
end

TempDiffDataFrame = DataFrame(Country = Treated_Infl[:Country], year = Treated_Infl[:year])
TempDiffDataFrame[:LevelDiff1] = map((x1, x2) -> x1-x2, Treated_Infl[:PostGrowth1], Synthetics_Infl[:PostGrowth1])
TempDiffDataFrame[:LevelDiff2] = map((x1, x2) -> x1-x2, Treated_Infl[:PostGrowth2], Synthetics_Infl[:PostGrowth2])
TempDiffDataFrame[:LevelDiff3] = map((x1, x2) -> x1-x2, Treated_Infl[:PostGrowth3], Synthetics_Infl[:PostGrowth3])
TempDiffDataFrame[:LevelDiff4] = map((x1, x2) -> x1-x2, Treated_Infl[:PostGrowth4], Synthetics_Infl[:PostGrowth4])
TempDiffDataFrame[:LevelDiff5] = map((x1, x2) -> x1-x2, Treated_Infl[:PostGrowth5], Synthetics_Infl[:PostGrowth5])
LDs = [:LevelDiff1, :LevelDiff2, :LevelDiff3, :LevelDiff4, :LevelDiff5]
		for (z, w) in enumerate(LDs)
			RobustnessChecks[z+2,3] = mean(TempDiffDataFrame[w])
		end

## WITH EXDEBT
matchon = [:LGrowth5, :LGrowth4, :LGrowth3, :LGrowth2, :LGrowth1, :DPWT, :Banking, :Currency, :Debt, :EXDEBT]
bounds  = [7, 7, 7, 7, 7, 7, .5, .5, .5, Inf]
(Treated_EXDEBT, Synthetics_EXDEBT, Weights_EXDEBT) = GenSynthetics(IMFCrises, NoIMFCrises, matchon, predict, localtol=bounds, matchweights=W);

for z = (Treated_EXDEBT, Synthetics_EXDEBT)
      z[:PostGrowth1] = map((x1) -> 100*(1+x1/100 -1), z[:FGrowth1])
      z[:PostGrowth2] = map((x1,x2) -> 100*((1+x1/100)*(1+x2/100) -1), z[:FGrowth1], z[:FGrowth2])
      z[:PostGrowth3] = map((x1,x2,x3) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3])
      z[:PostGrowth4] = map((x1,x2,x3,x4) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100)*(1+x4/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3], z[:FGrowth4])
      z[:PostGrowth5] = map((x1,x2,x3,x4,x5) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100)*(1+x4/100)*(1+x5/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3], z[:FGrowth4], z[:FGrowth5])
end

TempDiffDataFrame = DataFrame(Country = Treated_EXDEBT[:Country], year = Treated_EXDEBT[:year])
TempDiffDataFrame[:LevelDiff1] = map((x1, x2) -> x1-x2, Treated_EXDEBT[:PostGrowth1], Synthetics_EXDEBT[:PostGrowth1])
TempDiffDataFrame[:LevelDiff2] = map((x1, x2) -> x1-x2, Treated_EXDEBT[:PostGrowth2], Synthetics_EXDEBT[:PostGrowth2])
TempDiffDataFrame[:LevelDiff3] = map((x1, x2) -> x1-x2, Treated_EXDEBT[:PostGrowth3], Synthetics_EXDEBT[:PostGrowth3])
TempDiffDataFrame[:LevelDiff4] = map((x1, x2) -> x1-x2, Treated_EXDEBT[:PostGrowth4], Synthetics_EXDEBT[:PostGrowth4])
TempDiffDataFrame[:LevelDiff5] = map((x1, x2) -> x1-x2, Treated_EXDEBT[:PostGrowth5], Synthetics_EXDEBT[:PostGrowth5])
LDs = [:LevelDiff1, :LevelDiff2, :LevelDiff3, :LevelDiff4, :LevelDiff5]
		for (z, w) in enumerate(LDs)
			RobustnessChecks[z+2,4] = mean(TempDiffDataFrame[w])
		end

## USING PWT INSTEAD

## Wide Bounds LOCAL RESTRICTION
matchon = [:LGrowth5, :LGrowth4, :LGrowth3, :LGrowth2, :LGrowth1, :DPWT, :Banking, :Currency, :Debt]
bounds  = [9, 9, 9, 9, 9, 9, .5, .5, .5]
(Treated_WideBounds, Synthetics_WideBounds, Weights_WideBounds) = GenSynthetics(IMFCrises, NoIMFCrises, matchon, predict, localtol=bounds, matchweights=W);

for z = (Treated_WideBounds, Synthetics_WideBounds)
      z[:PostGrowth1] = map((x1) -> 100*(1+x1/100 -1), z[:FGrowth1])
      z[:PostGrowth2] = map((x1,x2) -> 100*((1+x1/100)*(1+x2/100) -1), z[:FGrowth1], z[:FGrowth2])
      z[:PostGrowth3] = map((x1,x2,x3) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3])
      z[:PostGrowth4] = map((x1,x2,x3,x4) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100)*(1+x4/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3], z[:FGrowth4])
      z[:PostGrowth5] = map((x1,x2,x3,x4,x5) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100)*(1+x4/100)*(1+x5/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3], z[:FGrowth4], z[:FGrowth5])
end

TempDiffDataFrame = DataFrame(Country = Treated_WideBounds[:Country], year = Treated_WideBounds[:year])
TempDiffDataFrame[:LevelDiff1] = map((x1, x2) -> x1-x2, Treated_WideBounds[:PostGrowth1], Synthetics_WideBounds[:PostGrowth1])
TempDiffDataFrame[:LevelDiff2] = map((x1, x2) -> x1-x2, Treated_WideBounds[:PostGrowth2], Synthetics_WideBounds[:PostGrowth2])
TempDiffDataFrame[:LevelDiff3] = map((x1, x2) -> x1-x2, Treated_WideBounds[:PostGrowth3], Synthetics_WideBounds[:PostGrowth3])
TempDiffDataFrame[:LevelDiff4] = map((x1, x2) -> x1-x2, Treated_WideBounds[:PostGrowth4], Synthetics_WideBounds[:PostGrowth4])
TempDiffDataFrame[:LevelDiff5] = map((x1, x2) -> x1-x2, Treated_WideBounds[:PostGrowth5], Synthetics_WideBounds[:PostGrowth5])
LDs = [:LevelDiff1, :LevelDiff2, :LevelDiff3, :LevelDiff4, :LevelDiff5]
		for (z, w) in enumerate(LDs)
			RobustnessChecks[z+2,6] = mean(TempDiffDataFrame[w])
		end

## Tight Bounds LOCAL RESTRICTION
matchon = [:LGrowth5, :LGrowth4, :LGrowth3, :LGrowth2, :LGrowth1, :DPWT, :Banking, :Currency, :Debt]
bounds  = [5, 5, 5, 5, 5, 5, .5, .5, .5]
(Treated_TightBounds, Synthetics_TightBounds, Weights_TightBounds) = GenSynthetics(IMFCrises, NoIMFCrises, matchon, predict, localtol=bounds, matchweights=W);

for z = (Treated_TightBounds, Synthetics_TightBounds)
      z[:PostGrowth1] = map((x1) -> 100*(1+x1/100 -1), z[:FGrowth1])
      z[:PostGrowth2] = map((x1,x2) -> 100*((1+x1/100)*(1+x2/100) -1), z[:FGrowth1], z[:FGrowth2])
      z[:PostGrowth3] = map((x1,x2,x3) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3])
      z[:PostGrowth4] = map((x1,x2,x3,x4) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100)*(1+x4/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3], z[:FGrowth4])
      z[:PostGrowth5] = map((x1,x2,x3,x4,x5) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100)*(1+x4/100)*(1+x5/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3], z[:FGrowth4], z[:FGrowth5])
end

TempDiffDataFrame = DataFrame(Country = Treated_TightBounds[:Country], year = Treated_TightBounds[:year])
TempDiffDataFrame[:LevelDiff1] = map((x1, x2) -> x1-x2, Treated_TightBounds[:PostGrowth1], Synthetics_TightBounds[:PostGrowth1])
TempDiffDataFrame[:LevelDiff2] = map((x1, x2) -> x1-x2, Treated_TightBounds[:PostGrowth2], Synthetics_TightBounds[:PostGrowth2])
TempDiffDataFrame[:LevelDiff3] = map((x1, x2) -> x1-x2, Treated_TightBounds[:PostGrowth3], Synthetics_TightBounds[:PostGrowth3])
TempDiffDataFrame[:LevelDiff4] = map((x1, x2) -> x1-x2, Treated_TightBounds[:PostGrowth4], Synthetics_TightBounds[:PostGrowth4])
TempDiffDataFrame[:LevelDiff5] = map((x1, x2) -> x1-x2, Treated_TightBounds[:PostGrowth5], Synthetics_TightBounds[:PostGrowth5])
LDs = [:LevelDiff1, :LevelDiff2, :LevelDiff3, :LevelDiff4, :LevelDiff5]
		for (z, w) in enumerate(LDs)
			RobustnessChecks[z+2,7] = mean(TempDiffDataFrame[w])
		end

## ONLY GOOD MATCHES
#DiffDataFrame[:]



## USING OPTIMAL WEIGHTING MATRIX
matchon = [:LGrowth5, :LGrowth4, :LGrowth3, :LGrowth2, :LGrowth1, :DPWT, :Banking, :Currency, :Debt]
bounds  = [7, 7, 7, 7, 7, 7, .5, .5, .5]
OptW 	= [1.7; .5; .1; .1; .3; 1.0; 1.0; 1.0; 1.0]  # Need 3 for 
(Treated_OptWeights, Synthetics_OptWeights, Weights_OptWeights) = GenSynthetics(IMFCrises, NoIMFCrises, matchon, predict, localtol=bounds, matchweights=OptW);

for z = (Treated_OptWeights, Synthetics_OptWeights)
      z[:PostGrowth1] = map((x1) -> 100*(1+x1/100 -1), z[:FGrowth1])
      z[:PostGrowth2] = map((x1,x2) -> 100*((1+x1/100)*(1+x2/100) -1), z[:FGrowth1], z[:FGrowth2])
      z[:PostGrowth3] = map((x1,x2,x3) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3])
      z[:PostGrowth4] = map((x1,x2,x3,x4) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100)*(1+x4/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3], z[:FGrowth4])
      z[:PostGrowth5] = map((x1,x2,x3,x4,x5) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100)*(1+x4/100)*(1+x5/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3], z[:FGrowth4], z[:FGrowth5])
end

TempDiffDataFrame = DataFrame(Country = Treated_OptWeights[:Country], year = Treated_OptWeights[:year])
TempDiffDataFrame[:LevelDiff1] = map((x1, x2) -> x1-x2, Treated_OptWeights[:PostGrowth1], Synthetics_OptWeights[:PostGrowth1])
TempDiffDataFrame[:LevelDiff2] = map((x1, x2) -> x1-x2, Treated_OptWeights[:PostGrowth2], Synthetics_OptWeights[:PostGrowth2])
TempDiffDataFrame[:LevelDiff3] = map((x1, x2) -> x1-x2, Treated_OptWeights[:PostGrowth3], Synthetics_OptWeights[:PostGrowth3])
TempDiffDataFrame[:LevelDiff4] = map((x1, x2) -> x1-x2, Treated_OptWeights[:PostGrowth4], Synthetics_OptWeights[:PostGrowth4])
TempDiffDataFrame[:LevelDiff5] = map((x1, x2) -> x1-x2, Treated_OptWeights[:PostGrowth5], Synthetics_OptWeights[:PostGrowth5])
LDs = [:LevelDiff1, :LevelDiff2, :LevelDiff3, :LevelDiff4, :LevelDiff5]
		for (z, w) in enumerate(LDs)
			RobustnessChecks[z+2,9] = mean(TempDiffDataFrame[w])
		end 

## GRAPH WITH ALL ROBUSTNESS
plot(collect(0:1:5), [0; MainBetas], linewidth=2, color=:black, label="", ylabel="", xlabel="Years From Crisis", legend=:bottomleft, legendfontsize=7, ylims=(-2.75,3.5), marker=([:circle], [:black], [2.5]))
plot!(collect(0:1:5), RobustnessChecks[2:end, 2], linewidth=1.5, color=:red, style=:dashdot, label="+CAB", marker=([:circle], [:red], [2]))
plot!(collect(0:1:5), RobustnessChecks[2:end, 3], linewidth=1.5, color=:green, style=:dashdot, label="+Infl",  marker=([:rect], [:green], [2]))
plot!(collect(0:1:5), RobustnessChecks[2:end, 4], linewidth=1.5, color=:blue, style=:dashdot, label="+Debt",  marker=([:xcross], [:blue], [2]))
plot!(collect(0:1:5), RobustnessChecks[2:end, 6], linewidth=1.5, color=:pink, style=:dashdot, label="Wide Bounds",  marker=([:utriangle], [:pink], [2]))
plot!(collect(0:1:5), RobustnessChecks[2:end, 7], linewidth=1.5, color=:gold, style=:dashdot, label="Tight Bounds",  marker=([:star4], [:gold], [2]))
plot!(collect(0:1:5), RobustnessChecks[2:end, 9], linewidth=1.5, color=:brown, style=:dashdot, label="Optimal Weights",  marker=([:+], [:brown], [2]))
hline!([0], color=:black, style=:dot, label="")
savefig("C:\\Users\\kevin\\Desktop\\IMF\\AERInsights\\Figures\\RobustIRF_PWT.pdf")


