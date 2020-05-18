include(joinpath(code_directory, "SolveForWeights.jl"))

RobustnessChecks = ["CAB" "Infl" "Debt" "WideBounds" "FreeForAll" "Optimal Weights" "CABOpt" "InflOpt" "DebtOpt" "NoAdv" "GoodMatches" "NoBounds" "PWT"]
Z = zeros(size(predict)[1]+1,length(RobustnessChecks))
RobustnessChecks = [RobustnessChecks; Z]

# --- Need Growth Variance First ---#
completecheck     = [:Country, :year, :DWDI]
tempTreat         = IMFCrises[:, completecheck]
tempTreat         = tempTreat[completecases(tempTreat),:]
Growth_variance   = var(tempTreat[:DWDI])

#----WITH CURRENT ACCOUNT BALANCE----#
matchon 		= [:LGrowth5, :LGrowth4, :LGrowth3, :LGrowth2, :LGrowth1, :DWDI, :Banking, :Currency, :Debt, :CAB]
completecheck 	= [:Country, :year, :DWDI, :CAB]
tempTreat 		= IMFCrises[:, completecheck]
tempTreat 		= tempTreat[completecases(tempTreat),:]
Treated_wCAB 	= join(IMFCrises, tempTreat, on=[:Country, :year], kind=:inner, makeunique=true)
CAB_variance	= var(Treated_wCAB[:CAB])
Weights 		= ones(size(matchon))
Weights[end]	= Growth_variance/CAB_variance
bounds  		= [B, B, B, B, B, B, .5, .5, .5, Inf]
(Treated_CAB, Synthetics_CAB, Weights_CAB) = GenSynthetics(IMFCrises, NoIMFCrises, matchon, predict, localtol=bounds, matchweights=Weights);


#----WITH INFLATION -------#
matchon 		= [:LGrowth5, :LGrowth4, :LGrowth3, :LGrowth2, :LGrowth1, :DWDI, :Banking, :Currency, :Debt, :Infl]
completecheck 	= [:Country, :year, :DWDI, :Infl]
tempTreat 		= IMFCrises[:, completecheck]
tempTreat 		= tempTreat[completecases(tempTreat),:]
Treated_wInfl 	= join(IMFCrises, tempTreat, on=[:Country, :year], kind=:inner, makeunique=true)
Infl_variance	= var(Treated_wInfl[:Infl])
Weights 		= ones(size(matchon))
Weights[end]	= Growth_variance/Infl_variance
bounds            = [B, B, B, B, B, B, .5, .5, .5, Inf]
(Treated_Infl, Synthetics_Infl, Weights_Infl) = GenSynthetics(IMFCrises, NoIMFCrises, matchon, predict, localtol=bounds, matchweights=Weights);

#---WITH EXDEBT ----------#
matchon 		= [:LGrowth5, :LGrowth4, :LGrowth3, :LGrowth2, :LGrowth1, :DWDI, :Banking, :Currency, :Debt, :EXDEBT]
completecheck 	= [:Country, :year, :DWDI, :EXDEBT]
tempTreat 		= IMFCrises[:, completecheck]
tempTreat 		= tempTreat[completecases(tempTreat),:]
Treated_wDebt 	= join(IMFCrises, tempTreat, on=[:Country, :year], kind=:inner, makeunique=true)
Debt_variance	= var(Treated_wDebt[:EXDEBT])
Weights 		= ones(size(matchon))
Weights[end]	= Growth_variance/Debt_variance
bounds            = [B, B, B, B, B, B, .5, .5, .5, Inf]
(Treated_EXDEBT, Synthetics_EXDEBT, Weights_EXDEBT) = GenSynthetics(IMFCrises, NoIMFCrises, matchon, predict, localtol=bounds, matchweights=Weights);

#---WIDER LOCAL RESTRICTION ----- #
matchon = [:LGrowth5, :LGrowth4, :LGrowth3, :LGrowth2, :LGrowth1, :DWDI, :Banking, :Currency, :Debt]
bounds  = [B+4, B+4, B+4, B+4, B+4, B+4, .5, .5, .5]
W       = ones(10,1)
(Treated_WideBounds, Synthetics_WideBounds, Weights_WideBounds) = GenSynthetics(IMFCrises, NoIMFCrises, matchon, predict, localtol=bounds, matchweights=W);

#----ANY CRISIS TYPE CAN MATCH ---- #
matchon = [:LGrowth5, :LGrowth4, :LGrowth3, :LGrowth2, :LGrowth1, :DWDI]
bounds  = [B, B, B, B, B, B] 
W       = ones(10,1)
(Treated_FreeForAll, Synthetics_FreeForAll, Weights_FreeForAll) = GenSynthetics(IMFCrises, NoIMFCrises, matchon, predict, localtol=bounds, matchweights=W);

#----USING OPTIMAL WEIGHTING MATRIX ---- #
matchon = [:LGrowth5, :LGrowth4, :LGrowth3, :LGrowth2, :LGrowth1, :DWDI, :Banking, :Currency, :Debt]
bounds  = [B, B, B, B, B, B, .5, .5, .5]
Ws       = ones(10,1)
Ws      = MinimizeForWeights(matchon, bounds, predict, NoIMFCrises)
WOpt    = Ws
OptW 	= [Ws[1]; Ws[2]; Ws[3]; Ws[4]; Ws[5]; Ws[6]; 1.0; 1.0; 1.0]  # Need 3 for 
(Treated_OptWeights, Synthetics_OptWeights, Weights_OptWeights) = GenSynthetics(IMFCrises, NoIMFCrises, matchon, predict, localtol=bounds, matchweights=OptW);

#---CURRENT ACCOUNT WITH OPTIMAL WEIGHTS ------ #
matchon = [:LGrowth5, :LGrowth4, :LGrowth3, :LGrowth2, :LGrowth1, :DWDI, :CAB, :Banking, :Currency, :Debt]
bounds  = [B, B, B, B, B, B, Inf, .5, .5, .5]
Ws      = MinimizeForWeights(matchon, bounds, predict, NoIMFCrises)
WOpt_CAB = Ws
OptW    = [Ws[1]; Ws[2]; Ws[3]; Ws[4]; Ws[5]; Ws[6]; W[7]; 1.0; 1.0; 1.0]  # Need 3 for 
(Treated_CABOptWeights, Synthetics_CABOptWeights, Weights_CABOptWeights) = GenSynthetics(IMFCrises, NoIMFCrises, matchon, predict, localtol=bounds, matchweights=OptW);

#---INFLATION WITH OPTIMAL WEIGHTS ------------ #
matchon = [:LGrowth5, :LGrowth4, :LGrowth3, :LGrowth2, :LGrowth1, :DWDI, :Infl, :Banking, :Currency, :Debt]
bounds  = [B, B, B, B, B, B, Inf, .5, .5, .5]
Ws      = MinimizeForWeights(matchon, bounds, predict, NoIMFCrises)
WOpt_Infl = Ws
OptW  = [Ws[1]; Ws[2]; Ws[3]; Ws[4]; Ws[5]; Ws[6]; W[7]; 1.0; 1.0; 1.0]  # Need 3 for 
(Treated_InflOptWeights, Synthetics_InflOptWeights, Weights_InflOptWeights) = GenSynthetics(IMFCrises, NoIMFCrises, matchon, predict, localtol=bounds, matchweights=OptW);

#---DEBT WITH OPTIMAL WEIGHTS ------------------#
matchon = [:LGrowth5, :LGrowth4, :LGrowth3, :LGrowth2, :LGrowth1, :DWDI, :EXDEBT, :Banking, :Currency, :Debt]
bounds  = [B, B, B, B, B, B, Inf, .5, .5, .5]
Ws      = MinimizeForWeights(matchon, bounds, predict, NoIMFCrises)
WOpt_Debt = Ws
OptW  = [Ws[1]; Ws[2]; Ws[3]; Ws[4]; Ws[5]; Ws[6]; W[7]; 1.0; 1.0; 1.0]  # Need 3 for 
(Treated_DebtOptWeights, Synthetics_DebtOptWeights, Weights_DebtOptWeights) = GenSynthetics(IMFCrises, NoIMFCrises, matchon, predict, localtol=bounds, matchweights=OptW);

#---DROP ADVANCED ECONOMIES AS CONTROLS --------#
TempNoIMFCrises = NoIMFCrises[NoIMFCrises[:advecon].!=1, :]
matchon = [:LGrowth5, :LGrowth4, :LGrowth3, :LGrowth2, :LGrowth1, :DWDI, :Banking, :Currency, :Debt]
bounds  = [B, B, B, B, B, B, .5, .5, .5]
W       = ones(10,1)
(Treated_NoAdv, Synthetics_NoAdv, Weights_NoAdv) = GenSynthetics(IMFCrises, TempNoIMFCrises, matchon, predict, localtol=bounds, matchweights=W);

#---DROP BAD MATCHES ---------------------------#
tempid                      = collect(1:1:size(Synthetics)[1])
Synthetics[:TempID]         = tempid
TreatedMatched[:TempID]     = tempid
Synthetics_GoodMatches      = sort(Synthetics, :SqError, rev=true)
Synthetics_GoodMatches      = Synthetics_GoodMatches[10:end,:]
Treated_GoodMatches         = join(TreatedMatched, Synthetics_GoodMatches, on=:TempID, kind=:inner, makeunique=true)  #keep only obs with matches in the 'good' range

#---NO LOCAL BOUNDS ----------------------------#
matchon = [:LGrowth5, :LGrowth4, :LGrowth3, :LGrowth2, :LGrowth1, :DWDI, :Banking, :Currency, :Debt]
bounds  = [Inf, Inf, Inf, Inf, Inf, Inf, .5, .5, .5]
W       = ones(10,1)
(Treated_NoBounds, Synthetics_NoBounds, Weights_NoBounds) = GenSynthetics(IMFCrises, NoIMFCrises, matchon, predict, localtol=bounds, matchweights=W);

#---USING PENN WORLD TABLES INSTEAD OF WDI ---- #
AllData_PWT                       = CSV.read(joinpath(data_directory, "created", "MasterData_PWT.csv"))
            for z in (:Banking, :Currency, :Debt)
                  AllData_PWT[z] = AllData_PWT[z]*.5*2
            end
IMFCrises_PWT                     = AllData_PWT[AllData_PWT[:, :IMF].==1, :]
NoIMFCrises_PWT                   = AllData_PWT[AllData_PWT[:, :IMF].==0, :]
matchon = [:LGrowth5, :LGrowth4, :LGrowth3, :LGrowth2, :LGrowth1, :DPWT, :Banking, :Currency, :Debt]
bounds  = [B, B, B, B, B, B, .5, .5, .5]
W       = ones(10,1)
(Treated_PWT, Synthetics_PWT, Weights_PWT) = GenSynthetics(IMFCrises_PWT, NoIMFCrises_PWT, matchon, predict, localtol=bounds, matchweights=W);

for z = (Treated_CAB, Synthetics_CAB, Treated_Infl, Synthetics_Infl, Treated_EXDEBT, Synthetics_EXDEBT, Treated_WideBounds, Synthetics_WideBounds, Treated_FreeForAll, Synthetics_FreeForAll, Treated_OptWeights, Synthetics_OptWeights, Treated_CABOptWeights, Synthetics_CABOptWeights, Treated_InflOptWeights, Synthetics_InflOptWeights, Treated_DebtOptWeights, Synthetics_DebtOptWeights, Treated_NoAdv, Synthetics_NoAdv, Treated_GoodMatches, Synthetics_GoodMatches, Treated_NoBounds, Synthetics_NoBounds, Treated_PWT, Synthetics_PWT)
      z[:PostGrowth1] = map((x1) -> 100*(1+x1/100 -1), z[:FGrowth1])
      z[:PostGrowth2] = map((x1,x2) -> 100*((1+x1/100)*(1+x2/100) -1), z[:FGrowth1], z[:FGrowth2])
      z[:PostGrowth3] = map((x1,x2,x3) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3])
      z[:PostGrowth4] = map((x1,x2,x3,x4) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100)*(1+x4/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3], z[:FGrowth4])
      z[:PostGrowth5] = map((x1,x2,x3,x4,x5) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100)*(1+x4/100)*(1+x5/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3], z[:FGrowth4], z[:FGrowth5])
      z[:PostGrowth6] = map((x1,x2,x3,x4,x5, x6) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100)*(1+x4/100)*(1+x5/100)*(1+x6/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3], z[:FGrowth4], z[:FGrowth5], z[:FGrowth6])
end

LDs = [:LevelDiff1, :LevelDiff2, :LevelDiff3, :LevelDiff4, :LevelDiff5, :LevelDiff6]
PostGrowths = [:PostGrowth1, :PostGrowth2, :PostGrowth3, :PostGrowth4, :PostGrowth5, :PostGrowth6]
for (h, pg) in enumerate(PostGrowths)
      TempDiff = convert(Array, Treated_CAB[pg]-Synthetics_CAB[pg])
      RobustnessChecks[h+2,1] = mean(TempDiff)
      TempDiff = convert(Array, Treated_Infl[pg]-Synthetics_Infl[pg])
      RobustnessChecks[h+2,2] = mean(TempDiff)
      TempDiff = convert(Array, Treated_EXDEBT[pg]-Synthetics_EXDEBT[pg])
      RobustnessChecks[h+2,3] = mean(TempDiff)
      TempDiff = convert(Array, Treated_WideBounds[pg]-Synthetics_WideBounds[pg])
      RobustnessChecks[h+2,4] = mean(TempDiff)
      TempDiff = convert(Array, Treated_FreeForAll[pg]-Synthetics_FreeForAll[pg])
      RobustnessChecks[h+2,5] = mean(TempDiff)
      TempDiff = convert(Array, Treated_OptWeights[pg]-Synthetics_OptWeights[pg])
      RobustnessChecks[h+2,6] = mean(TempDiff)
      TempDiff = convert(Array, Treated_CABOptWeights[pg]-Synthetics_CABOptWeights[pg])
      RobustnessChecks[h+2,7] = mean(TempDiff)
      TempDiff = convert(Array, Treated_InflOptWeights[pg]-Synthetics_InflOptWeights[pg])
      RobustnessChecks[h+2,8] = mean(TempDiff)
      TempDiff = convert(Array, Treated_DebtOptWeights[pg]-Synthetics_DebtOptWeights[pg])
      RobustnessChecks[h+2,9] = mean(TempDiff)
      TempDiff = convert(Array, Treated_NoAdv[pg]-Synthetics_NoAdv[pg])
      RobustnessChecks[h+2,10] = mean(TempDiff)
      TempDiff = convert(Array, Treated_GoodMatches[pg]-Synthetics_GoodMatches[pg])
      RobustnessChecks[h+2,11] = mean(TempDiff)
      TempDiff = convert(Array, Treated_NoBounds[pg]-Synthetics_NoBounds[pg])
      RobustnessChecks[h+2,12] = mean(TempDiff)
      TempDiff = convert(Array, Treated_PWT[pg]-Synthetics_PWT[pg])
      RobustnessChecks[h+2,13] = mean(TempDiff)
end


#---GRAPH WITH ALL ROBUSTNESS (Figure 3b) --------#
plot(collect(0:1:6), [0; MainBetas[:,1]], linewidth=2, color=:black, label="", ylabel="", xlabel="Years From Crisis", legend=:bottomleft, legendfontsize=7, ylims=(-3,4.75), marker=([:circle], [:black], [2.5]))
plot!(collect(0:1:6), RobustnessChecks[2:end, 1], linewidth=1.5, color=:red, style=:dashdot, label="+CAB", marker=([:hexagon], [:red], [2]))
plot!(collect(0:1:6), RobustnessChecks[2:end, 2], linewidth=1.5, color=:green, style=:dashdot, label="+Infl",  marker=([:rect], [:green], [2]))
plot!(collect(0:1:6), RobustnessChecks[2:end, 3], linewidth=1.5, color=:blue, style=:dot, label="+Debt",  marker=([:xcross], [:blue], [2]))
plot!(collect(0:1:6), RobustnessChecks[2:end, 4], linewidth=1.5, color=:pink, style=:dashdot, label="Wide Bounds",  marker=([:utriangle], [:pink], [2]))
plot!(collect(0:1:6), RobustnessChecks[2:end, 5], linewidth=1.5, color=:gold, style=:dot, label="Any Crisis",  marker=([:star4], [:gold], [2]))
plot!(collect(0:1:6), RobustnessChecks[2:end, 6], linewidth=1.5, color=:brown, style=:dashdot, label="Optimal Weights",  marker=([:+], [:brown], [2]))
hline!([0], color=:black, style=:dot, label="")
savefig(joinpath(output_directory, "Robustness.pdf"))

#--Something weird here--#
plot(collect(0:1:6), RobustnessChecks[2:end, 7], linewidth=2, color=:black, label="+CAB_Opt", ylabel="", xlabel="Years From Crisis", legend=:bottomleft, legendfontsize=7, ylims=(-3,4.75), marker=([:circle], [:black], [2]))
plot!(collect(0:1:6), RobustnessChecks[2:end, 8], linewidth=1.5, color=:red, style=:dashdot, label="+Infl_Opt", marker=([:hexagon], [:red], [2]))
plot!(collect(0:1:6), RobustnessChecks[2:end, 9], linewidth=1.5, color=:green, style=:dashdot, label="+Debt_Opt",  marker=([:rect], [:green], [2]))
plot!(collect(0:1:6), RobustnessChecks[2:end, 10], linewidth=1.5, color=:blue, style=:dot, label="No Adv. Economies",  marker=([:xcross], [:blue], [2]))
plot!(collect(0:1:6), RobustnessChecks[2:end, 11], linewidth=1.5, color=:pink, style=:dashdot, label="Good Matches",  marker=([:utriangle], [:pink], [2]))
plot!(collect(0:1:6), RobustnessChecks[2:end, 12], linewidth=1.5, color=:gold, style=:dot, label="No Boundaries",  marker=([:star4], [:gold], [2]))
plot!(collect(0:1:6), RobustnessChecks[2:end, 13], linewidth=1.5, color=:brown, style=:dashdot, label="PWT",  marker=([:+], [:brown], [2]))
hline!([0], color=:black, style=:dot, label="")
savefig(joinpath(output_directory, "Robustness_Appendix.pdf"))
