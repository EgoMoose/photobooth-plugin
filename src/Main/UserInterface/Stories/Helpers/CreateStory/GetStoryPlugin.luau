--!nocheck
--!nolint UnknownGlobal

-- selene: allow(undefined_variable)
local plugin = PluginManager():CreatePlugin()
plugin.Name = "StoryPlugin"

return function()
	return plugin
end
