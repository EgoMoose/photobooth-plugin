--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local OrderedDictionary = require(pluginRoot.Packages.OrderedDictionary)

local Versions = require(script.Versions)

export type Configuration = Versions.Configuration

export type SerializedWrapped = {
	version: number,
	serialized: any,
}

local Configuration = {}

-- Private

local configurationCurrent = Versions.Current.default()

local configurationChanged = Instance.new("BindableEvent")
local configurationChangedInstantCallbacks = OrderedDictionary.new()
local function fireConfigurationChanged()
	configurationChanged:Fire()
	for callback, _ in configurationChangedInstantCallbacks:iterate() do
		task.spawn(callback)
	end
end

-- Public

function Configuration.get()
	return configurationCurrent
end

function Configuration.set(configuration: Configuration)
	configurationCurrent = table.freeze(table.clone(configuration))
	fireConfigurationChanged()
end

function Configuration.onChanged(callback: () -> ())
	local connection = configurationChanged.Event:Connect(callback)
	return function()
		connection:Disconnect()
	end
end

function Configuration.onChangedInstant(callback: () -> ())
	configurationChangedInstantCallbacks:set(callback, true)
	return function()
		configurationChangedInstantCallbacks:set(callback, nil)
	end
end

function Configuration.serialize(configuration: Configuration): SerializedWrapped
	return {
		version = Versions.Current.version,
		serialized = Versions.Current.serialize(configuration),
	}
end

function Configuration.deserialize(serializedWrapped: SerializedWrapped): Configuration
	local matchedVersion = Versions.ByVersion[serializedWrapped.version]
	assert(matchedVersion, "Unable to find a matching format version.")

	local serialized = serializedWrapped.serialized
	local migrationIndex = matchedVersion.index
	for i = migrationIndex + 1, #Versions.ByOrder do
		local versionFormat = Versions.ByOrder[i]
		serialized = versionFormat.migrate(serialized)
	end

	return Versions.Current.deserialize(serialized)
end

--

return Configuration
