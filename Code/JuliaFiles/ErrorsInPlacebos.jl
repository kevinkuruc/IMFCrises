

include("RunningPlacebosFunction.jl")

function ErrorsInPlacebos(matchon, W, bounds, predict, Pool, h)  #here h is horizon I want these errors for
	
	(Placebos, Synths)	= RunningPlacebos(matchon, W, bounds, predict, Pool)

	Errors = DataFrame()
	Errors[:PostError1] = map((x,y) -> x-y, Placebos[:PostGrowth1], Synths[:PostGrowth1])
	Errors[:PostError2] = map((x,y) -> x-y, Placebos[:PostGrowth2], Synths[:PostGrowth2])
	Errors[:PostError3] = map((x,y) -> x-y, Placebos[:PostGrowth3], Synths[:PostGrowth3])
	Errors[:PostError4] = map((x,y) -> x-y, Placebos[:PostGrowth4], Synths[:PostGrowth4])
	Errors[:PostError5] = map((x,y) -> x-y, Placebos[:PostGrowth5], Synths[:PostGrowth5])

	Diffs = convert(Array, [Errors[:PostError1] Errors[:PostError2] Errors[:PostError3] Errors[:PostError4] Errors[:PostError5]])

	ParamCovariance = (1/size(Diffs)[1])*Diffs'*Diffs  #calculate variance by hand assuming mean zero (which is "known" in some sense)
	RelevantVariance = ParamCovariance[h,h]
return RelevantVariance
end