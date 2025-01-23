--!strict

local usePlugin = require(script.Parent.usePlugin)

local function useIsStoryPlugin()
	local plugin = usePlugin()
	return plugin and plugin.Name == "StoryPlugin"
end

return useIsStoryPlugin
