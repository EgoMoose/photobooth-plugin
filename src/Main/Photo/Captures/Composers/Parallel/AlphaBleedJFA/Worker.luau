--!strict
--!native
--!optimize 2

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Timeout = require(pluginRoot.Utilities.Timeout)

-- Jump Flood Algorithm for alpha bleed.
--
-- Seed buffer encoding (u32 per pixel, same dimensions as the image):
--   0    => transparent pixel with no opaque source found (yet)
--   k>0  => 1-based pixelIndex of the nearest opaque pixel
--
-- Each pass reads from `seedRead`, writes the merged result into `seedWrite`,
-- then the two are swapped. Passes use step = maxDim/2, /4, ..., 1, plus one
-- extra step=1 pass at the end (the "JFA+1" refinement: corrects rare 1-pixel
-- seed-selection errors at certain Voronoi boundaries with one more pass over
-- the immediate 3x3 neighborhood).

local function workerAction(imgBuffer: buffer, imgSize: Vector2)
	local width = imgSize.X
	local height = imgSize.Y
	local pixelCount = width * height
	local maxDim = math.max(width, height)

	local seedRead = buffer.create(pixelCount * 4)
	local seedWrite = buffer.create(pixelCount * 4)

	-- Init: every opaque pixel is its own seed.
	for index = 1, pixelCount do
		local byteOffset = (index - 1) * 4
		local alpha = buffer.readu8(imgBuffer, byteOffset + 3)
		if alpha ~= 0 then
			buffer.writeu32(seedRead, byteOffset, index)
		end
	end
	Timeout.tryYield()

	-- Build the step schedule: maxDim/2, maxDim/4, ..., 1, then one more 1
	-- for the JFA+1 refinement pass.
	local passSteps = {}
	local nextStep = maxDim // 2
	while nextStep >= 1 do
		table.insert(passSteps, nextStep)
		nextStep = nextStep // 2
	end

	-- uncomment for JFA + 1
	-- table.insert(passSteps, 1)

	for _, step in passSteps do
		for y = 1, height do
			for x = 1, width do
				local pByteOffset = ((y - 1) * width + x - 1) * 4

				local bestSeed = buffer.readu32(seedRead, pByteOffset)
				local bestDist: number
				if bestSeed == 0 then
					bestDist = math.huge
				else
					local sy = (bestSeed - 1) // width + 1
					local sx = bestSeed - (sy - 1) * width
					local ddx = sx - x
					local ddy = sy - y
					bestDist = ddx * ddx + ddy * ddy
				end

				for dyMul = -1, 1 do
					local ny = y + dyMul * step
					if ny < 1 or ny > height then
						continue
					end
					for dxMul = -1, 1 do
						if dxMul == 0 and dyMul == 0 then
							continue
						end
						local nx = x + dxMul * step
						if nx < 1 or nx > width then
							continue
						end

						local nByteOffset = ((ny - 1) * width + nx - 1) * 4
						local nSeed = buffer.readu32(seedRead, nByteOffset)
						if nSeed == 0 then
							continue
						end

						local sy = (nSeed - 1) // width + 1
						local sx = nSeed - (sy - 1) * width
						local ddx = sx - x
						local ddy = sy - y
						local d = ddx * ddx + ddy * ddy
						if d < bestDist then
							bestDist = d
							bestSeed = nSeed
						end
					end
				end

				buffer.writeu32(seedWrite, pByteOffset, bestSeed)
			end
			Timeout.tryYield()
		end

		seedRead, seedWrite = seedWrite, seedRead
	end

	-- Compose: copy nearest-opaque RGB into each transparent pixel; keep alpha = 0.
	local resultBuffer = buffer.create(pixelCount * 4)
	buffer.copy(resultBuffer, 0, imgBuffer, 0)

	for index = 1, pixelCount do
		local byteOffset = (index - 1) * 4
		local alpha = buffer.readu8(imgBuffer, byteOffset + 3)
		if alpha ~= 0 then
			continue
		end

		local seed = buffer.readu32(seedRead, byteOffset)
		if seed == 0 then
			continue
		end

		local seedByteOffset = (seed - 1) * 4
		local r = buffer.readu8(imgBuffer, seedByteOffset + 0)
		local g = buffer.readu8(imgBuffer, seedByteOffset + 1)
		local b = buffer.readu8(imgBuffer, seedByteOffset + 2)

		buffer.writeu8(resultBuffer, byteOffset + 0, r)
		buffer.writeu8(resultBuffer, byteOffset + 1, g)
		buffer.writeu8(resultBuffer, byteOffset + 2, b)
		-- alpha left at 0 (copied from input via buffer.copy)
	end
	Timeout.tryYield()

	return resultBuffer
end

return workerAction
