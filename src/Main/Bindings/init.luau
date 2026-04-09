--!strict

local CollectionService = game:GetService("CollectionService") :: CollectionService
local ServerStorage = game:GetService("ServerStorage") :: ServerStorage

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Trove = require(pluginRoot.Packages.Trove)

local State = require(pluginRoot.Main.State)

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

local function connectBindings(interface: Instance)
	local binding = interface:FindFirstChild("Binding") :: BindableFunction?
	local connected = binding and binding:FindFirstChild("Connected") :: BoolValue?

	if binding and connected then
		connected.Value = true
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
	end
end

local function createBindings()
	local interface = script.Interface:Clone()
	interface.Name = "Bindings"

	local descendants = interface:GetDescendants()
	table.insert(descendants, interface)

	for _, descendant in descendants do
		trove:Add(descendant)
		descendant.Archivable = false
	end

	connectBindings(interface)

	local camera = Instance.new("Camera")
	camera.Name = "Photobooth"
	camera.Archivable = false
	trove:Add(camera)

	interface.Parent = camera
	return camera
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
	setEnabled(State.read().saved.bindingsEnabled)
	local disconnect = State.onChanged(function()
		setEnabled(State.read().saved.bindingsEnabled)
	end)

	for _, instance in CollectionService:GetTagged("Photobooth_Bindings_Package") do
		connectBindings(instance)
	end

	local tagAdded = CollectionService:GetInstanceAddedSignal("Photobooth_Bindings_Package"):Connect(function(instance)
		connectBindings(instance)
	end)

	plugin.Unloading:Connect(function()
		tagAdded:Disconnect()
		disconnect()
		setEnabled(false)
	end)
end

--

return Bindings
