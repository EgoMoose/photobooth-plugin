--!strict

local Bindings = {}
local binding = assert(script:FindFirstChild("Binding") :: BindableFunction?)

export type ViewportCaptureTypes = "Unmodified" | "NoSkybox"
export type UICaptureTypes = "NoBackground" | "AlphaMask"

Bindings.cancellable = require(script.Helpers.Cancellable)
Bindings.execute = require(script.Helpers.Execute)

function Bindings.getOSScale(): Vector2
	return binding:Invoke("getOSScale")
end

function Bindings.captureViewport(rect: Rect, captureType: ViewportCaptureTypes): MeshPart
	return binding:Invoke("captureViewport", rect, captureType)
end

function Bindings.captureUI(subject: GuiObject, captureType: UICaptureTypes): MeshPart
	return binding:Invoke("captureUI", subject, captureType)
end

function Bindings.yieldUntilNextFrame(): ()
	return binding:Invoke("yieldUntilNextFrame")
end

return Bindings
