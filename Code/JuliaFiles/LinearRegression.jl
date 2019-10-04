function Regress(Y, DATA)
	n = length(DATA[:,1])
	k = length(DATA[1,:])
	cons = ones(n,1)
	X = [cons DATA]
	Xprimeinv = inv(X'*X)
	Betahat = Xprimeinv*X'*Y
	u = Y-X*Betahat
	Xeps = zeros(n,k+1)
	for i = 1:n
		Xeps[i,:] = u[i]*X[i,:]
	end
	VarHetero = Xprimeinv*Xeps'*Xeps*Xprimeinv
	return Betahat, VarHetero
end