--!strict

local serialFolder = script.Serial
local parallelFolder = script.Parallel

return {
	alphaBleed = require(serialFolder.AlphaBleed),
	reverseBlend = require(parallelFolder.ReverseBlend),
	fullyOpaque = require(serialFolder.FullyOpaque),
}
