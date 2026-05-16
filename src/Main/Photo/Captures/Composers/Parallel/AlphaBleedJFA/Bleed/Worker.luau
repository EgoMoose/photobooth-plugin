--!native
--!optimize 2

local function worker(img: EditableImage, voronoi: EditableImage, crop: Rect)
	local imgSize = img.Size
	local imgWidth = imgSize.X

	local cropSize = crop.Max - crop.Min
	local cropWidth, _cropHeight = cropSize.X, cropSize.Y
	local minX, maxX = crop.Min.X, crop.Max.X
	local minY, maxY = crop.Min.Y, crop.Max.Y

	local imgRead = img:ReadPixelsBuffer(Vector2.zero, imgSize)
	local cropWrite = img:ReadPixelsBuffer(crop.Min, cropSize)
	local voronoiRead = voronoi:ReadPixelsBuffer(crop.Min, cropSize)

	for y = minY + 1, maxY do
		for x = minX + 1, maxX do
			local i = x + (y - 1) * imgWidth
			local j = (i - 1) * 4

			local alpha = buffer.readu8(imgRead, j + 3)
			if alpha > 0 then
				continue
			end

			local ci = (x - minX) + (y - minY - 1) * cropWidth
			local cj = (ci - 1) * 4

			local seed = buffer.readu32(voronoiRead, cj)
			if seed == 0 then
				continue
			end

			local k = (seed - 1) * 4
			local r = buffer.readu8(imgRead, k + 0)
			local g = buffer.readu8(imgRead, k + 1)
			local b = buffer.readu8(imgRead, k + 2)

			buffer.writeu8(cropWrite, cj + 0, r)
			buffer.writeu8(cropWrite, cj + 1, g)
			buffer.writeu8(cropWrite, cj + 2, b)
		end
	end

	return cropWrite
end

return worker
