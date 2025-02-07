--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Parallel = require(pluginRoot.Utilities.Parallel)
local Image = require(pluginRoot.Utilities.Image)
local Deque = require(pluginRoot.Packages.Deque)

local function doWork(buffer: buffer, size: Vector2) end

local required = {
	script = script,
	callback = doWork,
}

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

	return readRadius
end

local function alphaBleedParallel(img: Image.Image)
	local scheduler = Parallel.new(32, required)

	local readAlphaCountRadius = integralImgAlphaBuffer(img)

	local visited = {}
	local canSample = {}
	local queue = Deque.raw({})

	for y = 1, img:GetHeight() do
		for x = 1, img:GetWidth() do
			local pixelIndex = img:GetPixelIndex(x, y)
			local _, _, _, alpha = img:GetRGBA255(pixelIndex)

			if alpha ~= 0 then
				visited[pixelIndex] = true
				canSample[pixelIndex] = true
				continue
			end

			if readAlphaCountRadius(x, y, 1) > 0 then
				visited[pixelIndex] = true
				queue:pushBack(pixelIndex)
			end
		end
	end

	local packedResults = scheduler:WorkDeferred()

	return img
end

return Parallel.cast(required, alphaBleedParallel)
