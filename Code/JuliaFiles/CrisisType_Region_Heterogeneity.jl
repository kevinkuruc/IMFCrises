function ByCrisisType()
Averages =[]
Crisis = []
N = []
LowBound = []
UpBound = []
	for c in (:Banking, :Currency, :Debt)
		Mean = mean(TreatedMatched[TreatedMatched[:, c].==1, :CumulativeEffect])
		SVar = var(TreatedMatched[TreatedMatched[:, c].==1, :CumulativeEffect])
		StErr = sqrt(SVar/length(TreatedMatched[TreatedMatched[:, c].==1, :CumulativeEffect]))
		lb = Mean-StErr
		ub = Mean+StErr
		push!(Averages, Mean)
		push!(Crisis, string(c))
        push!(N, length(TreatedMatched[TreatedMatched[:, c].==1, :CumulativeEffect]))
        push!(LowBound, lb)
        push!(UpBound, ub)
	end
Out = [Crisis Averages N]
BankN = N[1]
CurrN = N[2]
DebtN = N[3]
bar(["Banking \n ($BankN)", "Currency \n ($CurrN)", "Debt \n ($DebtN)"], Averages, color=:gray, label="", ylabel="Est. Cumulative Effect")
savefig(joinpath(output_directory, "CrisisTypeBar.pdf"))
return Out
end

function ByRegion()
	Averages =[]
    Regions = []
    N = []
	for r in ("Africa", "Asia", "Europe", "Island", "LatAm", "MidEast")
		Mean = mean(TreatedMatched[TreatedMatched[:, :Region].==r, :CumulativeEffect])
		push!(Averages, Mean)
		push!(Regions, r)
        push!(N, length(TreatedMatched[TreatedMatched[:, :Region].==r, :CumulativeEffect]))
	end
Out = [Regions Averages N]
AfricaN = N[1]
AsiaN = N[2]
EuropeN = N[3]
IslandsN = N[4]
LatAmN = N[5]
MidEastN = N[6]
bar(["Africa \n ($AfricaN)", "Asia \n ($AsiaN)", "Europe \n ($EuropeN)", "Latin Am. \n ($LatAmN)", "Mid Eat \n ($MidEastN)", "Small Islands \n ($IslandsN)"], Averages, color=:gray, label="", ylabel="Est. Cumulative Effect")
savefig(joinpath(output_directory, "RegionsBar.pdf"))    
return Out
end