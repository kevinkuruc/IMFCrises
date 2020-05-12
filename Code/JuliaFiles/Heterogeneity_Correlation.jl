function HeterogeneityScatter(s::Symbol)
	if s != :year
	Temp = dropmissing(TreatedMatched[:, [:Country, :year, s, :CumulativeEffect]])
	else 
	Temp = dropmissing(TreatedMatched[:, [:Country, s, :CumulativeEffect]])
	end
	if s == :AmountAgreedPercentGDP
		Temp = Temp[Temp[:,:AmountAgreedPercentGDP].<30, :]
	end
	x 	= convert(Array, Temp[s])
	y 	= convert(Array, Temp[:CumulativeEffect])
	(b,v) = Regress(y,x)
	yhat = b[1]ones(size(x)[1]) + b[2]*x
	ss = string(s)
	xlab = ""
	if s ==:year
		xlab = "Year"
	elseif s==:WGI 
		xlab="World Governance Indicator"
	elseif s==:conditions
		xlab="Conditionality Index"
	else
		xlab= "Size of Loan (as % GDP)"
	end
	scatter(Temp[s], Temp[:CumulativeEffect], label="", ylabel="Estimated Cumulative Effect", xlabel=xlab, markersize=[1], marker=:x, ylims=(-100,200))
	plot!(x, yhat, label="", linecolor=:black, linewidth=[2])
	savefig(joinpath(output_directory, "Heterogeneity_$ss.pdf"))
end