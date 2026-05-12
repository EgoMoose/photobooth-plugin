--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Parallel = require(pluginRoot.Utilities.Parallel)
local Constants = require(pluginRoot.Constants)

type WorkerAction = typeof(require(script.Worker))

local scheduler = Parallel.new(Constants.JFAActorCount, {
	script = script.Worker,
	typecast = (nil :: any) :: WorkerAction,
})

local function firstPassJFA(img: EditableImage, voronoi: EditableImage, regions: { Rect })
	scheduler:WaitForReady()

	local imgSize = img.Size
	local imgWidth, imgHeight = imgSize.X, imgSize.Y

	for _, crop in regions do
		scheduler:Schedule(img, voronoi, crop)
	end

	local offset = 0
	local stitched = buffer.create(imgWidth * imgHeight * 4)

	local results = scheduler:Work()
	for i, getCropBuffer in results do
		local cropBuffer = getCropBuffer()
		buffer.copy(stitched, offset, cropBuffer)
		offset = offset + buffer.len(cropBuffer)
	end

	voronoi:WritePixelsBuffer(Vector2.zero, imgSize, stitched)
end

return firstPassJFA
