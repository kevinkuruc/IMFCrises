using DataFrames
using JuMP
using Ipopt
using NLopt
using LinearAlgebra

function GenSynthetics(Treated::DataFrame, Pool::DataFrame, matchon::Array{Symbol,1}, predict::Array{Symbol,1}; matchtol = Inf, localtol = Inf*ones(15,1), matchweights=ones(15,1))
	m = size(matchon)[1]
	b = size(localtol)[1]
		if m >b  
		println("Must include more bounds than matching variables. Program only fitted to handled 10 matching vars, if including more must manually enter a vector of tolerances as localtol=[Inf ... Inf]")
		return false
		end

	#################################################################
	# First step is to get rid of any observations missing either the matching variables
	# or the main outcome variable we plan to track (growth paths here)
	#################################################################
	bign = size(Treated)[1]
	bigp = size(Pool)[1]
	Treated[:ID] = collect(1:1:bign)
	Pool[:ID] = collect(1:1:bigp)
	completecheck = [:ID; matchon; predict]
	tempTreat = Treated[:, completecheck]
	tempPool = Pool[:, completecheck]
	tempTreat = tempTreat[completecases(tempTreat),:]
	tempPool = tempPool[completecases(tempPool),:]
	TreatCompleteID = DataFrame(ID = tempTreat[:ID])
	PoolCompleteID = DataFrame(ID = tempPool[:ID])
	Treated = join(Treated, TreatCompleteID, on=:ID, kind=:inner)
	Pool = join(Pool, PoolCompleteID, on=:ID, kind=:inner)
	completen = size(Treated)[1]
	completep = size(Pool)[1]
	############################################################
	# Now have only treated and controls with full growth data
	############################################################
	
	Treated[:ID] = collect(1:1:completen)
	Pool[:ID] = collect(1:1:completep)
	#println("Put in new IDs")
	Weights = Pool[:, [:Country, :year, :ID]]
	Synthetic = Pool[1,[[:Country, :year]; matchon; predict]]
	Synthetic[:SqError] = [0.]
	deleterows!(Synthetic, 1)
	TreatedMatched = Treated[1,:]
	deleterows!(TreatedMatched,1)
	for i = 1:completen
		obs = Treated[i,:]  #pull one obs to match
		LocalPool = Pool[Pool[:year].>0,:]  #just want to copy 
		country = obs[1, :Country]
		yr = obs[1, :year]
		tomatch = ones(m)   # the vector of data to minimize distance between
			for v = 1:m  #populate this vector
				j = convert(Array, obs[matchon[v]])
				tomatch[v] = j[1]
			end
			#Trim to only local matches
			for v = 1:m
			q  = size(LocalPool)[1]
			LocalPool = LocalPool[abs.(LocalPool[matchon[v]]-tomatch[v]*ones(q)).<localtol[v],:]
			end
			q = size(LocalPool)[1] #trimmed to local size
			PoolWeight = DataFrame(ID = LocalPool[:ID])
	if q==0
		println("$country $yr has no local matches")
	else
		println("$country $yr has local matches!")
		obsvec = convert(Array, obs)
		poolMatrixMatching = ones(q,m)
			for v = 1:m
				poolMatrixMatching[:,v] = convert(Array, LocalPool[:,matchon[v]])
			end
		poolMatrixMatching = poolMatrixMatching'
		weightmatrix = zeros(m,m)
			for M in 1:m
			weightmatrix[M,M] = matchweights[M]
			end

	#Now need to declare as a model to minimize over
		function SSE(x)
			(weightmatrix*(tomatch - poolMatrixMatching*x))'*(weightmatrix*(tomatch - poolMatrixMatching*x))	
		end
		function sumone(x)
			sum(x) -1
		end
		opt = Opt(:LN_COBYLA, q)
		lower_bounds!(opt, zeros(q))
		upper_bounds!(opt, ones(q))
		equality_constraint!(opt, (x, grad) -> sumone(x), 1e-10)
		ftol_rel!(opt, 1e-8)
		xtol_rel!(opt, 1e-5)
		maxtime!(opt, 60)
		#maxeval!(opt, 50)  #maxtime seemed to fail on certain runs so added this only for an appendix check
		min_objective!(opt, (x, grad) -> SSE(x))  #calls on the inner function above 

		initguess = 1/q * ones(q)
		(sol, weight, ret) = optimize(opt, initguess);
		#Now want to create my synthetic observation
		if sol < matchtol
		RelevantPoolData = LocalPool[:, [matchon; predict]]
		poolForCollapse = convert(Array, RelevantPoolData)
		Collapsed = weight'*poolForCollapse
		Synthvect = ["Synthetic $country" yr Collapsed sol]
		push!(Synthetic, Synthvect)
		println("Pushed Synthetic")
		foradd = convert(Array, Treated[i,:])
		push!(TreatedMatched, foradd)
		println("Pushed Treated")
		PoolWeight[:weight] = weight
		Weights = join(Weights, PoolWeight, on=:ID, kind=:outer)
		end
	end
	end
	#########################################
	# Need to replace missing weights with 0
	#########################################
	NMatched = size(TreatedMatched)[1]
	for i = 1:NMatched+3  #have 3 extra rows for country, year id
		for j = 1:completep
			if typeof(Weights[j,i])==Missing
				Weights[j,i]=0
			end
		end
	end
	return TreatedMatched, Synthetic, Weights
end