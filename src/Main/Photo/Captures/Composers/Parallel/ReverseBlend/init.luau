--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Parallel = require(pluginRoot.Utilities.Parallel)
local Image = require(pluginRoot.Utilities.Image)

type WorkerAction = typeof(require(script.Worker))

local scheduler = Parallel.new(32, {
	script = script.Worker,
	typecast = (nil :: any) :: WorkerAction,
})

local function parallelize(
	onWhiteRetro: Image.Image,
	onBlackRetro: Image.Image,
	onBlack: Image.Image?,
	colorCorrection: ColorCorrectionEffect
)
	local splitOnWhiteRetro = onWhiteRetro:Split(scheduler:GetActorCount())
	local splitOnBlackRetro = onBlackRetro:Split(scheduler:GetActorCount())
	local splitOnBlack = if onBlack then onBlack:Split(scheduler:GetActorCount()) else {}

	for i = 1, #splitOnWhiteRetro do
		local onWhiteRetroChunk = splitOnWhiteRetro[i]
		local onBlackRetroChunk = splitOnBlackRetro[i]
		local onBlackChunk = splitOnBlack[i]

		scheduler:Schedule(
			onWhiteRetroChunk.size,
			colorCorrection,
			onWhiteRetroChunk.buffer,
			onBlackRetroChunk.buffer,
			if onBlackChunk then onBlackChunk.buffer else nil
		)
	end

	local packedResults = scheduler:Work()

	local copyIndex = 0
	local resultBuffer = buffer.create(onWhiteRetro:GetNumberOfPixels() * 4)
	for _, unpackResult in packedResults do
		local commitBuffer = unpackResult()
		buffer.copy(resultBuffer, copyIndex, commitBuffer)
		copyIndex = copyIndex + buffer.len(commitBuffer)
	end

	local result = Image.fromBuffer(resultBuffer, onWhiteRetro.size)
	result.templateUri = onWhiteRetro.templateUri
	return result
end

return parallelize
