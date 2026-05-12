--!strict
--!native
--!optimize 2

local function worker(img: EditableImage, voronoi: EditableImage, crop: Rect, step: number)
	local imgSize = img.Size
	local imgWidth, imgHeight = imgSize.X, imgSize.Y

	local cropSize = crop.Max - crop.Min
	local cropWidth, _cropHeight = cropSize.X, cropSize.Y
	local minX, maxX = crop.Min.X, crop.Max.X
	local minY, maxY = crop.Min.Y, crop.Max.Y

	local seedRead = voronoi:ReadPixelsBuffer(Vector2.zero, imgSize)
	local seedWrite = voronoi:ReadPixelsBuffer(crop.Min, cropSize)

	for y = minY + 1, maxY do
		for x = minX + 1, maxX do
			local i = x + (y - 1) * imgWidth
			local j = (i - 1) * 4

			local closestDistSq = math.huge
			local closestSeed = buffer.readu32(seedRead, j)
			if closestSeed > 0 then
				local sy = math.floor((closestSeed - 1) / imgWidth) + 1
				local sx = closestSeed - (sy - 1) * imgWidth
				closestDistSq = (sx - x) ^ 2 + (sy - y) ^ 2
			end

			for oy = -1, 1 do
				local ny = y + oy * step
				if ny < 1 or ny > imgHeight then
					continue
				end

				for ox = -1, 1 do
					if ox == 0 and oy == 0 then
						continue
					end

					local nx = x + ox * step
					if nx < 1 or nx > imgWidth then
						continue
					end

					local k = ((ny - 1) * imgWidth + nx - 1) * 4
					local nSeed = buffer.readu32(seedRead, k)

					if nSeed > 0 then
						local sny = math.floor((nSeed - 1) / imgWidth) + 1
						local snx = nSeed - (sny - 1) * imgWidth
						local distSq = (snx - x) ^ 2 + (sny - y) ^ 2

						if distSq < closestDistSq then
							closestDistSq = distSq
							closestSeed = nSeed
						end
					end
				end

				local cx = x - minX
				local cy = y - minY
				local ci = cx + (cy - 1) * cropWidth
				local cj = (ci - 1) * 4
				buffer.writeu32(seedWrite, cj, closestSeed)
			end
		end
	end

	return seedWrite
end

return worker
