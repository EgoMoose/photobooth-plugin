--!strict

local Types = require(script.Types)

local Reversible = require(script.Helpers.Reversible)
local CachelessRequire = require(script.Helpers.CachelessRequire)

local Bindings = {}
local binding = assert(script:FindFirstChild("Binding") :: BindableFunction?)

export type UICaptureTypes = Types.UICaptureTypes
export type ViewportCaptureTypes = Types.ViewportCaptureTypes

export type CaptureViewportOptions = Types.CaptureViewportOptions
export type CaptureUIOptions = Types.CaptureUIOptions

local function invokeBinding<T..., U...>(identifier: string, ...: T...): U...
	local results = table.pack(binding:Invoke(identifier, ...))
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

function Bindings.yieldUntilNextFrame(): ()
	return invokeBinding("yieldUntilNextFrame")
end

function Bindings.captureViewport(options: CaptureViewportOptions): MeshPart?
	return invokeBinding("captureViewport", options)
end

function Bindings.captureUI(options: CaptureUIOptions): MeshPart?
	return invokeBinding("captureUI", options)
end

return Bindings
