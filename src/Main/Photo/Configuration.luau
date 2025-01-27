--!strict

local Captures = require(script.Parent.Captures)

export type Configuration = {
	-- General
	ScaleOS: Vector2,
	BindingsEnabled: boolean,

	-- Viewport
	ViewportCaptureType: Captures.ViewportCaptureTypes,

	-- User Interface
	UserInterfaceCaptureType: Captures.UICaptureTypes,
}

local Configuration = {}

-- Private

local configurationChanged = Instance.new("BindableEvent")
local configurationCurrent: Configuration = {
	-- General
	ScaleOS = Vector2.new(1, 1),
	BindingsEnabled = false,

	-- Viewport
	ViewportCaptureType = Captures.Viewport.Default,

	-- User Interface
	UserInterfaceCaptureType = Captures.UserInterface.Default,
}

-- Public

function Configuration.get()
	return table.clone(configurationCurrent)
end

function Configuration.set(configuration: Configuration)
	configurationCurrent = table.clone(configuration)
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
