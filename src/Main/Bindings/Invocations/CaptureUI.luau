--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local gt = require(pluginRoot.Packages.GreenTea)
local Sift = require(pluginRoot.Packages.Sift)

local Captures = require(pluginRoot.Main.Photo.Captures)
local Photo = require(pluginRoot.Main.Photo)

local captureTypeLiterals = Sift.Array.map(Captures.UserInterface.Order, function(value)
	return gt.literal(value)
end)

local gtOptions = gt.table({
	type = gt.union(unpack(captureTypeLiterals)),
	subject = gt.IsA.GuiObject(),
	delay = gt.opt(gt.number()),
	alphaBleed = gt.opt(gt.bool()),
})

-- stylua: ignore
local typechecker = gt.fn(
	gt.args(gtOptions),
	gt.returns(gt.opt(gt.IsA("MeshPart")))
)

local function callback(options: typeof(gtOptions))
	local result = Photo.captureUI(options)
	local exported = Photo.export(result, nil)
	return exported[1]
end

return {
	identifier = "captureUI",
	callback = gt.wrapFn(typechecker, callback),
}
