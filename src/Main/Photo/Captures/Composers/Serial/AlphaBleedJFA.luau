--!strict
--!native
--!optimize 2

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Timeout = require(pluginRoot.Utilities.Timeout)
local Image = require(pluginRoot.Utilities.Image)

local Constants = require(pluginRoot.Constants)

local function alphaBleedJFASerial(img: Image.Image)
	local imgBuffer = img.buffer
	local imgSize = img.size

	local width, height = imgSize.X, imgSize.Y
	local nPixels = width * height

	local seedRead = buffer.create(nPixels * 4)
	local seedWrite = buffer.create(nPixels * 4)

	for i = 1, nPixels do
		local j = (i - 1) * 4
		local alpha = buffer.readu8(imgBuffer, j + 3)
		if alpha ~= 0 then
			-- every opaque pixel is its own seed
			buffer.writeu32(seedRead, j + 0, i)
		end
	end
	Timeout.tryYield()

	local passSteps = {}
	local nextStep = math.floor(math.max(width, height) / 2)
	while nextStep >= 1 do
		table.insert(passSteps, nextStep)
		nextStep = math.floor(nextStep / 2)
	end

	if Constants.JFAPlusOne then
		table.insert(passSteps, 1)
	end

	for _, step in passSteps do
		for y = 1, height do
			for x = 1, width do
				local j = ((y - 1) * width + x - 1) * 4

				local closestDistSq = math.huge
				local closestSeed = buffer.readu32(seedRead, j)
				if closestSeed > 0 then
					local sy = math.floor((closestSeed - 1) / width) + 1
					local sx = closestSeed - (sy - 1) * width
					closestDistSq = (sx - x) ^ 2 + (sy - y) ^ 2
				end

				for oy = -1, 1 do
					local ny = y + oy * step
					if ny < 1 or ny > height then
						continue
					end

					for ox = -1, 1 do
						if ox == 0 and oy == 0 then
							continue
						end

						local nx = x + ox * step
						if nx < 1 or nx > width then
							continue
						end

						local k = ((ny - 1) * width + nx - 1) * 4
						local nSeed = buffer.readu32(seedRead, k)

						if nSeed > 0 then
							local sny = math.floor((nSeed - 1) / width) + 1
							local snx = nSeed - (sny - 1) * width
							local distSq = (snx - x) ^ 2 + (sny - y) ^ 2

							if distSq < closestDistSq then
								closestDistSq = distSq
								closestSeed = nSeed
							end
						end
					end
				end

				buffer.writeu32(seedWrite, j, closestSeed)
			end
			Timeout.tryYield()
		end

		seedRead, seedWrite = seedWrite, seedRead
	end

	local jfaImg = img:Clone()
	local jfaBuffer = jfaImg.buffer

	for i = 1, nPixels do
		local j = (i - 1) * 4

		local alpha = buffer.readu8(imgBuffer, j + 3)
		if alpha > 0 then
			continue
		end

		local seed = buffer.readu32(seedRead, j)
		if seed == 0 then
			continue
		end

		local k = (seed - 1) * 4
		local r = buffer.readu8(imgBuffer, k + 0)
		local g = buffer.readu8(imgBuffer, k + 1)
		local b = buffer.readu8(imgBuffer, k + 2)

		buffer.writeu8(jfaBuffer, j + 0, r)
		buffer.writeu8(jfaBuffer, j + 1, g)
		buffer.writeu8(jfaBuffer, j + 2, b)
	end

	Timeout.tryYield()

	return jfaImg
end

return alphaBleedJFASerial
