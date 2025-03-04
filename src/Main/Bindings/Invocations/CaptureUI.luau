--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local gt = require(pluginRoot.Packages.GreenTea)
local Sift = require(pluginRoot.Packages.Sift)

local Captures = require(pluginRoot.Main.Photo.Captures)
local Photo = require(pluginRoot.Main.Photo)

local captureTypeLiterals = Sift.Array.map(Captures.UserInterface.Order, function(value)
	return gt.literal(value)
end)

-- stylua: ignore
local typechecker = gt.fn(
	gt.args(gt.IsA("GuiObject"), gt.union(unpack(captureTypeLiterals))),
	gt.returns(gt.IsA("MeshPart"))
)

local function callback(subject: GuiObject, captureType: Captures.UICaptureTypes)
	local result = Photo.captureUI(subject, captureType)
	local exported = Photo.export(result, nil)
	return exported[1]
end

return {
	identifier = "captureUI",
	callback = gt.wrapFn(typechecker, callback),
}
