--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Image = require(pluginRoot.Utilities.Image)

local function integralImgAlphaBuffer(img: Image.Image)
	local width = img:GetWidth()
	local height = img:GetHeight()
	local integralBuffer = buffer.create(width * height * 4)

	local function readImg(x: number, y: number)
		local i = img:GetPixelIndex(x, y)
		local _, _, _, a = img:GetRGBA255(i)
		return math.sign(a)
	end

	local function read(x: number, y: number)
		local i = ((x - 1) + (y - 1) * width) * 4
		return buffer.readu32(integralBuffer, i)
	end

	local function write(x: number, y: number, value: number)
		local i = ((x - 1) + (y - 1) * width) * 4
		buffer.writeu32(integralBuffer, i, value)
	end

	local function readClamped(x: number, y: number)
		local cx = math.min(x, width)
		local cy = math.min(y, height)
		if cx > 0 and cy > 0 then
			return read(cx, cy)
		end
		return 0
	end

	local function readRadius(x: number, y: number, radius: number)
		return readClamped(x + radius, y + radius)
			- readClamped(x - radius - 1, y + radius)
			- readClamped(x + radius, y - radius - 1)
			+ readClamped(x - radius - 1, y - radius - 1)
	end

	write(1, 1, readImg(1, 1))

	for x = 2, width do
		write(x, 1, readImg(x, 1) + read(x - 1, 1))
	end

	for y = 2, height do
		write(1, y, readImg(1, y) + read(1, y - 1))
	end

	for x = 2, width do
		for y = 2, height do
			write(x, y, readImg(x, y) + read(x, y - 1) + read(x - 1, y) - read(x - 1, y - 1))
		end
	end

	return readRadius
end

local HAS_VISITED = bit32.lshift(1, 0)
local CAN_SAMPLE = bit32.lshift(1, 1)
local BOTH = bit32.bor(HAS_VISITED, CAN_SAMPLE)

local function alphaBleedSerial(img: Image.Image)
	local copy = img:Clone()
	local width, height = copy.size.X, copy.size.Y

	local pending = {}
	local visited = buffer.create(width * height)

	local readRadius = integralImgAlphaBuffer(copy)

	for y = 1, height do
		for x = 1, width do
			local index = copy:GetPixelIndex(x, y)
			local _, _, _, alpha = copy:GetRGBA255(index)

			if alpha ~= 0 then
				buffer.writeu8(visited, index - 1, BOTH)
				continue
			end

			if readRadius(x, y, 1) > 0 then
				table.insert(pending, index)
				buffer.writeu8(visited, index - 1, HAS_VISITED)
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
				if bit32.band(buffer.readu8(visited, neighborIndex - 1), CAN_SAMPLE) > 0 then
					local r, g, b = copy:GetRGBA255(neighborIndex)

					rgb[1] = rgb[1] + r
					rgb[2] = rgb[2] + g
					rgb[3] = rgb[3] + b

					contributing = contributing + 1
				elseif not (bit32.band(buffer.readu8(visited, neighborIndex - 1), HAS_VISITED) > 0) then
					buffer.writeu8(visited, neighborIndex - 1, HAS_VISITED)
					table.insert(pendingNext, neighborIndex)
				end
			end

			if contributing > 0 then
				copy:SetRGBA255(index, rgb[1] / contributing, rgb[2] / contributing, rgb[3] / contributing, 0)
			end
		end

		for i = 1, #pending do
			buffer.writeu8(visited, pending[i] - 1, BOTH)
		end

		pending = pendingNext
	end

	return copy
end

return alphaBleedSerial
