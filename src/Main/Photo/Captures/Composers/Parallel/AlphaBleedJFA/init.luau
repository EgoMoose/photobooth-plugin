--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Parallel = require(pluginRoot.Utilities.Parallel)
local Image = require(pluginRoot.Utilities.Image)

type WorkerAction = typeof(require(script.Worker))

local scheduler = Parallel.new(1, {
	script = script.Worker,
	typecast = (nil :: any) :: WorkerAction,
})

local function alphaBleedJFA(img: Image.Image, nBleedPixels: number?)
	scheduler:WaitForReady()
	scheduler:Schedule(img.buffer, img.size, nBleedPixels)
	local packedResults = scheduler:Work()

	local result = Image.fromBuffer(packedResults[1](), img.size)
	result.templateUri = img.templateUri
	return result
end

return alphaBleedJFA
