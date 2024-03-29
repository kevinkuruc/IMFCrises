function HeterogeneityScatter(s::Symbol)
	Temp = DataFrame()
	Temp2 = DataFrame()
	if s != :year
	Temp = dropmissing(TreatedMatched[:, [:Country, :year, s, :CumulativeEffect]])
	else 
	Temp = dropmissing(TreatedMatched[:, [:Country, s, :CumulativeEffect]])
	end
	x 	= Array(Temp[!,s])
	y 	= Array(Temp[!,:CumulativeEffect])
	(b,v) = Regress(y,x)
	yhat = b[1]ones(size(x, 1)) + b[2]*x
	if s == :AmountAgreedPercentGDP
		Temp2 = Temp[Temp[:,:AmountAgreedPercentGDP].<30, :]
			x2 	= Array(Temp2[!,s])
			y 	= Array(Temp2[!,:CumulativeEffect])
			(b,v) = Regress(y,x2)
			yhat2 = b[1]ones(size(x2,1)) + b[2]*x2
			println("Amount Agreed b2 is $b")
	elseif s ==:AmountDrawnPercentAgreed
		Temp2 = Temp[Temp[:,:AmountDrawnPercentAgreed].>0, :]
			x2 	= Array(Temp2[!,s])
			y 	= Array(Temp2[!,:CumulativeEffect])
			(b,v) = Regress(y,x2)
			yhat2 = b[1]ones(size(x2)[1]) + b[2]*x2
			println("Amount drawn b2 is $b")
	elseif s ==:structural_conditions
			Temp2 = Temp[Temp[:, :structural_conditions].<40, :]
			x2 	= Array(Temp2[!,s])
			y 	= Array(Temp2[!,:CumulativeEffect])
			(b,v) = Regress(y,x2)
			yhat2 = b[1]*ones(size(x2, 1)) + b[2]*x2
			println("Structural conditions b2 is $b")
	end


	ss = string(s)
	xlab = ""
	if s ==:year
		xlab = "Year"
	elseif s==:WGI 
		xlab="World Governance Indicator"
	elseif s==:conditions
		xlab="Conditionality Index"
	elseif s==:AmountAgreedPercentGDP
		xlab= "Size of Loan (% of GDP)"
	elseif s==:quant_conditions
		xlab= "Quantitative Conditions"
	elseif s==:structural_conditions
		xlab= "Structural Conditions"
	elseif s==:AmountDrawnPercentAgreed
		xlab="Amount Drawn (Fraction of Agreed)"
	end
	scatter(Temp[!,s], Temp[!,:CumulativeEffect], label="", ylabel="Estimated Cumulative Output Effect \n (% of crisis year GDP)", guidefontsize = 8, grid=false, xlabel=xlab, marker=:x, markercolor=:gray, ylims=(-100,200),  markersize=2)
	plot!(x, yhat, label="", linecolor=treatedblue, linestyle=:solid, linewidth=[1.7], fontfamily="Times")
	if s ==:AmountAgreedPercentGDP 
	plot!([minimum(x2); maximum(x2)], [minimum(yhat2); maximum(yhat2)], label="Without Outlier", linecolor=:gray, linestyle=:dash, linewidth=[1.5], xlims=(0, 15.1))
	elseif s ==:AmountDrawnPercentAgreed
	plot!([minimum(x2); maximum(x2)], [minimum(yhat2); maximum(yhat2)], label="Without Zeros", linecolor=:gray, linestyle=:dash, linewidth=[1.5])	
	elseif s ==:structural_conditions
	plot!([minimum(x2); maximum(x2)], [minimum(yhat2); maximum(yhat2)], label="Without Outlier", linecolor=:gray, linestyle=:dash, linewidth=[1.5])
	end
	savefig(joinpath(output_directory, "Heterogeneity_$ss.pdf"))
	savefig(joinpath(output_directory, "Heterogeneity_$ss.svg"))
end