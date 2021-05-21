using GLM
## Crisis Type
	Temp = dropmissing(TreatedMatched[:, [:Country, :year, :Banking, :Currency, :Debt, :CumulativeEffect]])
	n = size(Temp)[1]
	println("N is $n")
	lm(@formula(CumulativeEffect ~ 0 + Banking + Currency + Debt), Temp)

## Region
	Temp = dropmissing(TreatedMatched[:, [:Country, :year, :Region, :CumulativeEffect]])
	n = size(Temp)[1]
		println("N is $n")
	for r in (:Africa, :SA, :EAP, :ECA, :LAC, :MidEast)
		s = string(r)
		array = zeros(n)	
			for i = 1:n
				if Temp[i, :Region] == s
					array[i] = 1
				end
			end
		Temp[r] = array
	end
 	lm(@formula(CumulativeEffect ~ 0 + Africa + SA + EAP + ECA + LAC + MidEast), Temp)
##Loan Size
	Temp = dropmissing(TreatedMatched[:, [:Country, :year, :AmountAgreedPercentGDP, :CumulativeEffect]])
	#Temp = Temp[Temp[:,:AmountAgreedPercentGDP].<30, :] #This completely drives any effect
		n = size(Temp)[1]
		println("N is $n")
	lm(@formula(CumulativeEffect ~ AmountAgreedPercentGDP), Temp)
##Amount Drawn Size
	Temp = dropmissing(TreatedMatched[:, [:Country, :year, :AmountDrawnPercentAgreed, :CumulativeEffect]])
	Temp = Temp[Temp[:,:AmountDrawnPercentAgreed].>0,:]
	n = size(Temp, 1)
	println("N is $n")
	lm(@formula(CumulativeEffect ~ AmountDrawnPercentAgreed), Temp)
##Conditions
	Temp = dropmissing(TreatedMatched[:, [:Country, :year, :conditions, :quant_conditions, :structural_conditions, :CumulativeEffect]])
			n = size(Temp)[1]
		println("N is $n")
	lm(@formula(CumulativeEffect ~ conditions), Temp)
	lm(@formula(CumulativeEffect ~ quant_conditions + structural_conditions), Temp)
##Governance
	Temp = dropmissing(TreatedMatched[:, [:Country, :year, :WGI, :CumulativeEffect]])
				n = size(Temp)[1]
		println("N is $n")
	lm(@formula(CumulativeEffect ~ WGI), Temp)
##Time Trend
	Temp = dropmissing(TreatedMatched[:, [:Country, :year, :CumulativeEffect]])
					n = size(Temp)[1]
		println("N is $n")
		Temp[:year] = Temp[:year] - 1990*ones(n)
	lm(@formula(CumulativeEffect ~ year), Temp)
##All w/Crisis
	Temp = dropmissing(TreatedMatched[:, [:Country, :year, :Region, :Banking, :Currency, :Debt, :AmountAgreedPercentGDP, :conditions, :WGI, :CumulativeEffect]])
	Temp = Temp[Temp[:,:AmountAgreedPercentGDP].<30, :]
						n = size(Temp)[1]
		println("N is $n")
	Temp[:year] = Temp[:year] - 1990*ones(n)
	lm(@formula(CumulativeEffect ~ AmountAgreedPercentGDP + conditions + year + WGI), Temp)
	lm(@formula(CumulativeEffect ~ 0 + Banking + Currency + Debt + AmountAgreedPercentGDP + conditions + year + WGI), Temp)
##All w/Region
	n = size(Temp)[1]
	for r in (:Africa, :SA, :EAP, :ECA, :LAC, :MidEast)
		s = string(r)
		array = zeros(n)	
			for i = 1:n
				if Temp[i, :Region] == s
					array[i] = 1
				end
			end
		Temp[r] = array
	end
lm(@formula(CumulativeEffect ~ 0 + Africa + SA + EAP + ECA + LAC + MidEast + AmountAgreedPercentGDP + conditions + year + WGI), Temp)