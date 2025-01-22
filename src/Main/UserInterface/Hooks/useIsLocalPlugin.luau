--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local StudioComponents = require(pluginRoot.Packages.StudioComponents)

local function useIsLocalPlugin()
	local plugin = StudioComponents.usePlugin() :: Plugin?
	local pluginName = plugin and plugin.Name

	if pluginName then
		return not not (
			pluginName:find(".rbxm$")
			or pluginName:find(".rbxmx$")
			or pluginName:find(".lua$")
			or pluginName:find(".luau$")
		)
	end

	return false
end

return useIsLocalPlugin
