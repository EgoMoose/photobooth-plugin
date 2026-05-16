local pluginRoot = script:FindFirstAncestor("PluginRoot")
local StudioComponents = require(pluginRoot.Packages.StudioComponents)

local function usePlugin()
	return StudioComponents.usePlugin() :: Plugin?
end

return usePlugin
