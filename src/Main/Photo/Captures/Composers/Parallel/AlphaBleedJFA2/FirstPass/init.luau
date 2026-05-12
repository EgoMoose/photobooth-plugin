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

	for _, crop in regions do
		scheduler:Schedule(img, voronoi, crop)
	end

	scheduler:Work()
end

return firstPassJFA
