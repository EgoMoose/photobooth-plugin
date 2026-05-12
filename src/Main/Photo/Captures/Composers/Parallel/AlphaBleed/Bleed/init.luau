--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Parallel = require(pluginRoot.Utilities.Parallel)
local Image = require(pluginRoot.Utilities.Image)

type WorkerAction = typeof(require(script.Worker))

local scheduler = Parallel.new(1, {
	script = script.Worker,
	typecast = (nil :: any) :: WorkerAction,
})

local function parallelize(img: Image.Image, visited: buffer, pending: { number }, nPixels: number?)
	-- not really taking advantage of parallel luau here
	-- however, by using a worker we stop studio from getting hung up

	scheduler:WaitForReady()
	scheduler:Schedule(img.buffer, img.size, visited, pending, nPixels or math.huge)
	local packedResults = scheduler:Work()

	local result = Image.fromBuffer(packedResults[1](), img.size)
	result.templateUri = img.templateUri
	return result
end

return parallelize
