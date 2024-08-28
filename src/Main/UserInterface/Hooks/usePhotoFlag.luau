--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local React = require(pluginRoot.Packages.React)
local Photo = require(pluginRoot.Main.Photo)

local function usePhotoFlag(key: string)
	local flag, setFlag = React.useState(Photo.Flags.get(key))

	React.useEffect(function()
		setFlag(Photo.Flags.get(key))
		return Photo.Flags.onChanged(function()
			setFlag(Photo.Flags.get(key))
		end)
	end)

	return flag
end

return usePhotoFlag
