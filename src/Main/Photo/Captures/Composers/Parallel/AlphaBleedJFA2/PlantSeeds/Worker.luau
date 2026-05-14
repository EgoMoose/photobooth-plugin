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

	local seedBuffer = buffer.create(cropWidth * cropHeight * 4)

	local hasOpaque = false
	local tXMin, tYMin = math.huge, math.huge
	local tXMax, tYMax = -math.huge, -math.huge

	for y = minY + 1, maxY do
		for x = minX + 1, maxX do
			local i = x + (y - 1) * imgWidth
			local j = (i - 1) * 4

			local alpha = buffer.readu8(imgBuffer, j + 3)
			if alpha > 0 then
				hasOpaque = true

				local cx = x - minX
				local cy = y - minY
				local ci = cx + (cy - 1) * cropWidth
				local cj = (ci - 1) * 4

				buffer.writeu32(seedBuffer, cj, i)
			else
				tXMin = math.min(tXMin, x)
				tXMax = math.max(tXMax, x)
				tYMin = math.min(tYMin, y)
				tYMax = math.max(tYMax, y)
			end
		end
	end

	return seedBuffer, hasOpaque, tXMin, tYMin, tXMax, tYMax
end

return worker
