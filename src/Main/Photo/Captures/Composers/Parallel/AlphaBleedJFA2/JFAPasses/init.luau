--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Parallel = require(pluginRoot.Packages.Parallel)

local Constants = require(pluginRoot.Constants)

type WorkerAction = typeof(require(script.Worker))

local scheduler = Parallel.new(Constants.JFAActorCount, {
	script = script.Worker,
	typecast = (nil :: any) :: WorkerAction,
})

local function firstPassJFA(img: EditableImage, voronoi: EditableImage, regions: { Rect }, nBleedPixels: number?)
	scheduler:waitForReady()

	local imgSize = img.Size
	local imgWidth, imgHeight = imgSize.X, imgSize.Y

	local nextStep = math.min(
		if nBleedPixels then math.floor(2 ^ math.ceil(math.log(nBleedPixels, 2))) else math.huge,
		math.floor(math.max(imgWidth, imgHeight) / 2)
	)

	local passSteps = {}
	while nextStep >= 1 do
		table.insert(passSteps, nextStep)
		nextStep = math.floor(nextStep / 2)
	end

	if #passSteps > 0 and Constants.JFAPlusOne then
		table.insert(passSteps, 1)
	end

	local stitched = buffer.create(imgWidth * imgHeight * 4)

	for _, step in passSteps do
		for _, crop in regions do
			scheduler:schedule(img, voronoi, crop, step)
		end

		local offset = 0
		local results = scheduler:workAsync()
		for i, getCropBuffer in results do
			local cropBuffer = getCropBuffer()
			buffer.copy(stitched, offset, cropBuffer)
			offset = offset + buffer.len(cropBuffer)
		end

		voronoi:WritePixelsBuffer(Vector2.zero, imgSize, stitched)
	end

	return #passSteps
end

return firstPassJFA
