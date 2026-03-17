--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local IntegralImage = require(pluginRoot.Utilities.IntegralImage)
local Timeout = require(pluginRoot.Utilities.Timeout)
local Image = require(pluginRoot.Utilities.Image)

local function workerAction(chunkBuffer: buffer, chunkSize: Vector2, crop: Rect, minIndex: number)
	local chunkImg = Image.fromBuffer(chunkBuffer, chunkSize)
	local alphaSignIntegralImg = IntegralImage.fromImage(chunkImg, function(u32)
		return math.sign(bit32.extract(u32, 24, 8))
	end)

	local pending = {}
	local visited = buffer.create(crop.Width * crop.Height)

	local fromIndex = chunkImg:GetPixelIndex(crop.Min.X + 1, crop.Min.Y + 1)
	local toIndex = chunkImg:GetPixelIndex(crop.Max.X, crop.Max.Y)

	for index = fromIndex, toIndex do
		Timeout.tryYield()

		local croppedOffset = index - fromIndex
		local _, _, _, alpha = chunkImg:GetRGBA255(index)

		if alpha ~= 0 then
			buffer.writeu8(visited, croppedOffset, 0b11)
			continue
		end

		local x, y = chunkImg:GetXYFromPixelIndex(index)
		if alphaSignIntegralImg:readRadius(x, y, 1) > 0 then
			table.insert(pending, minIndex + fromIndex - 1 + croppedOffset)
			buffer.writeu8(visited, croppedOffset, 0b01)
		end
	end

	return visited, pending
end

return workerAction
