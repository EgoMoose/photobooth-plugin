local pluginRoot = script:FindFirstAncestor("PluginRoot")
local gt = require(pluginRoot.Packages.GreenTea)

local Photo = require(pluginRoot.Main.Photo)

-- stylua: ignore
local typechecker = gt.fn(
	gt.args(),
	gt.returns(gt.isA.MeshPart())
)

local function callback()
	return Photo.getQuadMeshPart()
end

return {
	identifier = "getMeshPart",
	callback = gt.wrapFn(typechecker, callback),
}
