# -- Define Options -- #

IMF_NoAdv = IMFCrises[NoIMFCrises[:advecon].!=1, :]
NoIMF_NoAdv = NoIMFCrises[NoIMFCrises[:advecon].!=1, :]
Bounds = [7, 8, 9]
Covariates = [:CAB, :Infl, :DEBT]
AllBetas = zeros(6)
count=0
for data = (NoIMFCrises, NoIMF_NoAdv)
	for (i, x) = enumerate(Covariates)
		for b = Bounds
			count = count+1
			if i == 1
				matchon = [:LGrowth5, :LGrowth4, :LGrowth3, :LGrowth2, :LGrowth1, :DWDI, :Banking, :Currency, :Debt]
				Weights = ones(10,1)
				bounds  = [b, b, b, b, b, b, .5, .5, .5]
			elseif i>1
				matchon = [:LGrowth5, :LGrowth4, :LGrowth3, :LGrowth2, :LGrowth1, :DWDI, :Banking, :Currency, :Debt, x]
				completecheck 	= [:Country, :year, :DWDI, x]
				tempTreat 		= IMFCrises[:, completecheck]
				tempTreat 		= tempTreat[completecases(tempTreat),:]
				Treated_wCov 	= join(IMFCrises, tempTreat, on=[:Country, :year], kind=:inner)
				GrowthVariance 	= var(Treated_wCov[:DWDI])
				XVariance	   	= var(Treated_wCov[x])
				Weights 		= ones(size(matchon))
				Weights[end]	= GrowthVariance/XVariance
			end
			(Treated_temp, Synthetics_temp, Weights_temp) = GenSynthetics(IMFCrises, NoIMFCrises, matchon, predict, localtol=bounds, matchweights=Weights);
			for z = (Treated_temp, Synthetics_temp)
      			z[:PostGrowth1] = map((x1) -> 100*(1+x1/100 -1), z[:FGrowth1])
      			z[:PostGrowth2] = map((x1,x2) -> 100*((1+x1/100)*(1+x2/100) -1), z[:FGrowth1], z[:FGrowth2])
      			z[:PostGrowth3] = map((x1,x2,x3) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3])
      			z[:PostGrowth4] = map((x1,x2,x3,x4) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100)*(1+x4/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3], z[:FGrowth4])
      			z[:PostGrowth5] = map((x1,x2,x3,x4,x5) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100)*(1+x4/100)*(1+x5/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3], z[:FGrowth4], z[:FGrowth5])
      			z[:PostGrowth6] = map((x1,x2,x3,x4,x5, x6) -> 100*((1+x1/100)*(1+x2/100)*(1+x3/100)*(1+x4/100)*(1+x5/100)*(1+x6/100) -1), z[:FGrowth1], z[:FGrowth2], z[:FGrowth3], z[:FGrowth4], z[:FGrowth5], z[:FGrowth6])
			end
			TempDiffDataFrame = DataFrame(Country = Treated_temp[:Country], year = Treated_temp[:year])
			TempDiffDataFrame[:LevelDiff1] = map((x1, x2) -> x1-x2, Treated_temp[:PostGrowth1], Synthetics_temp[:PostGrowth1])
			TempDiffDataFrame[:LevelDiff2] = map((x1, x2) -> x1-x2, Treated_temp[:PostGrowth2], Synthetics_temp[:PostGrowth2])
			TempDiffDataFrame[:LevelDiff3] = map((x1, x2) -> x1-x2, Treated_temp[:PostGrowth3], Synthetics_temp[:PostGrowth3])
			TempDiffDataFrame[:LevelDiff4] = map((x1, x2) -> x1-x2, Treated_temp[:PostGrowth4], Synthetics_temp[:PostGrowth4])
			TempDiffDataFrame[:LevelDiff5] = map((x1, x2) -> x1-x2, Treated_temp[:PostGrowth5], Synthetics_temp[:PostGrowth5])
			TempDiffDataFrame[:LevelDiff6] = map((x1, x2) -> x1-x2, Treated_temp[:PostGrowth6], Synthetics_temp[:PostGrowth6])
			LDs = [:LevelDiff1, :LevelDiff2, :LevelDiff3, :LevelDiff4, :LevelDiff5, :LevelDiff6]
				for (z, w) in enumerate(LDs)
					tempBeta[z] = mean(TempDiffDataFrame[w])
				end
			AllBetas = [AllBetas, tempBeta]
		end
	end
end
