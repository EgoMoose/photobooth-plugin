--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local React = require(pluginRoot.Packages.React)
local State = require(pluginRoot.Main.Photo.State)

local function useStatePath<T>(readFromPath: (State.State) -> T)
	local value, setValue = React.useState(readFromPath(State.read()))

	React.useEffect(function()
		setValue(readFromPath(State.read()))
		return State.onChanged(function()
			setValue(readFromPath(State.read()))
		end)
	end, {})

	return value
end

return useStatePath
