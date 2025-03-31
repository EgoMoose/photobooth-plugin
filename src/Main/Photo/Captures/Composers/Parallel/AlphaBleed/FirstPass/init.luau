--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Parallel = require(pluginRoot.Utilities.Parallel)
local Image = require(pluginRoot.Utilities.Image)

type WorkerAction = typeof(require(script.Worker))

local scheduler = Parallel.new(32, {
	script = script.Worker,
	typecast = (nil :: any) :: WorkerAction,
})

local function parallelize(img: Image.Image)
	for _, chunk in img:Split(scheduler:GetActorCount(), 1) do
		scheduler:Schedule(chunk.buffer, chunk.size, chunk.crop, chunk.minIndex)
	end

	local packedResults = scheduler:Work()

	local pending = {}
	local copyIndex = 0
	local visited = buffer.create(img:GetNumberOfPixels())
	for _, unpackResult in packedResults do
		local visitedChunk, pendingChunk = unpackResult()
		buffer.copy(visited, copyIndex, visitedChunk)
		copyIndex = copyIndex + buffer.len(visitedChunk)
		table.move(pendingChunk, 1, #pendingChunk, #pending + 1, pending)
	end

	return visited, pending
end

return parallelize
