--!strict

type Vector = { number }
type Matrix = { Vector }

local Matrix = {}

-- Private

local function _matrixToString(M: Matrix): string
	local lines = {}
	for i = 1, #M do
		table.insert(lines, "[" .. table.concat(M[i], ",") .. "]")
	end
	return "\n" .. table.concat(lines, "\n") .. "\n"
end

local function multiply(A: Matrix, B: Matrix): Matrix
	local M = {}
	for r = 1, #A do
		M[r] = {}
		for c = 1, #B[1] do
			M[r][c] = 0
			for i = 1, #A[1] do
				M[r][c] = M[r][c] + (A[r][i] * B[i][c])
			end
		end
	end
	return M
end

local function transpose(M: Matrix): Matrix
	local transposed = {}
	for i = 1, #M[1] do
		transposed[i] = {}
		for j = 1, #M do
			transposed[i][j] = M[j][i]
		end
	end
	return transposed
end

local function pivot(M: Matrix): Matrix
	local n = #M

	local I = {}
	for i = 1, n do
		I[i] = {}
		for j = 1, n do
			I[i][j] = if i == j then 1 else 0
		end
	end

	for i = 1, n do
		local row = i
		local maxm = math.abs(M[i][i])
		for j = i, n do
			local abs = math.abs(M[j][i])
			if abs > maxm then
				maxm = abs
				row = j
			end
		end

		if i ~= row then
			I[i], I[row] = I[row], I[i]
		end
	end

	return I
end

local function decomposeLU(M: Matrix): (Matrix, Matrix)
	local n = #M
	local L, U = {}, {}
	for i = 1, n do
		L[i], U[i] = {}, {}
		for j = 1, n do
			L[i][j], U[i][j] = 0, 0
		end
	end

	for i = 1, n do
		for k = i, n do
			local sum = 0
			for j = 1, i do
				sum = sum + (L[i][j] * U[j][k])
			end
			U[i][k] = M[i][k] - sum
		end

		for k = i, n do
			if i == k then
				L[i][i] = 1
			else
				local sum = 0
				for j = 1, i do
					sum = sum + (L[k][j] * U[j][i])
				end
				L[k][i] = (M[k][i] - sum) / U[i][i]
			end
		end
	end

	return L, U
end

local function decomposeLUP(M: Matrix): (Matrix, Matrix, Matrix)
	local P = pivot(M)
	local PM = multiply(P, M)
	local L, U = decomposeLU(PM)
	return L, U, P
end

local function solve(A: Matrix, b: Matrix)
	-- solves for x in the form Ax = b
	local n = #A
	local L, U, P = decomposeLUP(A)
	local Pb = multiply(P, b)

	local x, y = {}, {}
	for i = 1, n do
		x[i], y[i] = 0, 0
	end

	for i = 1, n do
		local sum = 0
		for j = 1, i do
			sum = sum + L[i][j] * y[j]
		end
		y[i] = Pb[i][1] - sum
	end

	for i = n, 1, -1 do
		local sum = 0
		for j = i + 1, n do
			sum = sum + U[i][j] * x[j]
		end
		x[i] = (y[i] - sum) / U[i][i]
	end

	local xM = {}
	for i, v in x do
		xM[i] = { v }
	end

	return xM
end

-- Public

function Matrix.leastSquares(A: Matrix, b: Matrix): Matrix
	local At = transpose(A)
	local AtByA = multiply(At, A)
	local AtByb = multiply(At, b)
	return solve(AtByA, AtByb)
end

--

return Matrix
