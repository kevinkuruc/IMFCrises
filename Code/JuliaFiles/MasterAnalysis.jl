#############################################################
# This is a master file that runs all analysis for          #
# "Are IMF Rescue Packages Effective? Evidence From Crises" #
#  All findings and figures can be produced by running this #
# code with the appropriate data and julia functions within #
# the folder.                                               #
#############################################################

directory = dirname(dirname(pwd()))
code_directory = joinpath(directory, "Code", "JuliaFiles")
data_directory = joinpath(directory, "Data")
output_directory = joinpath(directory, "Results")
mkpath(output_directory)

using Plots
using Statistics
using ColorTypes
using DataFrames
using CSV
using Ipopt
using NLopt
using LinearAlgebra
using StatsPlots
using Distributions
include(joinpath(code_directory, "LinearRegression.jl"))
include(joinpath(code_directory, "RunningPlacebosFunction.jl"))
include(joinpath(code_directory, "Crisis_Heterogeneity.jl"))
include(joinpath(code_directory, "Heterogeneity_Correlation.jl"))


#############################################################
# Things to define for entire paper                         #
#############################################################
t = collect(-5:1:6)
growths = [:LGrowth5, :LGrowth4, :LGrowth3, :LGrowth2, :LGrowth1, :DWDI, :FGrowth1, :FGrowth2, :FGrowth3, :FGrowth4, :FGrowth5, :FGrowth6]
treatedblue = :black
controlred = RGB(120/255, 120/255, 120/255)


#############################################################
# Summary Stats												#
#############################################################

## LOAD IN ALL IMF LOAN GROWTH RATES CENTERED AROUND THEIR LOAN
LoanPath = CSV.read(joinpath(data_directory, "created", "AvgPathLoans.csv"))
tempk = [:AmountAgreedPercentGDP, :year]
LoanSizes  = LoanPath[:, tempk]
LoanSizes  = LoanSizes[completecases(LoanSizes),:]
LoanSizes  = LoanSizes[LoanSizes[:AmountAgreedPercentGDP].>0,:]
AvgSize = mean(LoanSizes[:AmountAgreedPercentGDP])
MedSize = median(LoanSizes[:AmountAgreedPercentGDP])
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
savefig(joinpath(output_directory, "SummaryPath.pdf"))

#########################################################################################
#  Make Graph with Financial Crisis & Split to With/Without                             #
#########################################################################################

AllData					= CSV.read(joinpath(data_directory, "created", "MasterData.csv"))
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
plot(t[1:11], CrisisPaths[1:11,1], legend=:bottomright, label="", color=:black, style=:solid, linewidth=2, ylim=(0, 4.4))
vline!([0], color=:black, label="", style=:dot)
xticks!(t)
xlabel!("Years Since Crisis")
ylabel!("GDP Growth (%)")
annotate!([(0, 3.4, text("Crisis Date", 9, :black, :left))])
savefig(joinpath(output_directory, "AvgPathCrises_AllCrises.pdf"))

plot(t[1:11], CrisisPaths[1:11,2:3], legend=:bottomright, label=["W/ IMF" "W/o IMF"], color=[treatedblue controlred], style=[:solid :dashdot], linewidth=[2 2], ylim=(0, 4.4))
vline!([0], color=:black, label="", style=:dot)
xticks!(t)
xlabel!("Years Since Crisis")
ylabel!("GDP Growth (%)")
savefig(joinpath(output_directory, "AvgPathCrises_WithWithout.pdf"))

#########################################################################################
# Run Synthetic Control and Make Graphs (Both Main and Appendix)						#
#########################################################################################

## FIRST DEFINE MAIN SPECIFICATION FOR CONSTRUCTING SYNTHETIC CONTROLS
W 		= ones(10,1)  #diaganol of weighting matrix (equal weights in baseline)
matchon = [:LGrowth5, :LGrowth4, :LGrowth3, :LGrowth2, :LGrowth1, :DWDI, :Banking, :Currency, :Debt]
predict = [:FGrowth1, :FGrowth2, :FGrowth3, :FGrowth4, :FGrowth5, :FGrowth6]
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
NullErrors[:PostError6] = map((x,y) -> x-y, Placebos[:PostGrowth6], SyntheticPlacebos[:PostGrowth6])

NullErrorsArray			= convert(Array, [NullErrors[:PostError1] NullErrors[:PostError2] NullErrors[:PostError3] NullErrors[:PostError4] NullErrors[:PostError5] NullErrors[:PostError6]])

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
savefig(joinpath(output_directory, "PlaceboGrowthRates.pdf"))


## NOW THAT I HAVE NULL VARIANCES I CAN MOVE TO RUNNING ACTUAL SYNTHETICS
(TreatedMatched, Synthetics, DonorWeights) = GenSynthetics(IMFCrises, NoIMFCrises, matchon, predict, localtol=bounds, matchweights=W);

## PRESENT SOME MATCH 'DIAGNOSTICS', i.e., WHO ACTUALLY CAN GET MATCHED WELL IN PRE-PERIOD
WeightsArray = convert(Array, DonorWeights[:,4:end])
synthtot = size(WeightsArray)[1]
TotalWeight = zeros(synthtot)
for i = 1:synthtot
    TotalWeight[i] = sum(WeightsArray[i,:])
end
DonorWeights[:TotalWeight] = TotalWeight
culprit = DonorWeights[DonorWeights[:TotalWeight].>3.5, :]
#print(culprit)  # Its Venezuala 1982 who didn't have a big collapse
histogram(TotalWeight, bins=30, xticks=collect(0:1:5), color=treatedblue, label="", ylabel="Frequency"
, xlabel="Total (Sum) of Weights in the 99 Synthetics", guidefont=9)
vline!([size(TreatedMatched)[1]/NNoIMF], color=controlred, label="Equal Weights Baseline", style=:dot, linewidth=2)
savefig(joinpath(output_directory, "Histogram.pdf"))

## MAKE TABLE OF NON-TARGETED MOMENTS
#First keep any obs that have full growth rates
EligibleDonors = NoIMFCrises
EligibleDonors[:ID] = collect(1:1:size(EligibleDonors)[1])
tabletemp = [growths; :ID]
CompleteDonors = EligibleDonors[:, tabletemp]
CompleteDonors = CompleteDonors[completecases(CompleteDonors), :]
EligibleDonors = join(EligibleDonors, CompleteDonors, on=:ID, kind=:inner, makeunique=true)

## NOW MAKE TABLE
foravg = [:EXDEBT, :CAB, :GDPRank, :pop, :Gshare, :Infl]
k = length(foravg)
avg = ones(k,2)
dataset = (TreatedMatched, EligibleDonors)
for h = 1:k
	for (y,z) in enumerate(dataset)
		if y==1
		weightsforaverage = (1/size(TreatedMatched)[1])*ones(size(TreatedMatched)[1])
		else
		weightsforaverage = TotalWeight./sum(TotalWeight)
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
savefig(joinpath(output_directory, "Diagnostic.pdf"))
plot!(tempx,[ylo yhi], label=["+/- 2.5" ""], style=[:dot :dot], color=:black, ylims=(-15,15))
savefig(joinpath(output_directory, "DiagnosticRobustness.pdf"))

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
plot(t, MeanTreatedVsSynthetics, linewidth=[2.5 2], color=[treatedblue controlred], label=["Treated" "Synthetic"],xticks=collect(-5:1:size(predict)[1]), ylabel="Percentage Points", xlabel="Years Since Crisis", style=[:solid :dashdot], legend=:bottomleft)
vline!([0], linestyle=:dashdot, linewidth=.75, color=:black, label="")
savefig(joinpath(output_directory, "TreatedGrowthRates.pdf"))


for z = (TreatedMatched, Synthetics)
      z[:PostGrowth1] = map((x1) -> 100*(1+x1/100 -1), z[:FGrowth1])
      z[:PostGrowth2] = map((x1,x2) -> 100*((1+x1/100)*(1+x2/100) -1), z[:FGrowth1], z[:FGrowth2])
      z[:PostGrowth3] = map((x1,x2,x3) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3])
      z[:PostGrowth4] = map((x1,x2,x3,x4) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100)*(1+x4/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3], z[:FGrowth4])
      z[:PostGrowth5] = map((x1,x2,x3,x4,x5) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100)*(1+x4/100)*(1+x5/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3], z[:FGrowth4], z[:FGrowth5])
      z[:PostGrowth6] = map((x1,x2,x3,x4,x5, x6) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100)*(1+x4/100)*(1+x5/100)*(1+x6/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3], z[:FGrowth4], z[:FGrowth5], z[:FGrowth6])
end

MainDiffDataFrame = DataFrame(Country = TreatedMatched[:Country], year = TreatedMatched[:year])
MainDiffDataFrame[:LevelDiff1] = map((x1, x2) -> x1-x2, TreatedMatched[:PostGrowth1], Synthetics[:PostGrowth1])
MainDiffDataFrame[:LevelDiff2] = map((x1, x2) -> x1-x2, TreatedMatched[:PostGrowth2], Synthetics[:PostGrowth2])
MainDiffDataFrame[:LevelDiff3] = map((x1, x2) -> x1-x2, TreatedMatched[:PostGrowth3], Synthetics[:PostGrowth3])
MainDiffDataFrame[:LevelDiff4] = map((x1, x2) -> x1-x2, TreatedMatched[:PostGrowth4], Synthetics[:PostGrowth4])
MainDiffDataFrame[:LevelDiff5] = map((x1, x2) -> x1-x2, TreatedMatched[:PostGrowth5], Synthetics[:PostGrowth5])
MainDiffDataFrame[:LevelDiff6] = map((x1, x2) -> x1-x2, TreatedMatched[:PostGrowth6], Synthetics[:PostGrowth6])
MainBetas = zeros(size(predict)[1])
N = size(MainDiffDataFrame)[1]
LDs = [:LevelDiff1, :LevelDiff2, :LevelDiff3, :LevelDiff4, :LevelDiff5, :LevelDiff6]
		for (z, w) in enumerate(LDs)
			MainBetas[z] = mean(MainDiffDataFrame[w])
		end
BetasWithStdErrors = zeros(size(predict)[1],2)
		for k = 1:size(predict)[1]
			BetasWithStdErrors[k,1] = MainBetas[k] - sqrt(NullCovariance[k,k]/N)
			BetasWithStdErrors[k,2] = MainBetas[k] + sqrt(NullCovariance[k,k]/N)
		end

#------ Hoteling T-sq for joint significance of first 5 coefficients ------- #
HotellingT = N*MainBetas'*inv(NullCovariance)*MainBetas
TranslatedToFDist = HotellingT*(N-6)/((N-1)*6) 
### Check p value of this number on F-dist(6,N-6)
F = FDist(6, N-6)
PVal = ccdf(F, TranslatedToFDist)

plot(collect(0:1:size(predict)[1]), [0; MainBetas], linewidth=2.5, color=:black, label="", ylabel="Increase in Output (%)", xlabel="Years From Crisis", marker=([:circle], [:black], [2.5]))
plot!(collect(0:1:size(predict)[1]), [[0; BetasWithStdErrors[:,1]] [0; BetasWithStdErrors[:,2]]], color=:gray, linestyle = :dot, label=["1 s.e." ""], legend=:bottomleft, ylims=(-3, 4.75))
hline!([0], color=:black, style=:dot, label="")
savefig(joinpath(output_directory, "MainIRF.pdf"))

density(MainDiffDataFrame[:LevelDiff2], color=treatedblue, yticks=nothing, xlabel="Level Difference", label="t=2", legend=:topleft, style=:solid, linewidth=2)
density!(MainDiffDataFrame[:LevelDiff3], color=treatedblue, style=:dashdot, label="t=3", linewidth=2)
density!(MainDiffDataFrame[:LevelDiff4], color=treatedblue, style=:dot, label="t=4", linewidth=2)
vline!([0], color=:black, style=:dot, label="")
savefig(joinpath(output_directory, "MainDensity.pdf"))

# -------- Cumulative Effect Size By Treated ------- $
TreatedMatched[:CumulativeEffect] = map((x1,x2,x3,x4,x5) -> +(x1, x2, x3, x4, x5), MainDiffDataFrame[:LevelDiff1], MainDiffDataFrame[:LevelDiff2], MainDiffDataFrame[:LevelDiff3], MainDiffDataFrame[:LevelDiff4], MainDiffDataFrame[:LevelDiff5])
MainMean = mean(TreatedMatched[:CumulativeEffect])
println("Average Cumulative Effect is $MainMean")

# -------- Heterogeneity Results ------------------- #

# -- By Crisis -- #
CrisisAverages = ByCrisisType()
HeterogeneityScatter(:WGI)

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

ForecastVars = [:IMF, :LGrowth5, :LGrowth4, :LGrowth3, :LGrowth2, :LGrowth1, :DWDI, :ActualOneYrGrowth, :ForecastedOneYrGrowth, :ActualTwoYrGrowth, :ForecastedTwoYrGrowth, :ActualThreeYrGrowth, :ForecastedThreeYrGrowth, :Banking, :Currency, :Debt]
ForecastData = AllData[ForecastVars]
ForecastData = AllData[completecases(ForecastData), :]

## RUN REGRESSIONS  (edit `fcontrols' here to change which forecasting regression is run)
fcontrols1 = [:ForecastedOneYrGrowth, :LGrowth4, :LGrowth2, :DWDI, :Banking, :Currency, :Debt, :IMF]
fcontrols2 = [:ForecastedTwoYrGrowth, :LGrowth4, :LGrowth2, :DWDI, :Banking, :Currency, :Debt, :IMF]
fcontrols3 = [:ForecastedThreeYrGrowth, :LGrowth4, :LGrowth2, :DWDI, :Banking, :Currency, :Debt, :IMF]
fcontrols4 = [:ForecastedFourYrGrowth, :LGrowth4, :LGrowth2, :DWDI, :Banking, :Currency, :Debt, :IMF]
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

RobustnessChecks = ["LP" "CAB" "Infl" "Debt" "PWT" "WideBounds" "TightBounds" "GoodMatches" "Optimal Weights" "FreeForAll"]
Z = zeros(size(predict)[1]+1,length(RobustnessChecks))
RobustnessChecks = [RobustnessChecks; Z]


## WITH CURRENT ACCOUNT BALANCE
matchon 		= [:LGrowth5, :LGrowth4, :LGrowth3, :LGrowth2, :LGrowth1, :DWDI, :Banking, :Currency, :Debt, :CAB]
completecheck 	= [:Country, :year, :DWDI, :CAB]
tempTreat 		= IMFCrises[:, completecheck]
tempTreat 		= tempTreat[completecases(tempTreat),:]
Treated_wCAB 	= join(IMFCrises, tempTreat, on=[:Country, :year], kind=:inner)
GrowthVariance 	= var(Treated_wCAB[:DWDI])
CABVariance	   	= var(Treated_wCAB[:CAB])
Weights 		= ones(size(matchon))
Weights[end]	= GrowthVariance/CABVariance
bounds  		= [7, 7, 7, 7, 7, 7, .5, .5, .5, Inf]
(Treated_CAB, Synthetics_CAB, Weights_CAB) = GenSynthetics(IMFCrises, NoIMFCrises, matchon, predict, localtol=bounds, matchweights=Weights);

for z = (Treated_CAB, Synthetics_CAB)
      z[:PostGrowth1] = map((x1) -> 100*(1+x1/100 -1), z[:FGrowth1])
      z[:PostGrowth2] = map((x1,x2) -> 100*((1+x1/100)*(1+x2/100) -1), z[:FGrowth1], z[:FGrowth2])
      z[:PostGrowth3] = map((x1,x2,x3) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3])
      z[:PostGrowth4] = map((x1,x2,x3,x4) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100)*(1+x4/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3], z[:FGrowth4])
      z[:PostGrowth5] = map((x1,x2,x3,x4,x5) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100)*(1+x4/100)*(1+x5/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3], z[:FGrowth4], z[:FGrowth5])
      z[:PostGrowth6] = map((x1,x2,x3,x4,x5, x6) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100)*(1+x4/100)*(1+x5/100)*(1+x6/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3], z[:FGrowth4], z[:FGrowth5], z[:FGrowth6])
end

TempDiffDataFrame = DataFrame(Country = Treated_CAB[:Country], year = Treated_CAB[:year])
TempDiffDataFrame[:LevelDiff1] = map((x1, x2) -> x1-x2, Treated_CAB[:PostGrowth1], Synthetics_CAB[:PostGrowth1])
TempDiffDataFrame[:LevelDiff2] = map((x1, x2) -> x1-x2, Treated_CAB[:PostGrowth2], Synthetics_CAB[:PostGrowth2])
TempDiffDataFrame[:LevelDiff3] = map((x1, x2) -> x1-x2, Treated_CAB[:PostGrowth3], Synthetics_CAB[:PostGrowth3])
TempDiffDataFrame[:LevelDiff4] = map((x1, x2) -> x1-x2, Treated_CAB[:PostGrowth4], Synthetics_CAB[:PostGrowth4])
TempDiffDataFrame[:LevelDiff5] = map((x1, x2) -> x1-x2, Treated_CAB[:PostGrowth5], Synthetics_CAB[:PostGrowth5])
TempDiffDataFrame[:LevelDiff6] = map((x1, x2) -> x1-x2, Treated_CAB[:PostGrowth6], Synthetics_CAB[:PostGrowth6])
LDs = [:LevelDiff1, :LevelDiff2, :LevelDiff3, :LevelDiff4, :LevelDiff5, :LevelDiff6]
		for (z, w) in enumerate(LDs)
			RobustnessChecks[z+2,2] = mean(TempDiffDataFrame[w])
		end

## WITH INFLATION
matchon 		= [:LGrowth5, :LGrowth4, :LGrowth3, :LGrowth2, :LGrowth1, :DWDI, :Banking, :Currency, :Debt, :Infl]
completecheck 	= [:Country, :year, :DWDI, :Infl]
tempTreat 		= IMFCrises[:, completecheck]
tempTreat 		= tempTreat[completecases(tempTreat),:]
Treated_wInfl 	= join(IMFCrises, tempTreat, on=[:Country, :year], kind=:inner)
GrowthVariance 	= var(Treated_wInfl[:DWDI])
InflVariance	= var(Treated_wInfl[:Infl])
Weights 		= ones(size(matchon))
Weights[end]	= GrowthVariance/InflVariance
bounds  		= [7, 7, 7, 7, 7, 7, .5, .5, .5, Inf]
(Treated_Infl, Synthetics_Infl, Weights_Infl) = GenSynthetics(IMFCrises, NoIMFCrises, matchon, predict, localtol=bounds, matchweights=Weights);

for z = (Treated_Infl, Synthetics_Infl)
      z[:PostGrowth1] = map((x1) -> 100*(1+x1/100 -1), z[:FGrowth1])
      z[:PostGrowth2] = map((x1,x2) -> 100*((1+x1/100)*(1+x2/100) -1), z[:FGrowth1], z[:FGrowth2])
      z[:PostGrowth3] = map((x1,x2,x3) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3])
      z[:PostGrowth4] = map((x1,x2,x3,x4) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100)*(1+x4/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3], z[:FGrowth4])
      z[:PostGrowth5] = map((x1,x2,x3,x4,x5) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100)*(1+x4/100)*(1+x5/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3], z[:FGrowth4], z[:FGrowth5])
      z[:PostGrowth6] = map((x1,x2,x3,x4,x5, x6) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100)*(1+x4/100)*(1+x5/100)*(1+x6/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3], z[:FGrowth4], z[:FGrowth5], z[:FGrowth6])
end

TempDiffDataFrame = DataFrame(Country = Treated_Infl[:Country], year = Treated_Infl[:year])
TempDiffDataFrame[:LevelDiff1] = map((x1, x2) -> x1-x2, Treated_Infl[:PostGrowth1], Synthetics_Infl[:PostGrowth1])
TempDiffDataFrame[:LevelDiff2] = map((x1, x2) -> x1-x2, Treated_Infl[:PostGrowth2], Synthetics_Infl[:PostGrowth2])
TempDiffDataFrame[:LevelDiff3] = map((x1, x2) -> x1-x2, Treated_Infl[:PostGrowth3], Synthetics_Infl[:PostGrowth3])
TempDiffDataFrame[:LevelDiff4] = map((x1, x2) -> x1-x2, Treated_Infl[:PostGrowth4], Synthetics_Infl[:PostGrowth4])
TempDiffDataFrame[:LevelDiff5] = map((x1, x2) -> x1-x2, Treated_Infl[:PostGrowth5], Synthetics_Infl[:PostGrowth5])
TempDiffDataFrame[:LevelDiff6] = map((x1, x2) -> x1-x2, Treated_Infl[:PostGrowth6], Synthetics_Infl[:PostGrowth6])
LDs = [:LevelDiff1, :LevelDiff2, :LevelDiff3, :LevelDiff4, :LevelDiff5, :LevelDiff6]
		for (z, w) in enumerate(LDs)
			RobustnessChecks[z+2,3] = mean(TempDiffDataFrame[w])
		end

## WITH EXDEBT
matchon 		= [:LGrowth5, :LGrowth4, :LGrowth3, :LGrowth2, :LGrowth1, :DWDI, :Banking, :Currency, :Debt, :EXDEBT]
completecheck 	= [:Country, :year, :DWDI, :EXDEBT]
tempTreat 		= IMFCrises[:, completecheck]
tempTreat 		= tempTreat[completecases(tempTreat),:]
Treated_wDebt 	= join(IMFCrises, tempTreat, on=[:Country, :year], kind=:inner)
GrowthVariance 	= var(Treated_wDebt[:DWDI])
DebtVar		   	= var(Treated_wDebt[:EXDEBT])
Weights 		= ones(size(matchon))
Weights[end]	= GrowthVariance/DebtVar
bounds  		= [7, 7, 7, 7, 7, 7, .5, .5, .5, Inf]
(Treated_EXDEBT, Synthetics_EXDEBT, Weights_EXDEBT) = GenSynthetics(IMFCrises, NoIMFCrises, matchon, predict, localtol=bounds, matchweights=Weights);

for z = (Treated_EXDEBT, Synthetics_EXDEBT)
      z[:PostGrowth1] = map((x1) -> 100*(1+x1/100 -1), z[:FGrowth1])
      z[:PostGrowth2] = map((x1,x2) -> 100*((1+x1/100)*(1+x2/100) -1), z[:FGrowth1], z[:FGrowth2])
      z[:PostGrowth3] = map((x1,x2,x3) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3])
      z[:PostGrowth4] = map((x1,x2,x3,x4) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100)*(1+x4/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3], z[:FGrowth4])
      z[:PostGrowth5] = map((x1,x2,x3,x4,x5) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100)*(1+x4/100)*(1+x5/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3], z[:FGrowth4], z[:FGrowth5])
      z[:PostGrowth6] = map((x1,x2,x3,x4,x5, x6) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100)*(1+x4/100)*(1+x5/100)*(1+x6/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3], z[:FGrowth4], z[:FGrowth5], z[:FGrowth6])
end

TempDiffDataFrame = DataFrame(Country = Treated_EXDEBT[:Country], year = Treated_EXDEBT[:year])
TempDiffDataFrame[:LevelDiff1] = map((x1, x2) -> x1-x2, Treated_EXDEBT[:PostGrowth1], Synthetics_EXDEBT[:PostGrowth1])
TempDiffDataFrame[:LevelDiff2] = map((x1, x2) -> x1-x2, Treated_EXDEBT[:PostGrowth2], Synthetics_EXDEBT[:PostGrowth2])
TempDiffDataFrame[:LevelDiff3] = map((x1, x2) -> x1-x2, Treated_EXDEBT[:PostGrowth3], Synthetics_EXDEBT[:PostGrowth3])
TempDiffDataFrame[:LevelDiff4] = map((x1, x2) -> x1-x2, Treated_EXDEBT[:PostGrowth4], Synthetics_EXDEBT[:PostGrowth4])
TempDiffDataFrame[:LevelDiff5] = map((x1, x2) -> x1-x2, Treated_EXDEBT[:PostGrowth5], Synthetics_EXDEBT[:PostGrowth5])
TempDiffDataFrame[:LevelDiff6] = map((x1, x2) -> x1-x2, Treated_EXDEBT[:PostGrowth6], Synthetics_EXDEBT[:PostGrowth6])
LDs = [:LevelDiff1, :LevelDiff2, :LevelDiff3, :LevelDiff4, :LevelDiff5, :LevelDiff6]
		for (z, w) in enumerate(LDs)
			RobustnessChecks[z+2,4] = mean(TempDiffDataFrame[w])
		end

## USING PWT INSTEAD

## Wide Bounds LOCAL RESTRICTION
matchon = [:LGrowth5, :LGrowth4, :LGrowth3, :LGrowth2, :LGrowth1, :DWDI, :Banking, :Currency, :Debt]
bounds  = [9, 9, 9, 9, 9, 9, .5, .5, .5]
(Treated_WideBounds, Synthetics_WideBounds, Weights_WideBounds) = GenSynthetics(IMFCrises, NoIMFCrises, matchon, predict, localtol=bounds, matchweights=W);

for z = (Treated_WideBounds, Synthetics_WideBounds)
      z[:PostGrowth1] = map((x1) -> 100*(1+x1/100 -1), z[:FGrowth1])
      z[:PostGrowth2] = map((x1,x2) -> 100*((1+x1/100)*(1+x2/100) -1), z[:FGrowth1], z[:FGrowth2])
      z[:PostGrowth3] = map((x1,x2,x3) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3])
      z[:PostGrowth4] = map((x1,x2,x3,x4) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100)*(1+x4/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3], z[:FGrowth4])
      z[:PostGrowth5] = map((x1,x2,x3,x4,x5) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100)*(1+x4/100)*(1+x5/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3], z[:FGrowth4], z[:FGrowth5])
      z[:PostGrowth6] = map((x1,x2,x3,x4,x5, x6) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100)*(1+x4/100)*(1+x5/100)*(1+x6/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3], z[:FGrowth4], z[:FGrowth5], z[:FGrowth6])
end

TempDiffDataFrame = DataFrame(Country = Treated_WideBounds[:Country], year = Treated_WideBounds[:year])
TempDiffDataFrame[:LevelDiff1] = map((x1, x2) -> x1-x2, Treated_WideBounds[:PostGrowth1], Synthetics_WideBounds[:PostGrowth1])
TempDiffDataFrame[:LevelDiff2] = map((x1, x2) -> x1-x2, Treated_WideBounds[:PostGrowth2], Synthetics_WideBounds[:PostGrowth2])
TempDiffDataFrame[:LevelDiff3] = map((x1, x2) -> x1-x2, Treated_WideBounds[:PostGrowth3], Synthetics_WideBounds[:PostGrowth3])
TempDiffDataFrame[:LevelDiff4] = map((x1, x2) -> x1-x2, Treated_WideBounds[:PostGrowth4], Synthetics_WideBounds[:PostGrowth4])
TempDiffDataFrame[:LevelDiff5] = map((x1, x2) -> x1-x2, Treated_WideBounds[:PostGrowth5], Synthetics_WideBounds[:PostGrowth5])
TempDiffDataFrame[:LevelDiff6] = map((x1, x2) -> x1-x2, Treated_WideBounds[:PostGrowth6], Synthetics_WideBounds[:PostGrowth6])
LDs = [:LevelDiff1, :LevelDiff2, :LevelDiff3, :LevelDiff4, :LevelDiff5, :LevelDiff6]
		for (z, w) in enumerate(LDs)
			RobustnessChecks[z+2,6] = mean(TempDiffDataFrame[w])
		end

## ONLY GOOD MATCHES
TreatedMatched[:tempID] = collect(1:1:size(TreatedMatched)[1])
Synthetics[:tempID]     = collect(1:1:size(TreatedMatched)[1])
Synthetics_GoodMatches      = sort(Synthetics, :SqError, rev=true)
Synthetics_GoodMatches 		= Synthetics_GoodMatches[10:end,:]
Synthetics_GoodMatches		= sort(Synthetics_GoodMatches, :tempID, rev=true)
Treated_GoodMatches		= join(TreatedMatched, Synthetics_GoodMatches, on=:tempID, kind=:inner)  #keep only obs with matches in the 'good' range

for z = (Treated_GoodMatches, Synthetics_GoodMatches)
      z[:PostGrowth1] = map((x1) -> 100*(1+x1/100 -1), z[:FGrowth1])
      z[:PostGrowth2] = map((x1,x2) -> 100*((1+x1/100)*(1+x2/100) -1), z[:FGrowth1], z[:FGrowth2])
      z[:PostGrowth3] = map((x1,x2,x3) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3])
      z[:PostGrowth4] = map((x1,x2,x3,x4) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100)*(1+x4/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3], z[:FGrowth4])
      z[:PostGrowth5] = map((x1,x2,x3,x4,x5) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100)*(1+x4/100)*(1+x5/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3], z[:FGrowth4], z[:FGrowth5])
      z[:PostGrowth6] = map((x1,x2,x3,x4,x5, x6) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100)*(1+x4/100)*(1+x5/100)*(1+x6/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3], z[:FGrowth4], z[:FGrowth5], z[:FGrowth6])
end

TempDiffDataFrame = DataFrame(Country = Treated_GoodMatches[:Country], year = Treated_GoodMatches[:year])
TempDiffDataFrame[:LevelDiff1] = map((x1, x2) -> x1-x2, Treated_GoodMatches[:PostGrowth1], Synthetics_GoodMatches[:PostGrowth1])
TempDiffDataFrame[:LevelDiff2] = map((x1, x2) -> x1-x2, Treated_GoodMatches[:PostGrowth2], Synthetics_GoodMatches[:PostGrowth2])
TempDiffDataFrame[:LevelDiff3] = map((x1, x2) -> x1-x2, Treated_GoodMatches[:PostGrowth3], Synthetics_GoodMatches[:PostGrowth3])
TempDiffDataFrame[:LevelDiff4] = map((x1, x2) -> x1-x2, Treated_GoodMatches[:PostGrowth4], Synthetics_GoodMatches[:PostGrowth4])
TempDiffDataFrame[:LevelDiff5] = map((x1, x2) -> x1-x2, Treated_GoodMatches[:PostGrowth5], Synthetics_GoodMatches[:PostGrowth5])
TempDiffDataFrame[:LevelDiff6] = map((x1, x2) -> x1-x2, Treated_GoodMatches[:PostGrowth6], Synthetics_GoodMatches[:PostGrowth6])
LDs = [:LevelDiff1, :LevelDiff2, :LevelDiff3, :LevelDiff4, :LevelDiff5, :LevelDiff6]
		for (z, w) in enumerate(LDs)
			RobustnessChecks[z+2,8] = mean(TempDiffDataFrame[w])
		end


## USING OPTIMAL WEIGHTING MATRIX
matchon = [:LGrowth5, :LGrowth4, :LGrowth3, :LGrowth2, :LGrowth1, :DWDI, :Banking, :Currency, :Debt]
bounds  = [7, 7, 7, 7, 7, 7, .5, .5, .5]
OptW 	= [1.7; .5; .1; .1; .3; 1.0; 1.0; 1.0; 1.0]  # Need 3 for 
(Treated_OptWeights, Synthetics_OptWeights, Weights_OptWeights) = GenSynthetics(IMFCrises, NoIMFCrises, matchon, predict, localtol=bounds, matchweights=OptW);

for z = (Treated_OptWeights, Synthetics_OptWeights)
      z[:PostGrowth1] = map((x1) -> 100*(1+x1/100 -1), z[:FGrowth1])
      z[:PostGrowth2] = map((x1,x2) -> 100*((1+x1/100)*(1+x2/100) -1), z[:FGrowth1], z[:FGrowth2])
      z[:PostGrowth3] = map((x1,x2,x3) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3])
      z[:PostGrowth4] = map((x1,x2,x3,x4) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100)*(1+x4/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3], z[:FGrowth4])
      z[:PostGrowth5] = map((x1,x2,x3,x4,x5) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100)*(1+x4/100)*(1+x5/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3], z[:FGrowth4], z[:FGrowth5])
      z[:PostGrowth6] = map((x1,x2,x3,x4,x5, x6) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100)*(1+x4/100)*(1+x5/100)*(1+x6/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3], z[:FGrowth4], z[:FGrowth5], z[:FGrowth6])
end

TempDiffDataFrame = DataFrame(Country = Treated_OptWeights[:Country], year = Treated_OptWeights[:year])
TempDiffDataFrame[:LevelDiff1] = map((x1, x2) -> x1-x2, Treated_OptWeights[:PostGrowth1], Synthetics_OptWeights[:PostGrowth1])
TempDiffDataFrame[:LevelDiff2] = map((x1, x2) -> x1-x2, Treated_OptWeights[:PostGrowth2], Synthetics_OptWeights[:PostGrowth2])
TempDiffDataFrame[:LevelDiff3] = map((x1, x2) -> x1-x2, Treated_OptWeights[:PostGrowth3], Synthetics_OptWeights[:PostGrowth3])
TempDiffDataFrame[:LevelDiff4] = map((x1, x2) -> x1-x2, Treated_OptWeights[:PostGrowth4], Synthetics_OptWeights[:PostGrowth4])
TempDiffDataFrame[:LevelDiff5] = map((x1, x2) -> x1-x2, Treated_OptWeights[:PostGrowth5], Synthetics_OptWeights[:PostGrowth5])
TempDiffDataFrame[:LevelDiff6] = map((x1, x2) -> x1-x2, Treated_OptWeights[:PostGrowth6], Synthetics_OptWeights[:PostGrowth6])
LDs = [:LevelDiff1, :LevelDiff2, :LevelDiff3, :LevelDiff4, :LevelDiff5, :LevelDiff6]
		for (z, w) in enumerate(LDs)
			RobustnessChecks[z+2,9] = mean(TempDiffDataFrame[w])
		end 

#### Allowing any crisis to match with any other
matchon = [:LGrowth5, :LGrowth4, :LGrowth3, :LGrowth2, :LGrowth1, :DWDI]
bounds  = [7, 7, 7, 7, 7, 7] 
(Treated_FreeForAll, Synthetics_FreeForAll, Weights_FreeForAll) = GenSynthetics(IMFCrises, NoIMFCrises, matchon, predict, localtol=bounds, matchweights=W);

for z = (Treated_FreeForAll, Synthetics_FreeForAll)
      z[:PostGrowth1] = map((x1) -> 100*(1+x1/100 -1), z[:FGrowth1])
      z[:PostGrowth2] = map((x1,x2) -> 100*((1+x1/100)*(1+x2/100) -1), z[:FGrowth1], z[:FGrowth2])
      z[:PostGrowth3] = map((x1,x2,x3) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3])
      z[:PostGrowth4] = map((x1,x2,x3,x4) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100)*(1+x4/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3], z[:FGrowth4])
      z[:PostGrowth5] = map((x1,x2,x3,x4,x5) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100)*(1+x4/100)*(1+x5/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3], z[:FGrowth4], z[:FGrowth5])
      z[:PostGrowth6] = map((x1,x2,x3,x4,x5, x6) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100)*(1+x4/100)*(1+x5/100)*(1+x6/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3], z[:FGrowth4], z[:FGrowth5], z[:FGrowth6])
end

TempDiffDataFrame = DataFrame(Country = Treated_FreeForAll[:Country], year = Treated_FreeForAll[:year])
TempDiffDataFrame[:LevelDiff1] = map((x1, x2) -> x1-x2, Treated_FreeForAll[:PostGrowth1], Synthetics_FreeForAll[:PostGrowth1])
TempDiffDataFrame[:LevelDiff2] = map((x1, x2) -> x1-x2, Treated_FreeForAll[:PostGrowth2], Synthetics_FreeForAll[:PostGrowth2])
TempDiffDataFrame[:LevelDiff3] = map((x1, x2) -> x1-x2, Treated_FreeForAll[:PostGrowth3], Synthetics_FreeForAll[:PostGrowth3])
TempDiffDataFrame[:LevelDiff4] = map((x1, x2) -> x1-x2, Treated_FreeForAll[:PostGrowth4], Synthetics_FreeForAll[:PostGrowth4])
TempDiffDataFrame[:LevelDiff5] = map((x1, x2) -> x1-x2, Treated_FreeForAll[:PostGrowth5], Synthetics_FreeForAll[:PostGrowth5])
TempDiffDataFrame[:LevelDiff6] = map((x1, x2) -> x1-x2, Treated_FreeForAll[:PostGrowth6], Synthetics_FreeForAll[:PostGrowth6])
LDs = [:LevelDiff1, :LevelDiff2, :LevelDiff3, :LevelDiff4, :LevelDiff5, :LevelDiff6]
		for (z, w) in enumerate(LDs)
			RobustnessChecks[z+2,10] = mean(TempDiffDataFrame[w])
		end 


## GRAPH WITH ALL ROBUSTNESS
plot(collect(0:1:6), [0; MainBetas], linewidth=2, color=:black, label="", ylabel="", xlabel="Years From Crisis", legend=:bottomleft, legendfontsize=7, ylims=(-3,4.75), marker=([:circle], [:black], [2.5]))
plot!(collect(0:1:6), RobustnessChecks[2:end, 2], linewidth=1.5, color=:red, style=:dashdot, label="+CAB", marker=([:circle], [:red], [2]))
plot!(collect(0:1:6), RobustnessChecks[2:end, 3], linewidth=1.5, color=:green, style=:dashdot, label="+Infl",  marker=([:rect], [:green], [2]))
plot!(collect(0:1:6), RobustnessChecks[2:end, 4], linewidth=1.5, color=:blue, style=:dot, label="+Debt",  marker=([:xcross], [:blue], [2]))
plot!(collect(0:1:6), RobustnessChecks[2:end, 6], linewidth=1.5, color=:pink, style=:dashdot, label="Wide Bounds",  marker=([:utriangle], [:pink], [2]))
plot!(collect(0:1:6), RobustnessChecks[2:end, 10], linewidth=1.5, color=:gold, style=:dot, label="Any Crisis",  marker=([:star4], [:gold], [2]))
plot!(collect(0:1:6), RobustnessChecks[2:end, 9], linewidth=1.5, color=:brown, style=:dashdot, label="Optimal Weights",  marker=([:+], [:brown], [2]))
hline!([0], color=:black, style=:dot, label="")
savefig(string(CurrentPath, "Figures\\RobustIRF.pdf"))


