--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Parallel = require(pluginRoot.Utilities.Parallel)
local Constants = require(pluginRoot.Constants)

type WorkerAction = typeof(require(script.Worker))

local scheduler = Parallel.new(Constants.JFAActorCount, {
	script = script.Worker,
	typecast = (nil :: any) :: WorkerAction,
})

local function firstPassJFA(img: EditableImage, voronoi: EditableImage, regions: { Rect }, nBleedPixels: number?)
	scheduler:WaitForReady()

	local imgSize = img.Size

	local passSteps = {}
	local nextStep = if nBleedPixels
		then math.floor(2 ^ math.ceil(math.log(nBleedPixels, 2)))
		else math.floor(math.max(imgSize.X, imgSize.Y) / 2)
	while nextStep >= 1 do
		table.insert(passSteps, nextStep)
		nextStep = math.floor(nextStep / 2)
	end

	if Constants.JFAPlusOne then
		table.insert(passSteps, 1)
	end

	for _, step in passSteps do
		for _, crop in regions do
			scheduler:Schedule(img, voronoi, crop, step)
		end
		scheduler:Work()
	end
end

return firstPassJFA
