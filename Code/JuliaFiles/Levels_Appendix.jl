include(joinpath(code_directory, "RunningPlacebos_Levels.jl"))

AllData_Levels                       = CSV.read(joinpath(data_directory, "created", "MasterData_Levels.csv"), DataFrame)
            for z in (:Banking, :Currency, :Debt)
                  AllData_Levels[!,z] = AllData_Levels[!,z]*.5*2
            end
IMFCrises_Levels                     = AllData_Levels[AllData_Levels[:, :IMF].==1, :]
NoIMFCrises_Levels                   = AllData_Levels[AllData_Levels[:, :IMF].==0, :]
matchon = [:LLevels5, :LLevels4, :LLevels3, :LLevels2, :LLevels1, :GDPCAP, :Banking, :Currency, :Debt]
bounds  = [Inf, Inf, Inf, Inf, Inf, Inf, .5, .5, .5]
predict = [:FLevels1, :FLevels2, :FLevels3, :FLevels4, :FLevels5, :FLevels6]
W       = ones(10,1)
#Set 'match tol' within the RunningPlacebos function.
(Placebos_Levels, SyntheticPlacebos_Levels) = RunningPlacebos_Levels(matchon, W, bounds, predict, NoIMFCrises_Levels)

NullErrors_Levels = DataFrame()
PostErrors = [:PostError1, :PostError2, :PostError3, :PostError4, :PostError5, :PostError6]#, :PostError7]
PostGrowths = [:PostGrowth1, :PostGrowth2, :PostGrowth3, :PostGrowth4, :PostGrowth5, :PostGrowth6]#, :PostGrowth7]
for (pe, pg) in zip(PostErrors, PostGrowths)
	NullErrors_Levels[!,pe] = map((x,y) -> x-y, Placebos_Levels[!,pg], SyntheticPlacebos_Levels[!,pg])
end

NullErrorsArray_Levels			= Matrix([NullErrors_Levels[!,:PostError1] NullErrors_Levels[!,:PostError2] NullErrors_Levels[!,:PostError3] NullErrors_Levels[!,:PostError4] NullErrors_Levels[!,:PostError5] NullErrors_Levels[!,:PostError6]])# NullErrors[:PostError7]])

NullCovariance_Levels 			= (1/size(NullErrorsArray_Levels,1))*NullErrorsArray_Levels'*NullErrorsArray_Levels  #calculate variance by hand assuming mean zero
Horizon_3_Level_error           = NullCovariance_Levels[3,3]
Horizon_3_growth_error          = NullCovariance[3,3]
println("Horizon 3 Forecast Variance = $Horizon_3_Level_error")
println("This is compared to growth rates value of $Horizon_3_growth_error")
N_levels = size(Placebos_Levels, 1)
println("This matchtol generates $N_levels values; as opposed to 82 for main specification.")

#Run Levels Analysis
(Treated_Levels, Synthetics_Levels, Weights_Levels) = GenSynthetics(IMFCrises_Levels, NoIMFCrises_Levels, matchon, predict, localtol=bounds, matchtol=3000000, matchweights=W)

t = collect(-5:1:6)

Levels_Outcomes = zeros(length(t), 2)
z = (Treated_Levels, Synthetics_Levels)
for (j,data) in enumerate(z)
    Levels_Outcomes[1, j] = mean(data[!,:LLevels5])
    Levels_Outcomes[2, j] = mean(data[!,:LLevels4]) 
    Levels_Outcomes[3, j] = mean(data[!,:LLevels3]) 
    Levels_Outcomes[4, j] = mean(data[!,:LLevels2])
    Levels_Outcomes[5, j] = mean(data[!,:LLevels1]) 
    Levels_Outcomes[6, j] = mean(data[!,:GDPCAP]) 
    Levels_Outcomes[7, j] = mean(data[!,:FLevels1]) 
    Levels_Outcomes[8, j] = mean(data[!,:FLevels2]) 
    Levels_Outcomes[9, j] = mean(data[!,:FLevels3]) 
    Levels_Outcomes[10, j] = mean(data[!,:FLevels4]) 
    Levels_Outcomes[11, j] = mean(data[!,:FLevels5])
    Levels_Outcomes[12, j] = mean(data[!,:FLevels6])
end

plot(collect(-5:1:6), Levels_Outcomes, label=["Treated" "Synthetics"], linecolor=[treatedblue controlred], linestyle=[:solid :dash], legend=:topleft, linewidth=[2.5 2],
    xticks=(collect(-5:1:6)), grid=false, ylabel="GDP per capita (2011 USD)")
vline!([0], linestyle=:dashdot, linewidth=.75, color=:black, label="")
savefig(joinpath(output_directory, "Level_Analysis_3Mill.pdf"))
savefig(joinpath(output_directory, "Level_Analysis_3Mill.svg"))