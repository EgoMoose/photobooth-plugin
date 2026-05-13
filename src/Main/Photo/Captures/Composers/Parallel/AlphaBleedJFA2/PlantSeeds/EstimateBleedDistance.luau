--!strict
--!native
--!optimize 2

-- Chebyshev distance transform: for each transparent pixel, computes max(|dx|, |dy|)
-- to its nearest opaque pixel. Returns the max over all transparent pixels — the
-- tightest sound `nBleedPixels` for JFA, since a JFA pass at step S can connect
-- pixels with Chebyshev distance up to 2*S - 1.
--
-- Two passes, O(width * height). Used as a fallback when the transparent bbox
-- touches an image edge and the cheaper bbox bound can't be used soundly.

local function estimateBleedDistance(img: EditableImage): number
	local imgSize = img.Size
	local w, h = imgSize.X, imgSize.Y
	local imgBuf = img:ReadPixelsBuffer(Vector2.zero, imgSize)
	local nPixels = w * h

	local INF = w + h
	local distBuf = buffer.create(nPixels * 4)

	for i = 0, nPixels - 1 do
		local j = i * 4
		if buffer.readu8(imgBuf, j + 3) > 0 then
			buffer.writeu32(distBuf, j, 0)
		else
			buffer.writeu32(distBuf, j, INF)
		end
	end

	local rowBytes = w * 4

	-- Forward pass: visits NW, N, NE, W neighbors (already finalized this pass).
	for y = 0, h - 1 do
		for x = 0, w - 1 do
			local j = (y * w + x) * 4
			local d = buffer.readu32(distBuf, j)
			if d == 0 then
				continue
			end

			local minN = d
			if y > 0 then
				local above = j - rowBytes
				local v = buffer.readu32(distBuf, above) + 1
				if v < minN then
					minN = v
				end
				if x > 0 then
					v = buffer.readu32(distBuf, above - 4) + 1
					if v < minN then
						minN = v
					end
				end
				if x < w - 1 then
					v = buffer.readu32(distBuf, above + 4) + 1
					if v < minN then
						minN = v
					end
				end
			end
			if x > 0 then
				local v = buffer.readu32(distBuf, j - 4) + 1
				if v < minN then
					minN = v
				end
			end

			if minN < d then
				buffer.writeu32(distBuf, j, minN)
			end
		end
	end

	-- Backward pass: visits SE, S, SW, E neighbors. Track maxD on the way out
	-- so we don't need a third pass over the buffer.
	local maxD = 0
	for y = h - 1, 0, -1 do
		for x = w - 1, 0, -1 do
			local j = (y * w + x) * 4
			local d = buffer.readu32(distBuf, j)
			if d == 0 then
				continue
			end

			local minN = d
			if y < h - 1 then
				local below = j + rowBytes
				local v = buffer.readu32(distBuf, below) + 1
				if v < minN then
					minN = v
				end
				if x > 0 then
					v = buffer.readu32(distBuf, below - 4) + 1
					if v < minN then
						minN = v
					end
				end
				if x < w - 1 then
					v = buffer.readu32(distBuf, below + 4) + 1
					if v < minN then
						minN = v
					end
				end
			end
			if x < w - 1 then
				local v = buffer.readu32(distBuf, j + 4) + 1
				if v < minN then
					minN = v
				end
			end

			if minN < d then
				buffer.writeu32(distBuf, j, minN)
				d = minN
			end

			if d < INF and d > maxD then
				maxD = d
			end
		end
	end

	return maxD
end

return estimateBleedDistance
