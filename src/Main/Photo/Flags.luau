--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Signal = require(pluginRoot.Packages.Signal)

local Flags = {}

-- Private

local flagsStorage = {}
local flagsChanged = Signal.new()

-- Public

function Flags.get(key: string)
	return not not flagsStorage[key]
end

function Flags.set(key: string, enabled: boolean)
	flagsStorage[key] = if enabled then true else nil
	flagsChanged:Fire()
end

function Flags.wrap<T...>(key: string, callback: () -> T...): T...
	Flags.set(key, true)
	local packed = table.pack(callback())
	Flags.set(key, false)
	return table.unpack(packed :: { any }, 1, packed.n)
end

function Flags.onChanged(callback: () -> ())
	local connection = flagsChanged:Connect(callback)
	return function()
		connection:Disconnect()
	end
end

--

return Flags
