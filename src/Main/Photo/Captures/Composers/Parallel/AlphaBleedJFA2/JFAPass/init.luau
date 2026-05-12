--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Parallel = require(pluginRoot.Utilities.Parallel)
local Timeout = require(pluginRoot.Utilities.Timeout)

local Constants = require(pluginRoot.Constants)

type WorkerAction = typeof(require(script.Worker))

local scheduler = Parallel.new(Constants.JFAActorCount, {
	script = script.Worker,
	typecast = (nil :: any) :: WorkerAction,
})

local function firstPassJFA(img: EditableImage, voronoi: EditableImage, regions: { Rect }, nBleedPixels: number?)
	scheduler:WaitForReady()

	local imgSize = img.Size
	local imgWidth, imgHeight = imgSize.X, imgSize.Y

	local passSteps = {}
	local nextStep = if nBleedPixels
		then math.floor(2 ^ math.ceil(math.log(nBleedPixels, 2)))
		else math.floor(math.max(imgWidth, imgHeight) / 2)
	while nextStep >= 1 do
		table.insert(passSteps, nextStep)
		nextStep = math.floor(nextStep / 2)
	end

	if Constants.JFAPlusOne then
		table.insert(passSteps, 1)
	end

	local totalWork = 0
	local totalWrite = 0
	for _, step in passSteps do
		local results
		local workDt = Timeout.benchmark(function()
			for _, crop in regions do
				scheduler:Schedule(img, voronoi, crop, step)
			end

			results = scheduler:Work()
		end)
		totalWork = totalWork + workDt

		local writeDt = Timeout.benchmark(function()
			local offset = 0
			local stitched = buffer.create(imgWidth * imgHeight * 4)

			for i, getCropBuffer in results do
				local cropBuffer = getCropBuffer()
				buffer.copy(stitched, offset, cropBuffer)
				offset = offset + buffer.len(cropBuffer)
			end

			voronoi:WritePixelsBuffer(Vector2.zero, imgSize, stitched)
		end)
		totalWrite = totalWrite + writeDt
	end

	local total = totalWork + totalWrite
	print(total)
	print(totalWork, totalWork / total)
	print(totalWrite, totalWrite / total)
end

return firstPassJFA
