--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local React = require(pluginRoot.Packages.React)
local Photo = require(pluginRoot.Main.Photo)

local currentConfiguration = Photo.Configuration.get()
Photo.Configuration.onChanged(function()
	currentConfiguration = Photo.Configuration.get()
end)

local function usePhotoConfiguration()
	local configuration, setConfiguration = React.useState(currentConfiguration)

	React.useEffect(function()
		setConfiguration(currentConfiguration)
		return Photo.Configuration.onChanged(function()
			setConfiguration(Photo.Configuration.get())
		end)
	end)

	return configuration, Photo.Configuration.set
end

return usePhotoConfiguration
