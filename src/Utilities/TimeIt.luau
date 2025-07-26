--!strict

local function timeIt<T...>(callback: () -> T...): (number, T...)
	local t = os.clock()
	local packed = table.pack(callback())
	local dt = os.clock() - t
	return dt, table.unpack(packed :: { any }, 1, packed.n)
end

return timeIt
