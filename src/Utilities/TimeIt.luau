--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Future = require(pluginRoot.Packages.Future)

local function timeIt<T...>(callback: () -> T...)
	local t = os.clock()
	local unpackResult = Future.packAsCallback(callback())
	local dt = os.clock() - t
	return dt, unpackResult()
end

return timeIt
