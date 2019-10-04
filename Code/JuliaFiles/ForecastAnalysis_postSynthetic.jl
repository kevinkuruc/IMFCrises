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

AllData					= CSV.read(string(CurrentPath, "Data\\created\\MasterData.csv"))
NAllCrises 				= size(AllData)[1]
println("Number of total crises for path is $NAllCrises")
		for z in (:Banking, :Currency, :Debt)
       		AllData[z] = AllData[z]*.5*2
		end
IMFCrises 				= AllData[AllData[:, :IMF].==1, :]

NoIMFCrises				= AllData[AllData[:, :IMF].==0, :]


W 		= ones(10,1)  #diaganol of weighting matrix (equal weights in baseline)
matchon = [:LGrowth5, :LGrowth4, :LGrowth3, :LGrowth2, :LGrowth1, :DWDI, :Banking, :Currency, :Debt]
predict = [:FGrowth1, :FGrowth2, :FGrowth3, :Fcast1, :Fcast2, :Fcast3]
matchtol= Inf	  ### For if I want to throw away bad matches 
bounds  = [7, 7, 7, 7, 7, 7, .5, .5, .5]

(TreatedForecasts, SyntheticsForecasts, DonorWeights) = GenSynthetics(IMFCrises, NoIMFCrises, matchon, predict, localtol=bounds, matchweights=W);

for z = (TreatedForecasts, SyntheticsForecasts)
      z[:PostGrowth1] = map((x1) -> 100*((1+x1/100) -1), z[:FGrowth1])
      z[:Forecasted1] = map((x1) -> 100*((1+x1/100) -1), z[:Fcast1])
      z[:PostGrowth2] = map((x1,x2) -> 100*((1+x1/100)*(1+x2/100) -1), z[:FGrowth1], z[:FGrowth2])
      z[:Forecasted2] = map((x1,x2) -> 100*((1+x1/100)*(1+x2/100) -1), z[:Fcast1], z[:Fcast2])
      z[:PostGrowth3] = map((x1,x2,x3) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3])
      z[:Forecasted3] = map((x1,x2,x3) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100) -1), z[:Fcast1], z[:Fcast2], z[:Fcast3])
end

DiffDataFrame = DataFrame(Country = TreatedForecasts[:Country], year = TreatedForecasts[:year])
DiffDataFrame[:RealDiff1] = TreatedForecasts[:PostGrowth1] - SyntheticsForecasts[:PostGrowth1]
DiffDataFrame[:RealDiff2] = TreatedForecasts[:PostGrowth2] - SyntheticsForecasts[:PostGrowth2]
DiffDataFrame[:RealDiff3] = TreatedForecasts[:PostGrowth3] - SyntheticsForecasts[:PostGrowth3]

DiffDataFrame[:ForecastedDiff1] = TreatedForecasts[:Forecasted1] - SyntheticsForecasts[:Forecasted1]
DiffDataFrame[:ForecastedDiff2] = TreatedForecasts[:Forecasted2] - SyntheticsForecasts[:Forecasted2]
DiffDataFrame[:ForecastedDiff3] = TreatedForecasts[:Forecasted3] - SyntheticsForecasts[:Forecasted3]

ForecastBetas = ones(3)
sd 			  = ones(3)
tempcontrol 	= convert(Array, DiffDataFrame[:ForecastedDiff1])
Y1 				= convert(Array, DiffDataFrame[:RealDiff1])
(b, v)			= Regress(Y1, tempcontrol)
ForecastBetas[1]= b[2]
sd[1]			= sqrt(v[2,2])

tempcontrol 	= convert(Array, DiffDataFrame[:ForecastedDiff2])
Y1 				= convert(Array, DiffDataFrame[:RealDiff2])
(b, v)			= Regress(Y1, tempcontrol)
ForecastBetas[2]= b[2]
sd[2]			= sqrt(v[2,2])

tempcontrol 	= convert(Array, DiffDataFrame[:ForecastedDiff3])
Y1 				= convert(Array, DiffDataFrame[:RealDiff3])
(b, v)			= Regress(Y1, tempcontrol)
ForecastBetas[3]= b[2]
sd[3]			= sqrt(v[2,2])