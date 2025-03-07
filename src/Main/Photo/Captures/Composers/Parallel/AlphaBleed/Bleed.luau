--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Parallel = require(pluginRoot.Utilities.Parallel)
local Image = require(pluginRoot.Utilities.Image)

local HAS_VISITED = bit32.lshift(1, 0)
local CAN_SAMPLE = bit32.lshift(1, 1)
local BOTH = bit32.bor(HAS_VISITED, CAN_SAMPLE)

local function doWork(imgBuffer: buffer, imgSize: Vector2, visited: buffer, pending: { number })
	local img = Image.fromBuffer(imgBuffer, imgSize)

	while #pending > 0 do
		local pendingNext = {}

		for i = 1, #pending do
			local index = pending[i]

			local rgb = { 0, 0, 0 }
			local contributing = 0

			for _, neighborIndex in img:GetNeighbors(index) do
				if bit32.band(buffer.readu8(visited, neighborIndex - 1), CAN_SAMPLE) > 0 then
					local r, g, b = img:GetRGBA255(neighborIndex)

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
				img:SetRGBA255(index, rgb[1] / contributing, rgb[2] / contributing, rgb[3] / contributing, 0)
			end
		end

		for i = 1, #pending do
			buffer.writeu8(visited, pending[i] - 1, BOTH)
		end

		pending = pendingNext
	end

	return img.buffer
end

local required = {
	script = script,
	callback = doWork,
}

local function bleed(img: Image.Image, visited: buffer, pending: { number })
	-- not really taking advantage of parallel luau here
	-- however, by using a worker we stop studio from getting hung up

	local scheduler = Parallel.cached(1, required)
	scheduler:Schedule(img.buffer, img.size, visited, pending)
	local packedResults = scheduler:Work()

	local result = Image.fromBuffer(packedResults[1](), img.size)
	result.templateUri = img.templateUri
	return result
end

return Parallel.cast(required, bleed)
