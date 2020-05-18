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
using Ipopt
using NLopt
using LinearAlgebra
using StatsPlots
using Distributions


#############################################################
# ---------Things to define for entire paper--------------- #
#############################################################
directory = dirname(dirname(pwd()))
code_directory = joinpath(directory, "Code", "JuliaFiles")
data_directory = joinpath(directory, "Data")
output_directory = joinpath(directory, "Results")
mkpath(output_directory)

include(joinpath(code_directory, "LinearRegression.jl"))
include(joinpath(code_directory, "RunningPlacebosFunction.jl"))
include(joinpath(code_directory, "CrisisType_Region_Heterogeneity.jl"))
include(joinpath(code_directory, "Heterogeneity_Correlation.jl"))

t = collect(-5:1:6)
growths = [:LGrowth5, :LGrowth4, :LGrowth3, :LGrowth2, :LGrowth1, :DWDI, :FGrowth1, :FGrowth2, :FGrowth3, :FGrowth4, :FGrowth5, :FGrowth6]
treatedblue = :black
controlred = RGB(120/255, 120/255, 120/255)


#############################################################
# -----------Summary Stats----------------------------------#
#############################################################

## LOAD IN ALL IMF LOAN GROWTH RATES (CENTERED AROUND LOAN)
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

# ------ FIGURE 1 -----------------------------------------------------------------------#
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

#------- FIGURE 2: Financial Crisis (a) & Split to With/Without (b) -------------------------  #

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
#----------Run Synthetic Control and Make Graphs (Both Main and Some Appendix)----------#
#########################################################################################

#------DEFINE MAIN SPECIFICATION FOR CONSTRUCTING SYNTHETIC CONTROLS--------------------#

W 		= ones(10,1)  #diaganol of weighting matrix (equal weights in baseline)
matchon = [:LGrowth5, :LGrowth4, :LGrowth3, :LGrowth2, :LGrowth1, :DWDI, :Banking, :Currency, :Debt]
predict = [:FGrowth1, :FGrowth2, :FGrowth3, :FGrowth4, :FGrowth5, :FGrowth6]
matchtol= Inf	  ### For if I want to throw away bad matches 
B 		= 7
bounds  = [B, B, B, B, B, B, .5, .5, .5]

#------ RUN PLACEBO GROUP FIRST TO GENERATE VARIANCE UNDER THE NULL---------------------#

include("RunningPlacebosFunction.jl")
(Placebos, SyntheticPlacebos) = RunningPlacebos(matchon, W, bounds, predict, NoIMFCrises);

NullErrors = DataFrame()
PostErrors = [:PostError1, :PostError2, :PostError3, :PostError4, :PostError5, :PostError6]
PostGrowths = [:PostGrowth1, :PostGrowth2, :PostGrowth3, :PostGrowth4, :PostGrowth5, :PostGrowth6]
for (pe, pg) in zip(PostErrors, PostGrowths)
	NullErrors[pe] = map((x,y) -> x-y, Placebos[pg], SyntheticPlacebos[pg])
end

NullErrorsArray			= convert(Array, [NullErrors[:PostError1] NullErrors[:PostError2] NullErrors[:PostError3] NullErrors[:PostError4] NullErrors[:PostError5] NullErrors[:PostError6]])

NullCovariance 			= (1/size(NullErrorsArray)[1])*NullErrorsArray'*NullErrorsArray  #calculate variance by hand assuming mean zero

#-------- RUN ACTUAL SYNTHETICS WITH COVARIANCES ABOVE FOR STANDARD ERRORS -------------#

(TreatedMatched, Synthetics, DonorWeights) = GenSynthetics(IMFCrises, NoIMFCrises, matchon, predict, localtol=bounds, matchweights=W);

#-------- HISTOGRAM OF OBS. UNDERLYING SYNTHETICS (FIGURE A2) --------------------------#
WeightsArray = convert(Array, DonorWeights[:,4:end])
synthtot = size(WeightsArray)[1]
TotalWeight = zeros(synthtot)
Matched 	= zeros(synthtot)
for i = 1:synthtot
    TotalWeight[i] = sum(WeightsArray[i,:])
    if TotalWeight[i]>.2
    	Matched[i]=1
    end
end
DonorWeights[:TotalWeight] = TotalWeight
DonorWeights[:Matched]     = Matched
histogram(TotalWeight, bins=30, xticks=collect(0:1:5), color=treatedblue, label="", ylabel="Frequency"
, xlabel="Total (Sum) of Weights in the 99 Synthetics", guidefont=9)
vline!([size(TreatedMatched)[1]/NNoIMF], color=controlred, label="Equal Weights Baseline", style=:dot, linewidth=2)
savefig(joinpath(output_directory, "Histogram.pdf"))

# -------- TABLE OF INCLUDED OBSERVATIONS (TABLE A1, A2) ------------------------------- #
TreatedMatched[:Matched] = 1
IMFCrisesForTable = join(IMFCrises, TreatedMatched, on=[:Country, :year], kind=:outer, makeunique=true)
IMFCrisesForTable = IMFCrisesForTable[:, [:Country, :year, :Banking, :Currency, :Debt, :Matched]]
CSV.write(joinpath(output_directory, "TableA1.csv"), IMFCrisesForTable)

NoIMFCrisesForTable = join(NoIMFCrises, DonorWeights, on=[:Country, :year], kind=:outer, makeunique=true)
NoIMFCrisesForTable = NoIMFCrisesForTable[:, [:Country, :year, :Banking, :Currency, :Debt, :TotalWeight, :Matched]]
dropmissing!(NoIMFCrisesForTable)
CSV.write(joinpath(output_directory, "TableA2.csv"), NoIMFCrisesForTable)

#--------- GROWTH RATES TREATED VS. SYNTHETIC (FIGURE 3C) ---- #

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

# ---- CUMULATIVE GROWTH RATES ---------------------------------#
for z = (TreatedMatched, Synthetics)
      z[:PostGrowth1] = map((x1) -> 100*(1+x1/100 -1), z[:FGrowth1])
      z[:PostGrowth2] = map((x1,x2) -> 100*((1+x1/100)*(1+x2/100) -1), z[:FGrowth1], z[:FGrowth2])
      z[:PostGrowth3] = map((x1,x2,x3) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3])
      z[:PostGrowth4] = map((x1,x2,x3,x4) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100)*(1+x4/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3], z[:FGrowth4])
      z[:PostGrowth5] = map((x1,x2,x3,x4,x5) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100)*(1+x4/100)*(1+x5/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3], z[:FGrowth4], z[:FGrowth5])
      z[:PostGrowth6] = map((x1,x2,x3,x4,x5, x6) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100)*(1+x4/100)*(1+x5/100)*(1+x6/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3], z[:FGrowth4], z[:FGrowth5], z[:FGrowth6])
end

MainDiffDataFrame = DataFrame(Country = TreatedMatched[:Country], year = TreatedMatched[:year])
LDs = [:LevelDiff1, :LevelDiff2, :LevelDiff3, :LevelDiff4, :LevelDiff5, :LevelDiff6]
PostGrowths = [:PostGrowth1, :PostGrowth2, :PostGrowth3, :PostGrowth4, :PostGrowth5, :PostGrowth6]
for (ld, pg) in zip(LDs, PostGrowths)
	MainDiffDataFrame[ld] = map((x1, x2) -> x1-x2, TreatedMatched[pg], Synthetics[pg])
end

# ---- Average Difference in Cumulative Growth Rates ------------#
MainBetas = zeros(size(predict)[1], 3)  #with lower and upper se in cols 2, 3
N = size(MainDiffDataFrame)[1]
for (z, w) in enumerate(LDs)
	MainBetas[z,1] = mean(MainDiffDataFrame[w])
	MainBetas[z,2] = MainBetas[z,1] - sqrt(NullCovariance[z,z]/N)
	MainBetas[z,3] = MainBetas[z,1] + sqrt(NullCovariance[z,z]/N)
end

#------ Hotelling T-sq for joint significance of first 5 coefficients ------- #
HotellingT = N*MainBetas[:,1]'*inv(NullCovariance)*MainBetas[:,1]
TranslatedToFDist = HotellingT*(N-6)/((N-1)*6) 
# ---- Check p value of this number on F-dist(6,N-6) --- #
F = FDist(6, N-6)
PVal = ccdf(F, TranslatedToFDist)

#------ FIGURE 3A -------------------------------------------------------------#
plot(collect(0:1:size(predict)[1]), [0; MainBetas[:,1]], linewidth=2.5, color=:black, label="", ylabel="Increase in Output (%)", xlabel="Years From Crisis", marker=([:circle], [:black], [2.5]))
plot!(collect(0:1:size(predict)[1]), [[0; MainBetas[:,2]] [0; MainBetas[:,3]]], color=:gray, linestyle = :dot, label=["1 s.e." ""], legend=:bottomleft, ylims=(-3, 4.75))
hline!([0], color=:black, style=:dot, label="")
savefig(joinpath(output_directory, "MainIRF.pdf"))

# ------ FIGURE A1 ------------------------------------------------------------#
density(MainDiffDataFrame[:LevelDiff2], color=treatedblue, yticks=nothing, xlabel="Level Difference", label="t=2", legend=:topleft, style=:solid, linewidth=2)
density!(MainDiffDataFrame[:LevelDiff3], color=treatedblue, style=:dashdot, label="t=3", linewidth=2)
density!(MainDiffDataFrame[:LevelDiff4], color=treatedblue, style=:dot, label="t=4", linewidth=2)
vline!([0], color=:black, style=:dot, label="")
savefig(joinpath(output_directory, "MainDensity.pdf"))

# -------- Cumulative Effect Size By Treated (Integral of IRF) ------- #
TreatedMatched[:CumulativeEffect] = map((x1,x2,x3,x4,x5) -> +(x1, x2, x3, x4, x5), MainDiffDataFrame[:LevelDiff1], MainDiffDataFrame[:LevelDiff2], MainDiffDataFrame[:LevelDiff3], MainDiffDataFrame[:LevelDiff4], MainDiffDataFrame[:LevelDiff5])
MainMean = mean(TreatedMatched[:CumulativeEffect])
println("Average Cumulative Effect is $MainMean")

# -------- Heterogeneity Results (FIGURE 4) ------------------- #
CrisisAverages = ByCrisisType()
RegionAverages = ByRegion()
HeterogeneityScatter(:WGI)
HeterogeneityScatter(:year)
HeterogeneityScatter(:conditions)
HeterogeneityScatter(:AmountAgreedPercentGDP)
#---- TABLE A6 ------------------------------------------------ #
#include(joinpath(code_directory, "Heterogeneity_Regressions.jl"))

# ------- ROBUSTNESS (BOTH FIGURE 3B & APPENDIX) -------------- #
#include(joinpath(code_directory, "RobustnessRuns.jl"))

# ------- TABLE 1 (AND A5) ARE MADE IN STATA [SEE "ForecastRegressoins_Table1.do"] -----------------------# 

# ------- APPENDIX TABLE A3, A4 ---------------#
#Takes a long time to run, only uncomment to replicate that particular Table
#include(PlaceboComparisonTable.jl)



