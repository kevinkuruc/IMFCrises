RobustnessChecks = ["CAB" "Infl" "Debt" "WideBounds" "FreeForAll" "NoAdv" "GoodMatches" "PWT" "9Bounds" "11Bounds" "13Bounds" "15Bounds" "25Bounds"]
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

#---WIDER LOCAL RESTRICTIONs ----- #
matchon = [:LGrowth5, :LGrowth4, :LGrowth3, :LGrowth2, :LGrowth1, :DWDI, :Banking, :Currency, :Debt]
bounds  = [B+2, B+2, B+2, B+2, B+2, B+2, .5, .5, .5]
W       = ones(10,1)
(Treated_WideBounds1, Synthetics_WideBounds1, Weights_WideBounds1) = GenSynthetics(IMFCrises, NoIMFCrises, matchon, predict, localtol=bounds, matchweights=W);

matchon = [:LGrowth5, :LGrowth4, :LGrowth3, :LGrowth2, :LGrowth1, :DWDI, :Banking, :Currency, :Debt]
bounds  = [B+4, B+4, B+4, B+4, B+4, B+4, .5, .5, .5]
W       = ones(10,1)
(Treated_WideBounds2, Synthetics_WideBounds2, Weights_WideBounds2) = GenSynthetics(IMFCrises, NoIMFCrises, matchon, predict, localtol=bounds, matchweights=W);

matchon = [:LGrowth5, :LGrowth4, :LGrowth3, :LGrowth2, :LGrowth1, :DWDI, :Banking, :Currency, :Debt]
bounds  = [B+6, B+6, B+6, B+6, B+6, B+6, .5, .5, .5]
W       = ones(10,1)
(Treated_WideBounds3, Synthetics_WideBounds3, Weights_WideBounds3) = GenSynthetics(IMFCrises, NoIMFCrises, matchon, predict, localtol=bounds, matchweights=W);

matchon = [:LGrowth5, :LGrowth4, :LGrowth3, :LGrowth2, :LGrowth1, :DWDI, :Banking, :Currency, :Debt]
bounds  = [B+8, B+8, B+8, B+8, B+8, B+8, .5, .5, .5]
W       = ones(10,1)
(Treated_WideBounds4, Synthetics_WideBounds4, Weights_WideBounds4) = GenSynthetics(IMFCrises, NoIMFCrises, matchon, predict, localtol=bounds, matchweights=W);

#---NO LOCAL BOUNDS ----------------------------#
matchon = [:LGrowth5, :LGrowth4, :LGrowth3, :LGrowth2, :LGrowth1, :DWDI, :Banking, :Currency, :Debt]
bounds  = [25, 25, 25, 25, 25, 25, .5, .5, .5]
W       = ones(10,1)
(Treated_NoBounds, Synthetics_NoBounds, Weights_NoBounds) = GenSynthetics(IMFCrises, NoIMFCrises, matchon, predict, localtol=bounds, matchweights=W);

#----ANY CRISIS TYPE CAN MATCH ---- #
matchon = [:LGrowth5, :LGrowth4, :LGrowth3, :LGrowth2, :LGrowth1, :DWDI]
bounds  = [B, B, B, B, B, B] 
W       = ones(10,1)
(Treated_FreeForAll, Synthetics_FreeForAll, Weights_FreeForAll) = GenSynthetics(IMFCrises, NoIMFCrises, matchon, predict, localtol=bounds, matchweights=W);

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

for z = (Treated_CAB, Synthetics_CAB, Treated_Infl, Synthetics_Infl, Treated_EXDEBT, Synthetics_EXDEBT, Treated_WideBounds1, Synthetics_WideBounds1, Treated_WideBounds2, Synthetics_WideBounds2, Treated_WideBounds3, Synthetics_WideBounds3,Treated_WideBounds4, Synthetics_WideBounds4, Treated_FreeForAll, Synthetics_FreeForAll, Treated_NoAdv, Synthetics_NoAdv, Treated_GoodMatches, Synthetics_GoodMatches, Treated_NoBounds, Synthetics_NoBounds, Treated_PWT, Synthetics_PWT)
      z[:PostGrowth1] = map((x1) -> 100*(1+x1/100 -1), z[:FGrowth1])
      z[:PostGrowth2] = map((x1,x2) -> 100*((1+x1/100)*(1+x2/100) -1), z[:FGrowth1], z[:FGrowth2])
      z[:PostGrowth3] = map((x1,x2,x3) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3])
      z[:PostGrowth4] = map((x1,x2,x3,x4) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100)*(1+x4/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3], z[:FGrowth4])
      z[:PostGrowth5] = map((x1,x2,x3,x4,x5) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100)*(1+x4/100)*(1+x5/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3], z[:FGrowth4], z[:FGrowth5])
      z[:PostGrowth6] = map((x1,x2,x3,x4,x5, x6) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100)*(1+x4/100)*(1+x5/100)*(1+x6/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3], z[:FGrowth4], z[:FGrowth5], z[:FGrowth6])
      z[:PostGrowth7] = map((x1,x2,x3,x4,x5, x6, x7) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100)*(1+x4/100)*(1+x5/100)*(1+x6/100)*(1+x7/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3], z[:FGrowth4], z[:FGrowth5], z[:FGrowth6], z[:FGrowth7])
end

LDs = [:LevelDiff1, :LevelDiff2, :LevelDiff3, :LevelDiff4, :LevelDiff5, :LevelDiff6, :LevelDiff7]
PostGrowths = [:PostGrowth1, :PostGrowth2, :PostGrowth3, :PostGrowth4, :PostGrowth5, :PostGrowth6, :PostGrowth7]
for (h, pg) in enumerate(PostGrowths)
      TempDiff = convert(Array, Treated_CAB[pg]-Synthetics_CAB[pg])
      RobustnessChecks[h+2,1] = mean(TempDiff)
      TempDiff = convert(Array, Treated_Infl[pg]-Synthetics_Infl[pg])
      RobustnessChecks[h+2,2] = mean(TempDiff)
      TempDiff = convert(Array, Treated_EXDEBT[pg]-Synthetics_EXDEBT[pg])
      RobustnessChecks[h+2,3] = mean(TempDiff)
      TempDiff = convert(Array, Treated_WideBounds2[pg]-Synthetics_WideBounds2[pg])
      RobustnessChecks[h+2,4] = mean(TempDiff)
      TempDiff = convert(Array, Treated_FreeForAll[pg]-Synthetics_FreeForAll[pg])
      RobustnessChecks[h+2,5] = mean(TempDiff)
      TempDiff = convert(Array, Treated_NoAdv[pg]-Synthetics_NoAdv[pg])
      RobustnessChecks[h+2,6] = mean(TempDiff)
      TempDiff = convert(Array, Treated_GoodMatches[pg]-Synthetics_GoodMatches[pg])
      RobustnessChecks[h+2,7] = mean(TempDiff)
      TempDiff = convert(Array, Treated_PWT[pg]-Synthetics_PWT[pg])
      RobustnessChecks[h+2,8] = mean(TempDiff)
      TempDiff = convert(Array, Treated_WideBounds1[pg]-Synthetics_WideBounds1[pg])
      RobustnessChecks[h+2,9] = mean(TempDiff)
      TempDiff = convert(Array, Treated_WideBounds3[pg]-Synthetics_WideBounds3[pg])
      RobustnessChecks[h+2,10] = mean(TempDiff)
      TempDiff = convert(Array, Treated_WideBounds4[pg]-Synthetics_WideBounds4[pg])
      RobustnessChecks[h+2,11] = mean(TempDiff)  
      TempDiff = convert(Array, Treated_NoBounds[pg]-Synthetics_NoBounds[pg])
      RobustnessChecks[h+2,12] = mean(TempDiff)    
end

#Define gray colors
g1 = RGB(.1,.1,.1)
g2 = RGB(.25,.25,.25)
g3 = RGB(.4,.4,.4)
g4 = RGB(.53,.53,.53)
g5 = RGB(.7,.7,.7)
g6 = RGB(.82,.82, .82)
g7 = RGB(.9,.9,.9)

t = collect(0:1:7)
#---GRAPH WITH ALL ROBUSTNESS (Figure 3b) --------#
plot(t, [0; MainBetas[:,1]], linewidth=2, color=:black, grid=false, label="", ylabel="", xlabel="Years From Crisis", legend=(0.1,0.3), legendfontsize=7, ylims=(-3,5.3), marker=([:circle], [:black], [2.5]))
plot!(t, RobustnessChecks[2:end, 1], linewidth=1.5, color=g1, style=:dashdot, label="+CAB", marker=([:hexagon], [g1], [2]))
plot!(t, RobustnessChecks[2:end, 2], linewidth=1.5, color=g2, style=:dashdot, label="+Infl",  marker=([:rect], [g2], [2]))
plot!(t, RobustnessChecks[2:end, 3], linewidth=1.5, color=g3, style=:dot, label="+Debt",  marker=([:xcross], [g3], [2]))
plot!(t, RobustnessChecks[2:end, 4], linewidth=1.5, color=g4, style=:dashdot, label="Wide Bounds",  marker=([:utriangle], [g4], [2]))
plot!(t, RobustnessChecks[2:end, 5], linewidth=1.5, color=g5, style=:dot, label="Any Crisis Type",  marker=([:star4], [g5], [2]))
plot!(t, RobustnessChecks[2:end, 6], linewidth=1.5, color=g6, style=:dashdot, label="No Adv.",  marker=([:+], [g6], [2]))
plot!(t, RobustnessChecks[2:end, 7], linewidth=1.5, color=g7, style=:dashdot, label="Good Matches",  marker=([:pentagon], [g7], [2]))
hline!([0], color=:black, style=:dot, label="")
savefig(joinpath(output_directory, "Robustness.pdf"))

#--Something weird here--#
plot(t, [0; MainBetas[:,1]], linewidth=2, color=:black, label="", ylabel="", grid=false, xlabel="Years From Crisis", legend=(0.1,0.3), legendfontsize=7, ylims=(-3,5.3), marker=([:circle], [:black], [2]))
plot!(t, RobustnessChecks[2:end, 8], linewidth=1.5, color=g2, style=:dashdot, label="PWT", marker=([:hexagon], [g2], [2]))
plot!(t, RobustnessChecks[2:end, 9], linewidth=1.5, color=g3, style=:dashdot, label="+/-9",  marker=([:rect], [g3], [2]))
plot!(t, RobustnessChecks[2:end, 4], linewidth=1.5, color=g4, style=:dot, label="+/-11",  marker=([:xcross], [g4], [2]))
plot!(t, RobustnessChecks[2:end, 10], linewidth=1.5, color=g5, style=:dashdot, label="+/-13",  marker=([:utriangle], [g5], [2]))
plot!(t, RobustnessChecks[2:end, 11], linewidth=1.5, color=g6, style=:dot, label="+/-15",  marker=([:star4], [g6], [2]))
plot!(t, RobustnessChecks[2:end, 12], linewidth=1.5, color=g7, style=:dashdot, label="+/-25",  marker=([:pentagon], [g7], [2]))
hline!([0], color=:black, style=:dot, label="")
savefig(joinpath(output_directory, "Robustness_Appendix.pdf"))
