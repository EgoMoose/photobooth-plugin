--!strict

return function(script: LuaSourceContainer)
	local actor = assert(script:GetActor(), "No actor found.")
	local binding = assert(actor:FindFirstChild("Binding"), "Not binding instance found.")
	assert(binding:IsA("BindableEvent"), "Not a BindableEvent.")

	local moduleRef = assert(actor:FindFirstAncestorWhichIsA("ObjectValue"), "No module found.")
	local module = assert(moduleRef.Value, "No value in the ObjectValue.")
	assert(module:IsA("ModuleScript"), "ModuleRef Value is not a ModuleScript.")

	local workerAction = require(module) :: any
	actor:BindToMessageParallel("Work", function(index, ...)
		binding:Fire(index, workerAction(...))
	end)

	actor:SetAttribute("IsReady", true)
end
