local serialFolder = script.Serial
local parallelFolder = script.Parallel

return {
	alphaBleed = require(parallelFolder.AlphaBleed),
	reverseBlend = require(parallelFolder.ReverseBlend),
	fullyOpaque = require(serialFolder.FullyOpaque),
}
