--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local React = require(pluginRoot.Packages.React)
local Photo = require(pluginRoot.Main.Photo)

local function useState()
	local value, setValue = React.useState(false)
	local stateRef = React.useRef(Photo.State.read())

	React.useEffect(function()
		local flipValue = value
		Photo.State.onChanged(function()
			flipValue = not flipValue
			setValue(flipValue)
		end)
	end, {})

	return stateRef.current
end

return useState
