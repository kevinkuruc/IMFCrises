function HeterogeneityScatter(s::Symbol)
	Temp = dropmissing(TreatedMatched[:, [:Country, :year, s, :CumulativeEffect]])
	x 	= convert(Array, Temp[s])
	y 	= convert(Array, Temp[:CumulativeEffect])
	(b,v) = Regress(y,x)
	yhat = b[1]ones(size(x)[1]) + b[2]*x
	ss = string(s)
	scatter(Temp[s], Temp[:CumulativeEffect], label="", ylabel="Estimated Cumulative Effect", xlabel="Conditionality Index", markersize=[1], marker=:x)
	plot!(x, yhat, label="", linecolor=:black, linewidth=[2])
	savefig(joinpath(output_directory, "Heterogeneity_$ss.pdf"))
end