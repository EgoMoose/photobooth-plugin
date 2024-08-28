--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Trove = require(pluginRoot.Packages.Trove)

local photoRoot = script:FindFirstAncestor("Photo")
local BillboardBackground = require(photoRoot.Tools.BillboardBackground)
local Screenshot = require(photoRoot.Captures.Screenshot)

local function operation(rect: Rect, _billboardBackground: BillboardBackground.BillboardBackground, _trove: Trove.Trove)
	return Screenshot.rect(rect)
end

return operation
