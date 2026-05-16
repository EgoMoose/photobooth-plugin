local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Parallel = require(pluginRoot.Packages.Parallel)

local Constants = require(pluginRoot.Constants)

type WorkerAction = typeof(require(script.Worker))

local function firstPassJFA(
	img: EditableImage,
	voronoi: EditableImage,
	regions: { Rect },
	workingBbox: Rect,
	nBleedPixels: number?
)
	local scheduler = Parallel.new(Constants.JFAActorCount, {
		script = script.Worker,
		typecast = (nil :: any) :: WorkerAction,
	})

	scheduler:waitForReady()

	local bboxSize = workingBbox.Max - workingBbox.Min
	local bboxWidth, bboxHeight = bboxSize.X, bboxSize.Y

	local maxBboxDim = math.max(bboxWidth, bboxHeight)
	local nextStep = math.min(
		if nBleedPixels then math.floor(2 ^ math.ceil(math.log(nBleedPixels, 2))) else math.huge,
		math.max(1, math.floor(maxBboxDim / 2))
	)

	local passSteps = {}
	while nextStep >= 1 do
		table.insert(passSteps, nextStep)
		nextStep = math.floor(nextStep / 2)
	end

	if #passSteps > 0 and Constants.JFAPlusOne then
		table.insert(passSteps, 1)
	end

	local stitched = buffer.create(bboxWidth * bboxHeight * 4)

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

		voronoi:WritePixelsBuffer(workingBbox.Min, bboxSize, stitched)
	end

	scheduler:Destroy()

	return #passSteps
end

return firstPassJFA
