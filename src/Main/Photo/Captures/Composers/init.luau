--!strict

local serialFolder = script.Serial
local parallelFolder = script.Parallel

return {
	alphaBleedParallel = require(parallelFolder.AlphaBleed),
	alphaBleedSerial = require(serialFolder.AlphaBleed),
	reverseBlend = require(parallelFolder.ReverseBlend),
	fullyOpaque = require(serialFolder.FullyOpaque),
}
