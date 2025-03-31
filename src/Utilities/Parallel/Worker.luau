--!strict

return function(script: LuaSourceContainer)
	local actor = assert(script:GetActor(), "No actor found.")
	local moduleRef = assert(actor.Parent and actor.Parent.Parent, "No module found.")
	local binding = assert(moduleRef:FindFirstChild("Binding"), "Not binding instance found.")

	assert(moduleRef:IsA("ObjectValue"), "Not a ObjectValue.")
	assert(binding:IsA("BindableEvent"), "Not a BindableEvent.")

	local module = assert(moduleRef.Value, "No value in the ObjectValue.")
	assert(module:IsA("ModuleScript"), "ModuleRef Value is not a ModuleScript.")

	local workerAction = require(module) :: any
	actor:BindToMessageParallel("Work", function(index, ...)
		binding:Fire(index, workerAction(...))
	end)

	actor:SetAttribute("IsReady", true)
end
