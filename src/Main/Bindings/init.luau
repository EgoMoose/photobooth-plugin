--!strict

local CaptureService = game:GetService("CaptureService") :: CaptureService
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

local function connectBindings(plugin: Plugin, interface: Instance)
	local binding = interface:FindFirstChild("Binding") :: ModuleScript?
	local bindable = binding and binding:FindFirstChild("Bindable") :: BindableFunction?

	if bindable then
		bindable.OnInvoke = function(identifier: string, ...: any)
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

		plugin.Unloading:Connect(function()
			bindable.OnInvoke = function() end
		end)
	end
end

local function createBindings(plugin: Plugin)
	local interface = script.Interface:Clone()
	interface.Name = "Bindings"

	local descendants = interface:GetDescendants()
	table.insert(descendants, interface)

	for _, descendant in descendants do
		trove:Add(descendant)
	end

	connectBindings(plugin, interface)

	local camera = Instance.new("Camera")
	camera.Name = "Photobooth"
	camera.Archivable = false
	trove:Add(camera)

	interface.Parent = camera
	return camera
end

local isEnabled = false
local function setEnabled(plugin: Plugin, enabled: boolean)
	if isEnabled ~= enabled then
		isEnabled = enabled
		trove:Clean()

		if isEnabled then
			local interface = createBindings(plugin)
			interface.Parent = ServerStorage
		end
	end
end

-- Public

function Bindings.setup(plugin: Plugin)
	setEnabled(plugin, State.read().saved.bindingsEnabled)
	local disconnect = State.onChanged(function()
		setEnabled(plugin, State.read().saved.bindingsEnabled)
	end)

	local camera = Instance.new("Camera")
	camera.Name = "Photobooth"
	camera.Archivable = false
	camera.Parent = CaptureService

	local connectBinding = Instance.new("BindableFunction")
	connectBinding.Archivable = false
	connectBinding.Name = "ConnectBinding"
	connectBinding.OnInvoke = function(instance: Instance)
		if instance:HasTag("Photobooth_Bindings") then
			connectBindings(plugin, instance)
		end
	end
	connectBinding.Parent = camera

	plugin.Unloading:Connect(function()
		connectBinding:Destroy()
		camera:Destroy()
		disconnect()
		setEnabled(plugin, false)
	end)
end

--

return Bindings
