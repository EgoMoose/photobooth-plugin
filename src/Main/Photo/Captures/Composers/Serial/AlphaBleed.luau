--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Image = require(pluginRoot.Utilities.Image)
local Deque = require(pluginRoot.Packages.Deque)

local function alphaBleedSerial(img: Image.Image)
	local copy = img:Clone()
	local width, height = copy.size.X, copy.size.Y

	local visited = {}
	local canSample = {}
	local queue = Deque.raw({})

	for y = 1, height do
		for x = 1, width do
			local index = copy:GetPixelIndex(x, y)
			local _, _, _, a = copy:GetRGBA255(index)

			if a ~= 0 then
				visited[index] = true
				canSample[index] = true
				continue
			end

			local hasOpaqueNeighbor = false
			for _, neighborIndex in copy:GetNeighbors(index) do
				local _, _, _, na = copy:GetRGBA255(neighborIndex)
				if na ~= 0 then
					hasOpaqueNeighbor = true
					break
				end
			end

			if hasOpaqueNeighbor then
				visited[index] = true
				queue:pushBack(index)
			end
		end
	end

	while true do
		local length = queue:getLength()
		if length == 0 then
			break
		end

		for i = 1, length do
			local index = queue:getElement(i)

			local rgb = { 0, 0, 0 }
			local contributing = 0

			for _, neighborIndex in copy:GetNeighbors(index) do
				if canSample[neighborIndex] then
					local r, g, b = copy:GetRGBA255(neighborIndex)

					rgb[1] = rgb[1] + r
					rgb[2] = rgb[2] + g
					rgb[3] = rgb[3] + b

					contributing = contributing + 1
				elseif not visited[neighborIndex] then
					visited[neighborIndex] = true
					queue:pushBack(neighborIndex)
				end
			end

			if contributing > 0 then
				copy:SetRGBA255(index, rgb[1] / contributing, rgb[2] / contributing, rgb[3] / contributing, 0)
			end
		end

		for _ = 1, length do
			local poppedIndex = queue:popFront()
			canSample[poppedIndex] = true
		end
	end

	return copy
end

return alphaBleedSerial
