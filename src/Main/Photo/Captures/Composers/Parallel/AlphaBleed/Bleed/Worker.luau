--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Timeout = require(pluginRoot.Utilities.Timeout)
local Image = require(pluginRoot.Utilities.Image)

local function workerAction(imgBuffer: buffer, imgSize: Vector2, visited: buffer, pending: { number })
	local img = Image.fromBuffer(imgBuffer, imgSize)

	while #pending > 0 do
		local pendingNext = {}

		for i = 1, #pending do
			local index = pending[i]

			local rgb = { 0, 0, 0 }
			local contributing = 0

			for _, neighborIndex in img:IterateNeighbors(index) do
				if bit32.band(buffer.readu8(visited, neighborIndex - 1), 0b10) > 0 then
					local r, g, b = img:GetRGBA255(neighborIndex)

					rgb[1] = rgb[1] + r
					rgb[2] = rgb[2] + g
					rgb[3] = rgb[3] + b

					contributing = contributing + 1
				elseif not (bit32.band(buffer.readu8(visited, neighborIndex - 1), 0b01) > 0) then
					buffer.writeu8(visited, neighborIndex - 1, 0b01)
					table.insert(pendingNext, neighborIndex)
				end

				Timeout.tryYield()
			end

			if contributing > 0 then
				img:SetRGBA255(index, rgb[1] / contributing, rgb[2] / contributing, rgb[3] / contributing, 0)
			end

			Timeout.tryYield()
		end

		for i = 1, #pending do
			buffer.writeu8(visited, pending[i] - 1, 0b11)
			Timeout.tryYield()
		end

		pending = pendingNext
	end

	return img.buffer
end

return workerAction
