--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Image = require(pluginRoot.Utilities.Image)

local function doWork(serialized: Image.ParallelSerialized)
	local img = Image.fromBuffer(serialized.buffer, serialized.size)

	local nPixels = (serialized.toPixelIndex - serialized.fromPixelIndex) + 1
	local commitBuffer = buffer.create(nPixels * 4)
	buffer.copy(commitBuffer, 0, serialized.buffer, (serialized.fromPixelIndex - 1) * 4, nPixels * 4)

	for index = serialized.fromPixelIndex, serialized.toPixelIndex do
		local _, _, _, alpha = img:GetRGBA255(index)

		if alpha == 0 then
			local opaqueCount = 0
			local sr, sg, sb = 0, 0, 0
			for _, neighborIndex in img:GetNeighbors(index) do
				local nr, ng, nb, na = img:GetRGBA255(neighborIndex)
				if na > 0 then
					opaqueCount = opaqueCount + 1

					sr = sr + nr
					sg = sg + ng
					sb = sb + nb
				end
			end

			if opaqueCount > 0 then
				local j = (index - serialized.fromPixelIndex) * 4
				buffer.writeu8(commitBuffer, j + 0, sr / opaqueCount)
				buffer.writeu8(commitBuffer, j + 1, sg / opaqueCount)
				buffer.writeu8(commitBuffer, j + 2, sb / opaqueCount)
			end
		end
	end

	return commitBuffer
end

return {
	script = script,
	callback = doWork,
}
