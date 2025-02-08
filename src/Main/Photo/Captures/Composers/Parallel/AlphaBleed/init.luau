--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Image = require(pluginRoot.Utilities.Image)

local FirstPass = require(script.FirstPass)
local Bleed = require(script.Bleed)

local function alphaBleedParallel(img: Image.Image)
	local visited, pending = FirstPass(img)
	local copy = Bleed(img, visited, pending)
	return copy
end

return alphaBleedParallel
