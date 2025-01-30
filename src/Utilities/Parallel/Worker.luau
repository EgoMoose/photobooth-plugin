--!strict

return function(script: LuaSourceContainer)
	local actor = assert(script:GetActor(), "No actor found.")
	local module = assert(actor.Parent and actor.Parent.Parent, "No module found.")
	local resultsBinding = assert(module:FindFirstChild("Results"), "Not Results instance found.")
	assert(resultsBinding:IsA("BindableEvent"), "Not a BindableEvent.")

	local required = require(module) :: any

	actor:BindToMessageParallel("Work", function(index, ...)
		resultsBinding:Fire(index, required.callback(...))
	end)
end
