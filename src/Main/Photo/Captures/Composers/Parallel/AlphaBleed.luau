--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Parallel = require(pluginRoot.Utilities.Parallel)
local Image = require(pluginRoot.Utilities.Image)

local function doWork(chunkBuffer: buffer, chunkSize: Vector2)
	local chunkImg = Image.fromBuffer(chunkBuffer, chunkSize)
	local commitImg = chunkImg:Clone()

	for index = 1, chunkImg:GetNumberOfPixels() do
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
				commitImg:SetRGBA255(index, sr / opaqueCount, sg / opaqueCount, sb / opaqueCount, 0)
			end
		end
	end

	return commitImg.buffer
end

local required = {
	script = script,
	callback = doWork,
}

local function alphaBleedParallel(img: Image.Image)
	local scheduler = Parallel.new(32, required)

	for i, chunkImg in img:Split(scheduler:GetActorCount()) do
		scheduler:Schedule(chunkImg.buffer, chunkImg.size)
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
