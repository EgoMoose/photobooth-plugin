--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local gt = require(pluginRoot.Packages.GreenTea)

local Wally = require(pluginRoot.Wally)

-- stylua: ignore
local typechecker = gt.fn(
	gt.args(),
	gt.returns(gt.string())
)

local function callback()
	return Wally.package.version
end

return {
	identifier = "getVersion",
	callback = gt.wrapFn(typechecker, callback),
}
