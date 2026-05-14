--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Parallel = require(pluginRoot.Packages.Parallel)
local Constants = require(pluginRoot.Constants)
local Image = require(pluginRoot.Utilities.Image)

type WorkerAction = typeof(require(script.Worker))

local scheduler = Parallel.new(Constants.JFAActorCount, {
	script = script.Worker,
	typecast = (nil :: any) :: WorkerAction,
})

local function bleed(img: EditableImage, voronoi: EditableImage, regions: { Rect }, workingBbox: Rect)
	scheduler:waitForReady()

	for _, crop in regions do
		scheduler:schedule(img, voronoi, crop)
	end

	local offset = 0
	local stitched = buffer.create(workingBbox.Width * workingBbox.Height * 4)

	local results = scheduler:workAsync()
	for i, getCropBuffer in results do
		local cropBuffer = getCropBuffer()
		buffer.copy(stitched, offset, cropBuffer)
		offset = offset + buffer.len(cropBuffer)
	end

	img:WritePixelsBuffer(workingBbox.Min, workingBbox.Max - workingBbox.Min, stitched)
end

return bleed
