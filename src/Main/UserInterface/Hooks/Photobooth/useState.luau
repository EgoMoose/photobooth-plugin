--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local React = require(pluginRoot.Packages.React)
local State = require(pluginRoot.Main.State)

local function useState()
	local value, setValue = React.useState(false)
	local stateRef = React.useRef(State.read())

	React.useEffect(function()
		local flipValue = not value
		setValue(flipValue)
		State.onChanged(function()
			flipValue = not flipValue
			setValue(flipValue)
		end)
	end, {})

	return stateRef.current
end

return useState
