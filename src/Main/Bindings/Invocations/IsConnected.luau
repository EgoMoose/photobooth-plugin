local pluginRoot = script:FindFirstAncestor("PluginRoot")
local gt = require(pluginRoot.Packages.GreenTea)

-- stylua: ignore
local typechecker = gt.fn(
	gt.args(),
	gt.returns(gt.boolean())
)

local function callback()
	return true
end

return {
	identifier = "isConnected",
	callback = gt.wrapFn(typechecker, callback),
}
