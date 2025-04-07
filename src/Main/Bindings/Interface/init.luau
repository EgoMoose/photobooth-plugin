--!strict

local Invoke = require(script.Invoke)
local Cancellable = require(script.Helpers.Cancellable)

local Bindings = {}

export type ViewportCaptureTypes = "Unmodified" | "NoSkybox"
export type UICaptureTypes = "NoBackground" | "AlphaMask"

Bindings.cancellable = Cancellable.wrap
Bindings.execute = require(script.Helpers.Execute)

function Bindings.getVersion(): string
	return Cancellable.critical(2, function()
		return Invoke("getVersion")
	end)
end

function Bindings.getOSScale(): Vector2
	return Cancellable.critical(2, function()
		return Invoke("getOSScale")
	end)
end

function Bindings.captureViewport(rect: Rect, captureType: ViewportCaptureTypes): MeshPart
	return Cancellable.critical(2, function()
		return Invoke("captureViewport", rect, captureType)
	end)
end

function Bindings.captureUI(subject: GuiObject, captureType: UICaptureTypes): MeshPart
	return Cancellable.critical(2, function()
		return Invoke("captureUI", subject, captureType)
	end)
end

function Bindings.yieldUntilNextFrame(): ()
	return Cancellable.critical(2, function()
		return Invoke("yieldUntilNextFrame")
	end)
end

return Bindings
