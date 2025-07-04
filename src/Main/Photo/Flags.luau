--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Future = require(pluginRoot.Utilities.Future)

local Flags = {}

-- Private

local flagsStorage = {}
local flagsChanged = Instance.new("BindableEvent")

-- Public

function Flags.get(key: string)
	return not not flagsStorage[key]
end

function Flags.set(key: string, enabled: boolean)
	flagsStorage[key] = if enabled then true else nil
	flagsChanged:Fire()
end

function Flags.wrap<T...>(key: string, callback: () -> T...)
	Flags.set(key, true)
	local unpackResult = Future.packAsCallback(callback())
	Flags.set(key, false)
	return unpackResult()
end

function Flags.onChanged(callback: () -> ())
	local connection = flagsChanged.Event:Connect(callback)
	return function()
		connection:Disconnect()
	end
end

--

return Flags
