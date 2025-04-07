--!strict

local binding = assert(script:FindFirstChild("Binding") :: BindableFunction?)

local function invokeBinding<T..., U...>(identifier: string, ...: T...): U...
	local results = table.pack(binding:Invoke(identifier, ...))
	local success = table.unpack(results, 1, 1)
	if not success then
		error(table.unpack(results, 2, 2), 2)
	end
	return table.unpack(results, 2)
end

return invokeBinding
