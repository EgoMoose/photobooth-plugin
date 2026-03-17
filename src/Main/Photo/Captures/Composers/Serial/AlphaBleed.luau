--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local IntegralImage = require(pluginRoot.Utilities.IntegralImage)
local Timeout = require(pluginRoot.Utilities.Timeout)
local Image = require(pluginRoot.Utilities.Image)

local function alphaBleedSerial(img: Image.Image)
	local alphaSignIntegralImg = IntegralImage.fromImage(img, function(u32)
		return math.sign(bit32.extract(u32, 24, 8))
	end)

	local copy = img:Clone()
	local width, height = copy.size.X, copy.size.Y

	local pending = {}
	local visited = buffer.create(width * height)

	for y = 1, height do
		for x = 1, width do
			Timeout.tryYield()

			local index = copy:GetPixelIndex(x, y)
			local _, _, _, alpha = copy:GetRGBA255(index)

			if alpha ~= 0 then
				buffer.writeu8(visited, index - 1, 0b11)
				continue
			end

			if alphaSignIntegralImg:readRadius(x, y, 1) > 0 then
				table.insert(pending, index)
				buffer.writeu8(visited, index - 1, 0b01)
			end
		end
	end

	while #pending > 0 do
		local pendingNext = {}

		for i = 1, #pending do
			local index = pending[i]

			local rgb = { 0, 0, 0 }
			local contributing = 0

			for _, neighborIndex in copy:IterateNeighbors(index) do
				if bit32.band(buffer.readu8(visited, neighborIndex - 1), 0b10) > 0 then
					local r, g, b = copy:GetRGBA255(neighborIndex)

					rgb[1] = rgb[1] + r
					rgb[2] = rgb[2] + g
					rgb[3] = rgb[3] + b

					contributing = contributing + 1
				elseif not (bit32.band(buffer.readu8(visited, neighborIndex - 1), 0b01) > 0) then
					buffer.writeu8(visited, neighborIndex - 1, 0b01)
					table.insert(pendingNext, neighborIndex)
				end

				Timeout.tryYield()
			end

			if contributing > 0 then
				copy:SetRGBA255(index, rgb[1] / contributing, rgb[2] / contributing, rgb[3] / contributing, 0)
			end

			Timeout.tryYield()
		end

		for i = 1, #pending do
			buffer.writeu8(visited, pending[i] - 1, 0b11)
			Timeout.tryYield()
		end

		pending = pendingNext
	end

	return copy
end

return alphaBleedSerial
