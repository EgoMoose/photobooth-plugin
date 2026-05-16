local Types = require(script.Types)
local Wally = require(script.Wally)
local Binding = require(script.Binding)

local RenderRect = require(script.Helpers.RenderRect)
local Reversible = require(script.Helpers.Reversible)
local CachelessRequire = require(script.Helpers.CachelessRequire)

local Bindings = {}

export type UICaptureTypes = Types.UICaptureTypes
export type ViewportCaptureTypes = Types.ViewportCaptureTypes

export type CaptureViewportOptions = Types.CaptureViewportOptions
export type CaptureUIOptions = Types.CaptureUIOptions

-- Public

Bindings.rect = RenderRect
Bindings.reversible = Reversible.wrap

function Bindings.execute(script: LuaSourceContainer)
	assert(game:GetService("CoreGui"), "This should only be run in the command line.")
	return CachelessRequire.execute(script, {})
end

function Bindings.getVersion(): string
	return Binding.invoke("getVersion")
end

function Bindings.getPackageVersion(): string
	return assert(script:GetAttribute("PackageVersion") :: string?, "No package version attribute found.")
end

function Bindings.getOSScale(): Vector2
	return Binding.invoke("getOSScale")
end

function Bindings.yieldUntilNextFrame(): ()
	return Binding.invoke("yieldUntilNextFrame")
end

function Bindings.captureViewport(options: CaptureViewportOptions): MeshPart?
	return Binding.invoke("captureViewport", options)
end

function Bindings.captureUI(options: CaptureUIOptions): MeshPart?
	return Binding.invoke("captureUI", options)
end

function Bindings.isConnected(): boolean
	return Binding.isConnected()
end

function Bindings.isCompatible(): boolean
	local pkgVersion = Wally.package.version
	return Binding.invoke("compatibilityCheck", pkgVersion)
end

return Bindings
