--!strict

local Bindings = {}
local binding = assert(script:FindFirstChild("Binding") :: BindableFunction?)

export type ViewportCaptureTypes = "Unmodified" | "NoSkybox"
export type UICaptureTypes = "NoBackground" | "AlphaMask"

local function invokeBinding<T..., U...>(identifier: string, ...: T...): U...
	local results = table.pack(binding:Invoke(identifier, ...))
	local success = table.unpack(results, 1, 1)
	if not success then
		error(table.unpack(results, 2, 2), 2)
	end
	return table.unpack(results, 2)
end

Bindings.cancellable = require(script.Helpers.Cancellable)
Bindings.execute = require(script.Helpers.Execute)

function Bindings.getVersion(): string
	return invokeBinding("getVersion")
end

function Bindings.getOSScale(): Vector2
	return invokeBinding("getOSScale")
end

function Bindings.captureViewport(rect: Rect, captureType: ViewportCaptureTypes): MeshPart
	return invokeBinding("captureViewport", rect, captureType)
end

function Bindings.captureUI(subject: GuiObject, captureType: UICaptureTypes): MeshPart
	return invokeBinding("captureUI", subject, captureType)
end

function Bindings.yieldUntilNextFrame(): ()
	return invokeBinding("yieldUntilNextFrame")
end

return Bindings
