--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local React = require(pluginRoot.Packages.React)
local Photo = require(pluginRoot.Main.Photo)

local function useState()
	local value, setValue = React.useState(Photo.State.read())

	React.useEffect(function() end, {})

	return value
end

return useState
