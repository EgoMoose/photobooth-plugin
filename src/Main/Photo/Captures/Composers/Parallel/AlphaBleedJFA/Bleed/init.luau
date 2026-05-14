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

	local imgSize = img.Size
	local imgWidth = imgSize.X

	for _, crop in regions do
		scheduler:schedule(img, voronoi, crop)
	end

	local stitched = img:ReadPixelsBuffer(Vector2.zero, imgSize)

	local bboxMinX = workingBbox.Min.X
	local results = scheduler:workAsync()
	for i, getCropBuffer in results do
		local cropBuffer = getCropBuffer()
		local crop = regions[i]
		local cropWidth = crop.Max.X - crop.Min.X
		local cropHeight = crop.Max.Y - crop.Min.Y
		local cropMinY = crop.Min.Y

		local rowBytes = cropWidth * 4
		for row = 0, cropHeight - 1 do
			local srcOffset = row * rowBytes
			local destOffset = ((cropMinY + row) * imgWidth + bboxMinX) * 4
			buffer.copy(stitched, destOffset, cropBuffer, srcOffset, rowBytes)
		end
	end

	return stitched
end

return bleed
