--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local React = require(pluginRoot.Packages.React)
local Photo = require(pluginRoot.Main.Photo)

local function readFromPath<T>(path: { string }): T
	local pointer = Photo.State.read()
	for _, step in path do
		pointer = pointer[step]
	end
	return pointer :: any
end

local function useStatePath<T>(path: { string })
	local value, setValue = React.useState(readFromPath(path) :: T)

	React.useEffect(function()
		local strPath = table.concat(path, "/")
		Photo.State.onChanged(function(changedPath, newValue)
			if table.concat(changedPath, "/") == strPath then
				setValue(newValue)
			end
		end)
	end, {})

	return value
end

return useStatePath
