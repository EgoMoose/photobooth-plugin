--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
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

return {
	script = script,
	callback = doWork,
}
