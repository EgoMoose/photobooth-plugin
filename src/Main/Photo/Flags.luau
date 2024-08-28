--!strict

local Flags = {}

-- Private

local flagsStorage = {}
local flagsChanged = Instance.new("BindableEvent")

local function packAsCallback<T...>(...: T...): () -> T...
	local n = select("#", ...)
	local packed = { select(1, ...) }
	return function()
		return unpack(packed, 1, n)
	end
end

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
	local unpackResult = packAsCallback(callback())
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
