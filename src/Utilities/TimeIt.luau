--!strict

local function packAsCallback<T...>(...: T...): () -> T...
	local n = select("#", ...)
	local packed = { select(1, ...) }
	return function()
		return unpack(packed, 1, n)
	end
end

local function timeIt<T...>(callback: () -> T...)
	local t = os.clock()
	local unpackResult = packAsCallback(callback())
	local dt = os.clock() - t
	return dt, unpackResult()
end

return timeIt
