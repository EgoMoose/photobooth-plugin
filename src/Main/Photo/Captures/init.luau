--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Image = require(pluginRoot.Utilities.Image)
local Deque = require(pluginRoot.Packages.Deque)
local Sift = require(pluginRoot.Packages.Sift)

local TimeIt = require(pluginRoot.Utilities.TimeIt)

-- Private

local function _convertToWhite(img: Image.Image)
	local width, height = img.size.X, img.size.Y

	for y = 1, height do
		for x = 1, width do
			local index = img:GetPixelIndex(x, y)
			local _, _, _, a = img:GetRGBA(index)

			img:SetRGBA(index, 1, 1, 1, a)
		end
	end
end

local function _alphaBleedSerial(img: Image.Image, thickness: number)
	local width, height = img.size.X, img.size.Y

	local visited = {}
	local canSample = {}
	local queue = Deque.raw({})

	for y = 1, height do
		for x = 1, width do
			local index = img:GetPixelIndex(x, y)
			local _, _, _, a = img:GetRGBA255(index)

			if a ~= 0 then
				visited[index] = true
				canSample[index] = true
				continue
			end

			local hasOpaqueNeighbor = false
			for _, neighborIndex in img:GetNeighbors(index) do
				local _, _, _, na = img:GetRGBA255(neighborIndex)
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

	for _ = 1, thickness do
		local length = queue:getLength()
		if length == 0 then
			break
		end

		for i = 1, length do
			local index = queue:getElement(i)

			local rgb = { 0, 0, 0 }
			local contributing = 0

			for _, neighborIndex in img:GetNeighbors(index) do
				if canSample[neighborIndex] then
					local r, g, b = img:GetRGBA255(neighborIndex)

					rgb[1] = rgb[1] + r
					rgb[2] = rgb[2] + g
					rgb[3] = rgb[3] + b

					contributing = contributing + 1
				elseif not visited[neighborIndex] then
					visited[neighborIndex] = true
					queue:pushBack(neighborIndex)
				end
			end

			img:SetRGBA255(index, rgb[1] / contributing, rgb[2] / contributing, rgb[3] / contributing, 0)
		end

		for _ = 1, length do
			local poppedIndex = queue:popFront()
			canSample[poppedIndex] = true
		end
	end

	return img
end

local function alphaBleedParallel(img: Image.Image)
	-- this only bleeds 1 pixels which more efficient and easier to write in parallel
	local packedResults = img:Parallel(32, require(script.Parallel.AlphaBleed))

	local i = 0
	local newBuffer = buffer.create(img.size.X * img.size.Y * 4)
	for _, unpackResult in packedResults do
		local commitBuffer = unpackResult()
		buffer.copy(newBuffer, i, commitBuffer)
		i = i + buffer.len(commitBuffer)
	end

	local result = Image.fromBuffer(newBuffer, img.size)
	result.templateUri = img.templateUri
	return result
end

local ticket = 0
local ticketLookup = {}

local function wrap<T...>(callback: (T...) -> ...Image.Image)
	ticket = ticket + 1
	local myTicket = ticket

	local function wrapped(...: T...)
		local results = { callback(...) }
		local dt = TimeIt(function()
			for i, img in results do
				results[i] = alphaBleedParallel(img :: Image.Image)
			end
		end)
		print(dt)
		return results
	end

	ticketLookup[wrapped] = myTicket
	return wrapped
end

local function getOrder<T...>(exported: { [string]: (T...) -> { Image.Image } })
	local order = Sift.Dictionary.keys(exported)
	table.sort(order, function(a, b)
		return ticketLookup[exported[a]] < ticketLookup[exported[b]]
	end)
	return order
end

-- Public

export type UICaptureTypes = "NoBackground" | "AlphaMask"
export type ViewportCaptureTypes = "Unmodified" | "NoSkybox"

local captureTypes = {
	UserInterface = {
		NoBackground = wrap(require(script.UserInterface.ReverseBlend)),
		AlphaMask = wrap(require(script.UserInterface.AlphaMask)),
	},
	Viewport = {
		Unmodified = wrap(require(script.Viewport.Unmodified)),
		NoSkybox = wrap(require(script.Viewport.ReverseBlend)),

		-- FogAlpha = wrap(require(script.Viewport.FogAlpha)),
		-- ReverseBlend = wrap(require(script.Viewport.ReverseBlend)),
		-- LeastSquares = wrap(require(script.Viewport.LeastSquares)),
		-- ReverseBlendLeastSquares = wrap(require(script.Viewport.ReverseBlendLeastSquares)),
	},
}

return {
	UserInterface = {
		Default = "NoBackground" :: UICaptureTypes,
		Order = getOrder(captureTypes.UserInterface),
		Processors = captureTypes.UserInterface,
	},
	Viewport = {
		Default = "NoSkybox" :: ViewportCaptureTypes,
		Order = getOrder(captureTypes.Viewport),
		Processors = captureTypes.Viewport,
	},
}
