--!strict

local Binding = {}
local bindable = assert(script:FindFirstChild("Bindable") :: BindableFunction?)

-- Private

local function isConnected()
	local pcallSuccess, invokeSuccess, result
	local thread = task.spawn(function()
		pcallSuccess = pcall(function()
			invokeSuccess, result = bindable:Invoke("isConnected")
		end)
	end)

	local value = false
	if coroutine.status(thread) == "dead" then
		local closeSuccess, _errorMessage = coroutine.close(thread)
		if closeSuccess and pcallSuccess and invokeSuccess then
			value = (result == true)
		end
	end

	return value
end

local function tryConnecting()
	if not isConnected() then
		local camera = game:GetService("CaptureService"):FindFirstChild("Photobooth") :: Camera?
		local connectBinding = camera and camera:FindFirstChild("ConnectBinding") :: BindableFunction?

		if connectBinding then
			connectBinding:Invoke(script.Parent)
		end
	end
end

-- Public

function Binding.isConnected()
	tryConnecting()
	return isConnected()
end

function Binding.invoke<T..., U...>(identifier: string, ...: T...): U...
	tryConnecting()

	local results = table.pack(bindable:Invoke(identifier, ...))
	local success = table.unpack(results, 1, 1)

	if not success then
		error(table.unpack(results, 2, 2), 2)
	end

	return table.unpack(results, 2)
end

return Binding
