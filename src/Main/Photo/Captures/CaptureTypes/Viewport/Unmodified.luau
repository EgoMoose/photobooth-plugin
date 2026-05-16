local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Trove = require(pluginRoot.Packages.Trove)

local Types = require(pluginRoot.Main.Bindings.Interface.Types)

local photoRoot = script:FindFirstAncestor("Photo")
local Screenshot = require(photoRoot.Captures.Screenshot)
local SceneControl = require(photoRoot.SceneControl)

local function operation(options: Types.CaptureViewportOptions, trove: Trove.Trove)
	trove:Add(SceneControl.hideScreenUI())

	SceneControl.yieldUntilNextFrame()
	local capture = Screenshot.rect(options.rect)

	return capture
end

return operation
