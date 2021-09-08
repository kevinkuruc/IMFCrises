# Runs a new synthetic control for each horizon, in order to leverage more data at earlier horizons.
# For example: in main run, crises in 2016 won't be used for horizons 1,2,3 even though the data is available because
# their full set of post-crisis growth rates is not complete. Here they are used because they're estimated separately.
function New_Sample_Each_Horizon()
bounds  = [B, B, B, B, B, B, .5, .5, .5]
W       = ones(10,1)
matchon = [:LGrowth5, :LGrowth4, :LGrowth3, :LGrowth2, :LGrowth1, :DWDI, :Banking, :Currency, :Debt]

predict1 = [:FGrowth1]
(Treated_F1, Synthetics_F1, Weights_F1) = GenSynthetics(IMFCrises, NoIMFCrises, matchon, predict1, localtol=bounds, matchweights=W);
N1 		 = size(Treated_F1, 1)
println("N1 is $N1")

predict2 = [:FGrowth1, :FGrowth2]
(Treated_F2, Synthetics_F2, Weights_F2) = GenSynthetics(IMFCrises, NoIMFCrises, matchon, predict2, localtol=bounds, matchweights=W);
N2 		 = size(Treated_F2, 1)
println("N2 is $N2")

predict3 = [:FGrowth1, :FGrowth2, :FGrowth3]
(Treated_F3, Synthetics_F3, Weights_F3) = GenSynthetics(IMFCrises, NoIMFCrises, matchon, predict3, localtol=bounds, matchweights=W);
N3 		 = size(Treated_F3, 1)
println("N3 is $N3")

predict4 = [:FGrowth1, :FGrowth2, :FGrowth3, :FGrowth4]
(Treated_F4, Synthetics_F4, Weights_F4) = GenSynthetics(IMFCrises, NoIMFCrises, matchon, predict4, localtol=bounds, matchweights=W);
N4 		 = size(Treated_F4, 1)
print("N4 is $N4")

predict5 = [:FGrowth1, :FGrowth2, :FGrowth3, :FGrowth4, :FGrowth5]
(Treated_F5, Synthetics_F5, Weights_F5) = GenSynthetics(IMFCrises, NoIMFCrises, matchon, predict5, localtol=bounds, matchweights=W);
N5 		 = size(Treated_F5, 1)
print("N5 is $N5")

predict6 = [:FGrowth1, :FGrowth2, :FGrowth3, :FGrowth4, :FGrowth5, :FGrowth6]
(Treated_F6, Synthetics_F6, Weights_F6) = GenSynthetics(IMFCrises, NoIMFCrises, matchon, predict6, localtol=bounds, matchweights=W);
N6 		 = size(Treated_F6, 1)
print("N6 is $N6")


Treated_F1[!,:PostGrowth1] = map((x1) -> 100*(1+x1/100 -1), Treated_F1[!,:FGrowth1])
Synthetics_F1[!,:PostGrowth1] = map((x1) -> 100*(1+x1/100 -1), Synthetics_F1[!,:FGrowth1])
Treated_F2[!,:PostGrowth2] = map((x1,x2) -> 100*((1+x1/100)*(1+x2/100) -1), Treated_F2[!,:FGrowth1], Treated_F2[!,:FGrowth2])
Synthetics_F2[!,:PostGrowth2] = map((x1,x2) -> 100*((1+x1/100)*(1+x2/100) -1), Synthetics_F2[!,:FGrowth1], Synthetics_F2[!,:FGrowth2])
Treated_F3[!,:PostGrowth3] = map((x1,x2,x3) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100) -1), Treated_F3[!,:FGrowth1], Treated_F3[!,:FGrowth2], Treated_F3[!,:FGrowth3])
Synthetics_F3[!,:PostGrowth3] = map((x1,x2,x3) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100) -1), Synthetics_F3[!,:FGrowth1], Synthetics_F3[!,:FGrowth2], Synthetics_F3[!,:FGrowth3])
Treated_F4[!,:PostGrowth4] = map((x1,x2,x3,x4) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100)*(1+x4/100) -1), Treated_F4[!,:FGrowth1], Treated_F4[!,:FGrowth2], Treated_F4[!,:FGrowth3], Treated_F4[!,:FGrowth4])
Synthetics_F4[!,:PostGrowth4] = map((x1,x2,x3,x4) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100)*(1+x4/100) -1), Synthetics_F4[!,:FGrowth1], Synthetics_F4[!,:FGrowth2], Synthetics_F4[!,:FGrowth3], Synthetics_F4[!,:FGrowth4])
Treated_F5[!,:PostGrowth5] = map((x1,x2,x3,x4,x5) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100)*(1+x4/100)*(1+x5/100) -1), Treated_F5[!,:FGrowth1], Treated_F5[!,:FGrowth2], Treated_F5[!,:FGrowth3], Treated_F5[!,:FGrowth4], Treated_F5[!,:FGrowth5])
Synthetics_F5[!,:PostGrowth5] = map((x1,x2,x3,x4,x5) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100)*(1+x4/100)*(1+x5/100) -1), Synthetics_F5[!,:FGrowth1], Synthetics_F5[!,:FGrowth2], Synthetics_F5[!,:FGrowth3], Synthetics_F5[!,:FGrowth4], Synthetics_F5[!,:FGrowth5])
Treated_F6[!,:PostGrowth6] = map((x1,x2,x3,x4,x5, x6) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100)*(1+x4/100)*(1+x5/100)*(1+x6/100) -1), Treated_F6[!,:FGrowth1], Treated_F6[!,:FGrowth2], Treated_F6[!,:FGrowth3], Treated_F6[!,:FGrowth4], Treated_F6[!,:FGrowth5], Treated_F6[!,:FGrowth6])
Synthetics_F6[!,:PostGrowth6] = map((x1,x2,x3,x4,x5, x6) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100)*(1+x4/100)*(1+x5/100)*(1+x6/100) -1), Synthetics_F6[!,:FGrowth1], Synthetics_F6[!,:FGrowth2], Synthetics_F6[!,:FGrowth3], Synthetics_F6[!,:FGrowth4], Synthetics_F6[!,:FGrowth5], Synthetics_F6[!,:FGrowth6])

horizons = zeros(7)
horizons[2] = mean(Array(Treated_F1[!,:PostGrowth1]-Synthetics_F1[!,:PostGrowth1]))
horizons[3] = mean(Array(Treated_F2[!,:PostGrowth2]-Synthetics_F2[!,:PostGrowth2]))
horizons[4] = mean(Array(Treated_F3[!,:PostGrowth3]-Synthetics_F3[!,:PostGrowth3]))
horizons[5] = mean(Array(Treated_F4[!,:PostGrowth4]-Synthetics_F4[!,:PostGrowth4]))
horizons[6] = mean(Array(Treated_F5[!,:PostGrowth5]-Synthetics_F5[!,:PostGrowth5]))
horizons[7] = mean(Array(Treated_F6[!,:PostGrowth6]-Synthetics_F6[!,:PostGrowth6]))
return horizons
end