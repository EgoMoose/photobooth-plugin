--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local gt = require(pluginRoot.Packages.GreenTea)

local SceneControl = require(pluginRoot.Main.Photo.SceneControl)

-- stylua: ignore
local typechecker = gt.fn(
	gt.args(),
	gt.returns()
)

local function callback()
	SceneControl.yieldUntilNextFrame()
end

return {
	identifier = "yieldUntilNextFrame",
	callback = gt.wrapFn(typechecker, callback),
}
