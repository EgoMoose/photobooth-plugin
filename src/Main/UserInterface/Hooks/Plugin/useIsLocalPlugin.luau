--!strict

local usePlugin = require(script.Parent.usePlugin)

local function useIsLocalPlugin()
	local plugin = usePlugin()
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
