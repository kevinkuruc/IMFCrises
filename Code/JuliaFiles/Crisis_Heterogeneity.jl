function ByCrisisType()
Averages =[]
Crisis = []
N = []
	for c in (:Banking, :Currency, :Debt)
		Mean = mean(TreatedMatched[TreatedMatched[:, c].==1, :CumulativeEffect])
		push!(Averages, Mean)
		push!(Crisis, string(c))
        push!(N, length(TreatedMatched[TreatedMatched[:, c].==1, :CumulativeEffect]))
	end
Out = [Crisis Averages N]
return Out
end

function ByRegion()
	Averages =[]
    Regions = []
    N = []
	for r in ("Africa", "Asia", "Europe", "Island", "LatAm", "MidEast", "Rich")
		Mean = mean(TreatedMatched[TreatedMatched[:, :Region].==r, :CumulativeEffect])
		push!(Averages, Mean)
		push!(Regions, r)
        push!(N, length(TreatedMatched[TreatedMatched[:, :Region].==r, :CumulativeEffect]))
	end
Out = [Regions Averages N]
return Out
end