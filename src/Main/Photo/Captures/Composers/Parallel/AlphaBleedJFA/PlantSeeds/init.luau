--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Parallel = require(pluginRoot.Packages.Parallel)
local Constants = require(pluginRoot.Constants)

type WorkerAction = typeof(require(script.Worker))

local function plantSeeds(img: EditableImage, voronoi: EditableImage, regions: { Rect }): Rect?
	local scheduler = Parallel.new(Constants.JFAActorCount, {
		script = script.Worker,
		typecast = (nil :: any) :: WorkerAction,
	})

	scheduler:waitForReady()

	local imgSize = img.Size
	local imgWidth, imgHeight = imgSize.X, imgSize.Y

	for _, crop in regions do
		scheduler:schedule(img, voronoi, crop)
	end

	local offset = 0
	local stitched = buffer.create(imgWidth * imgHeight * 4)

	local hasOpaque = false
	local tXMin, tYMin = math.huge, math.huge
	local tXMax, tYMax = -math.huge, -math.huge

	local results = scheduler:workAsync()
	scheduler:Destroy()

	for i, getCropBuffer in results do
		local cropBuffer, chunkHasOpaque, cXMin, cYMin, cXMax, cYMax = getCropBuffer()
		buffer.copy(stitched, offset, cropBuffer)
		offset = offset + buffer.len(cropBuffer)

		hasOpaque = hasOpaque or chunkHasOpaque

		tXMin = math.min(tXMin, cXMin)
		tXMax = math.max(tXMax, cXMax)
		tYMin = math.min(tYMin, cYMin)
		tYMax = math.max(tYMax, cYMax)
	end

	voronoi:WritePixelsBuffer(Vector2.zero, imgSize, stitched)

	if not hasOpaque or tXMin == math.huge then
		return nil
	end

	return Rect.new(tXMin - 1, tYMin - 1, tXMax, tYMax)
end

return plantSeeds
