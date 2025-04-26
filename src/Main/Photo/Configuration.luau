--!strict

local CapturesTypes = require(script.Parent.Captures.Types)

export type Configuration = {
	-- General
	ScaleOS: Vector2,
	AlphaBleedingEnabled: boolean,
	BindingsEnabled: boolean,
	ServePort: number,

	-- Viewport
	IsFullscreen: boolean,
	ViewportCaptureType: CapturesTypes.ViewportCaptureTypes,

	-- User Interface
	UserInterfaceCaptureType: CapturesTypes.UICaptureTypes,
}

local Configuration = {}

-- Private

local configurationChanged = Instance.new("BindableEvent")
local configurationCurrent: Configuration = {
	-- General
	ScaleOS = Vector2.new(1, 1),
	AlphaBleedingEnabled = true,
	BindingsEnabled = false,
	ServePort = -1,

	-- Viewport
	IsFullscreen = false,
	ViewportCaptureType = "NoSkybox",

	-- User Interface
	UserInterfaceCaptureType = "NoBackground",
}

-- Public

function Configuration.get()
	return configurationCurrent
end

function Configuration.set(configuration: Configuration)
	configurationCurrent = table.freeze(table.clone(configuration))
	configurationChanged:Fire()
end

function Configuration.onChanged(callback: () -> ())
	local connection = configurationChanged.Event:Connect(callback)
	return function()
		connection:Disconnect()
	end
end

--

return Configuration
