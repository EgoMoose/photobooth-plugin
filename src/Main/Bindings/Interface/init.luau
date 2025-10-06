--!strict

local Types = require(script.Types)

local Reversible = require(script.Helpers.Reversible)
local CachelessRequire = require(script.Helpers.CachelessRequire)

local Bindings = {}
local binding = assert(script:FindFirstChild("Binding") :: BindableFunction?)

export type ViewportCaptureTypes = Types.ViewportCaptureTypes
export type UICaptureTypes = Types.UICaptureTypes

local function invokeBinding<T..., U...>(identifier: string, ...: T...): U...
	local results
	local args = table.pack(...)
	Reversible.critical(3, function()
		results = table.pack(binding:Invoke(identifier, table.unpack(args)))
	end)

	local success = table.unpack(results, 1, 1)
	if not success then
		error(table.unpack(results, 2, 2), 2)
	end

	return table.unpack(results, 2)
end

Bindings.reversible = Reversible.wrap

function Bindings.execute(script: LuaSourceContainer)
	assert(game:GetService("CoreGui"), "This should only be run in the command line.")
	return CachelessRequire.execute(script, {})
end

function Bindings.getVersion(): string
	return invokeBinding("getVersion")
end

function Bindings.getOSScale(): Vector2
	return invokeBinding("getOSScale")
end

function Bindings.captureViewport(rect: Rect, captureType: ViewportCaptureTypes): MeshPart
	return invokeBinding("captureViewport", rect, captureType)
end

function Bindings.captureUI(subject: GuiObject, captureType: UICaptureTypes, captureDelay: number?): MeshPart
	return invokeBinding("captureUI", subject, captureType, captureDelay)
end

function Bindings.yieldUntilNextFrame(): ()
	return invokeBinding("yieldUntilNextFrame")
end

return Bindings
