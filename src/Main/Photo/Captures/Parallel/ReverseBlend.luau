--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Image = require(pluginRoot.Utilities.Image)

local COMPARE_MARGIN = 0

local Wb = { 255, 255, 255, 255 }
local Bb = { 0, 0, 0, 255 }

local function compareByMargin(a: { number }, b: { number }, margin: number): boolean
	-- stylua: ignore
	return (
			math.abs(a[1] - b[1]) <= margin 
		and math.abs(a[2] - b[2]) <= margin
		and math.abs(a[3] - b[3]) <= margin
	)
end

local function doWork(serialized: Image.ParallelSerialized, blackRetroBuffer: buffer, blackBuffer: buffer?)
	local onWhiteRetro = Image.fromBuffer(serialized.buffer, serialized.size)
	local onBlackRetro = Image.fromBuffer(blackRetroBuffer, serialized.size)
	local onBlack = Image.fromBuffer(blackBuffer or blackRetroBuffer, serialized.size)

	return onBlack.buffer
end

return {
	script = script,
	callback = doWork,
}
