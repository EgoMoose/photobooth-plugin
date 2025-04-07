--!strict

local ServerStorage = game:GetService("ServerStorage") :: ServerStorage

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Trove = require(pluginRoot.Packages.Trove)

local Photo = require(pluginRoot.Main.Photo)

local Bindings = {}
local trove = Trove.new()

-- Private

type Invocation = {
	identifier: string,
	callback: (...any) -> ...any,
}

local invocationByIdentifier = {}
for _, invocationModule in script.Invocations:GetDescendants() do
	if invocationModule:IsA("ModuleScript") then
		local invocation = require(invocationModule) :: Invocation
		assert(
			not invocationByIdentifier[invocation.identifier],
			`Duplicate invocation identifier: {invocation.identifier}`
		)
		invocationByIdentifier[invocation.identifier] = invocation
	end
end

local function createBindings()
	local interface = script.Interface:Clone()
	local binding = interface.Invoke.Binding
	interface.Name = "PhotoboothBindings"

	local descendants = interface:GetDescendants()
	table.insert(descendants, interface)

	for _, descendant in descendants do
		trove:Add(descendant)
		descendant.Archivable = false
	end

	binding.OnInvoke = function(identifier: string, ...: any)
		local results
		local packedArgs = table.pack(...)
		local success, err = pcall(function()
			local invocation = assert(invocationByIdentifier[identifier], `No invocation found for: {identifier}`)
			results = table.pack(invocation.callback(table.unpack(packedArgs)))
		end)

		if success then
			return true, table.unpack(results)
		end

		return false, err
	end

	return interface
end

local isEnabled = false
local function setEnabled(enabled: boolean)
	if isEnabled ~= enabled then
		isEnabled = enabled
		trove:Clean()

		if isEnabled then
			local interface = createBindings()
			interface.Parent = ServerStorage
		end
	end
end

-- Public

function Bindings.setup(plugin: Plugin)
	setEnabled(Photo.Configuration.get().BindingsEnabled)
	local disconnect = Photo.Configuration.onChanged(function()
		setEnabled(Photo.Configuration.get().BindingsEnabled)
	end)

	plugin.Unloading:Connect(function()
		disconnect()
		setEnabled(false)
	end)
end

--

return Bindings
