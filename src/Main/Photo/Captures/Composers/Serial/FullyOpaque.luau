--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Timeout = require(pluginRoot.Utilities.Timeout)
local Image = require(pluginRoot.Utilities.Image)

local function fullyOpaque(img: Image.Image)
	local copy = img:Clone()
	local width, height = copy.size.X, copy.size.Y

	for y = 1, height do
		for x = 1, width do
			Timeout.tryYield()

			local index = copy:GetPixelIndex(x, y)
			local r, g, b = copy:GetRGBA255(index)

			copy:SetRGBA255(index, r, g, b, 255)
		end
	end

	return copy
end

return fullyOpaque
