--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Parallel = require(pluginRoot.Utilities.Parallel)
local Image = require(pluginRoot.Utilities.Image)

local HAS_VISITED = bit32.lshift(1, 0)
local CAN_SAMPLE = bit32.lshift(1, 1)
local BOTH = bit32.bor(HAS_VISITED, CAN_SAMPLE)

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

local function doWork(chunkBuffer: buffer, chunkSize: Vector2, fromIndex: number)
	local chunkImg = Image.fromBuffer(chunkBuffer, chunkSize)
	local readRadius = integralImgAlphaBuffer(chunkImg)

	local height = chunkImg.size.Y
	local width = chunkImg.size.X
	local visited = buffer.create(width * height)
	local pending = {}

	for y = 1, height do
		for x = 1, width do
			local index = chunkImg:GetPixelIndex(x, y)
			local _, _, _, alpha = chunkImg:GetRGBA255(index)

			if alpha ~= 0 then
				buffer.writeu8(visited, index - 1, BOTH)
				continue
			end

			if readRadius(x, y, 1) > 0 then
				table.insert(pending, index + fromIndex - 1)
				buffer.writeu8(visited, index - 1, HAS_VISITED)
			end
		end
	end

	return visited, pending
end

local required = {
	script = script,
	callback = doWork,
}

local function firstPass(img: Image.Image)
	local scheduler = Parallel.new(32, required)

	for i, chunk in img:Split(scheduler:GetActorCount()) do
		scheduler:Schedule(chunk.buffer, chunk.size, chunk.fromPixelIndex)
	end

	local packedResults = scheduler:WorkDeferred()
	scheduler:Destroy()

	local pending = {}
	local copyIndex = 0
	local visited = buffer.create(img:GetNumberOfPixels())
	for _, unpackResult in packedResults do
		local visitedStream, pendingStream = unpackResult()
		buffer.copy(visited, copyIndex, visitedStream)
		copyIndex = copyIndex + buffer.len(visitedStream)
		table.move(pendingStream, 1, #pendingStream, #pending + 1, pending)
	end

	return visited, pending
end

return Parallel.cast(required, firstPass)
