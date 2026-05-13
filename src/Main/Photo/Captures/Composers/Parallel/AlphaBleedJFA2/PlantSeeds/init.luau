--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Parallel = require(pluginRoot.Utilities.Parallel)
local Constants = require(pluginRoot.Constants)

local EstimateBleedDistance = require(script.Parent.EstimateBleedDistance)

type WorkerAction = typeof(require(script.Worker))

local scheduler = Parallel.new(Constants.JFAActorCount, {
	script = script.Worker,
	typecast = (nil :: any) :: WorkerAction,
})

local function plantSeeds(img: EditableImage, voronoi: EditableImage, regions: { Rect })
	scheduler:WaitForReady()

	local imgSize = img.Size
	local imgWidth, imgHeight = imgSize.X, imgSize.Y

	for _, crop in regions do
		scheduler:Schedule(img, voronoi, crop)
	end

	local offset = 0
	local minTX, maxTX = math.huge, -math.huge
	local minTY, maxTY = math.huge, -math.huge
	local stitched = buffer.create(imgWidth * imgHeight * 4)

	local results = scheduler:Work()
	for i, getCropBuffer in results do
		local cropBuffer, cMinX, cMaxX, cMinY, cMaxY = getCropBuffer()

		minTX = math.min(minTX, cMinX)
		maxTX = math.max(maxTX, cMaxX)
		minTY = math.min(minTY, cMinY)
		maxTY = math.max(maxTY, cMaxY)

		buffer.copy(stitched, offset, cropBuffer)
		offset = offset + buffer.len(cropBuffer)
	end

	voronoi:WritePixelsBuffer(Vector2.zero, imgSize, stitched)

	local nBleedPixels
	if minTX > maxTX then
		-- No transparent pixels — JFAPasses sees 0 and does nothing.
		nBleedPixels = 0
	elseif minTX > 1 and maxTX < imgWidth and minTY > 1 and maxTY < imgHeight then
		-- Transparent bbox is strictly inside the image, so opaque pixels are guaranteed
		-- to exist just outside each bbox edge — the bbox bound is sound and cheap.
		local bboxW = maxTX - minTX + 1
		local bboxH = maxTY - minTY + 1
		nBleedPixels = math.ceil(math.min(bboxW, bboxH) / 2)
	else
		-- Bbox touches an image edge (icon-on-transparent and similar). Fall back to
		-- a Chebyshev distance transform to get a tight, sound bound.
		local t = os.clock()
		nBleedPixels = EstimateBleedDistance(img)
		print(os.clock() - t)
		print(nBleedPixels)
	end

	return nBleedPixels
end

return plantSeeds
