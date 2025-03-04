--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local gt = require(pluginRoot.Packages.GreenTea)

local Photo = require(pluginRoot.Main.Photo)

-- stylua: ignore
local typechecker = gt.fn(
	gt.args(),
	gt.returns(gt.Vector2())
)

local function callback()
	return Photo.Configuration.get().ScaleOS
end

return {
	identifier = "getOSScale",
	callback = gt.wrapFn(typechecker, callback),
}
