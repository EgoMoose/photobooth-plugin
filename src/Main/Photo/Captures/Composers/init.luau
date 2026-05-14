--!strict

local serialFolder = script.Serial
local parallelFolder = script.Parallel

return {
	alphaBleed = require(parallelFolder.AlphaBleed),
	alphaBleedJFA = require(parallelFolder.AlphaBleedJFA),
	reverseBlend = require(parallelFolder.ReverseBlend),
	fullyOpaque = require(serialFolder.FullyOpaque),
}
