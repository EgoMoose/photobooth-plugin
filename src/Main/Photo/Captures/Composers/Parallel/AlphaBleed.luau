--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Parallel = require(pluginRoot.Utilities.Parallel)
local Image = require(pluginRoot.Utilities.Image)

local function doWork(chunkBuffer: buffer, chunkSize: Vector2, crop: Rect)
	local chunkImg = Image.fromBuffer(chunkBuffer, chunkSize)
	local commitImg = chunkImg:Crop(crop)

	local fromIndex = chunkImg:GetPixelIndex(crop.Min.X + 1, crop.Min.Y + 1)
	local toIndex = chunkImg:GetPixelIndex(crop.Max.X, crop.Max.Y)

	for index = fromIndex, toIndex do
		local _, _, _, alpha = chunkImg:GetRGBA255(index)

		if alpha == 0 then
			local opaqueCount = 0
			local sr, sg, sb = 0, 0, 0
			for _, neighborIndex in chunkImg:GetNeighbors(index) do
				local nr, ng, nb, na = chunkImg:GetRGBA255(neighborIndex)
				if na > 0 then
					opaqueCount = opaqueCount + 1

					sr = sr + nr
					sg = sg + ng
					sb = sb + nb
				end
			end

			if opaqueCount > 0 then
				commitImg:SetRGBA255(index - fromIndex + 1, sr / opaqueCount, sg / opaqueCount, sb / opaqueCount, 0)
			end
		end
	end

	return commitImg.buffer
end

local required = {
	script = script,
	callback = doWork,
}

local function customImageSplit(img: Image.Image, n: number, yPadding: number)
	local width = img.size.X
	local height = img.size.Y
	local linesPerWorker = math.ceil(height / n)

	local chunks = {}
	for i = 1, n do
		local start = ((i - 1) * linesPerWorker) + 1
		local finish = math.min(height, (i * linesPerWorker))

		if start <= finish then
			local startPadded = math.max(1, start - yPadding)
			local finishPadded = math.min(height, finish + yPadding)

			local fromPixelIndex = img:GetPixelIndex(1, startPadded)
			local toPixelIndex = img:GetPixelIndex(width, finishPadded)

			local chunkLen = (toPixelIndex - fromPixelIndex + 1) * 4
			local chunkBuffer = buffer.create(chunkLen)
			local chunkSize = Vector2.new(width, (finishPadded - startPadded) + 1)
			buffer.copy(chunkBuffer, 0, img.buffer, (fromPixelIndex - 1) * 4, chunkLen)

			local cropMinY = start - startPadded
			local crop = Rect.new(0, cropMinY, width, cropMinY + finish - start + 1)

			table.insert(chunks, {
				crop = crop,
				buffer = chunkBuffer,
				size = chunkSize,
			})
		end
	end

	return chunks
end

local function alphaBleedParallel(img: Image.Image)
	local scheduler = Parallel.new(3, required)

	for i, chunk in customImageSplit(img, scheduler:GetActorCount(), 1) do
		scheduler:Schedule(chunk.buffer, chunk.size, chunk.crop)
	end

	local packedResults = scheduler:WorkDeferred()
	scheduler:Destroy()

	local copyIndex = 0
	local resultBuffer = buffer.create(img:GetNumberOfPixels() * 4)
	for _, unpackResult in packedResults do
		local commitBuffer = unpackResult()
		buffer.copy(resultBuffer, copyIndex, commitBuffer)
		copyIndex = copyIndex + buffer.len(commitBuffer)
	end

	local result = Image.fromBuffer(resultBuffer, img.size)
	result.templateUri = img.templateUri
	return result
end

return Parallel.cast(required, alphaBleedParallel)
