local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Image = require(pluginRoot.Utilities.Image)

local FirstPass = require(script.FirstPass)
local Bleed = require(script.Bleed)

local function alphaBleedParallel(img: Image.Image, nPixels: number?)
	local visited, pending = FirstPass(img)
	local copy = Bleed(img, visited, pending, nPixels)
	return copy
end

return alphaBleedParallel
