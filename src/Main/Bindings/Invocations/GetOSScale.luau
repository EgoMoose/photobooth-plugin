local pluginRoot = script:FindFirstAncestor("PluginRoot")
local gt = require(pluginRoot.Packages.GreenTea)

local State = require(pluginRoot.Main.State)

-- stylua: ignore
local typechecker = gt.fn(
	gt.args(),
	gt.returns(gt.Vector2())
)

local function callback()
	return State.read().temporary.scaleOS
end

return {
	identifier = "getOSScale",
	callback = gt.wrapFn(typechecker, callback),
}
