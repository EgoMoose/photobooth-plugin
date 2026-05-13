--!strict
--!native
--!optimize 2

local function worker(img: EditableImage, voronoi: EditableImage, crop: Rect)
	local imgSize = img.Size
	local imgWidth, _imgHeight = imgSize.X, imgSize.Y
	local imgBuffer = img:ReadPixelsBuffer(Vector2.zero, imgSize)

	local cropSize = crop.Max - crop.Min
	local cropWidth, cropHeight = cropSize.X, cropSize.Y
	local minX, maxX = crop.Min.X, crop.Max.X
	local minY, maxY = crop.Min.Y, crop.Max.Y

	local minTX, maxTX = math.huge, -math.huge
	local minTY, maxTY = math.huge, -math.huge
	local seedBuffer = buffer.create(cropWidth * cropHeight * 4)

	for y = minY + 1, maxY do
		for x = minX + 1, maxX do
			local i = x + (y - 1) * imgWidth
			local j = (i - 1) * 4

			local alpha = buffer.readu8(imgBuffer, j + 3)
			if alpha > 0 then
				local cx = x - minX
				local cy = y - minY
				local ci = cx + (cy - 1) * cropWidth
				local cj = (ci - 1) * 4

				buffer.writeu32(seedBuffer, cj, i)
			else
				minTX = math.min(minTX, x)
				maxTX = math.max(maxTX, x)
				minTY = math.min(minTY, y)
				maxTY = math.max(maxTY, y)
			end
		end
	end

	return seedBuffer, minTX, maxTX, minTY, maxTY
end

return worker
