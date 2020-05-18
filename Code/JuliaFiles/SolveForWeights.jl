#####################################################
# This function takes the matching variables and
# the pool of donor countries to solve for the 
# specification that minimizes the errors in the placebo runs.
# Note its written to require you to use all 6 pre-periods of 
# growth rate data as a potential matching variable.
# It can opt not to use them (a weight of zero) but they 
# MUST be included in the 'matchon' variable. And they 
# MUST be the first 6 entries in it. The last 3 must be
# Banking Currency Debt
#####################################################

include(joinpath(code_directory, "ErrorsInPlacebos.jl"))


function MinimizeForWeights(matchon, bounds, predict, Pool, horizon=3)
 	dim = size(matchon)[1]
	opt = Opt(:LN_SBPLX, dim)
	low = zeros(dim)
	up = 5*ones(dim)
	low[1] = 1
	up[1] = 1
	low[end-2:end] = ones(3)
	up[end-2:end] = ones(3)
	lower_bounds!(opt, low)
	upper_bounds!(opt, up)
	ftol_rel!(opt, 1e-8)
	maxtime!(opt, 14400)
		 function Min(x)
		 	ErrorsInPlacebos(matchon, x, bounds, predict, Pool, horizon)
		 end
		 min_objective!(opt, (x, grad) -> Min(x))
		 init = ones(dim)

		 (sol, Weights) = optimize(opt, init)
		 return Weights
end