--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local React = require(pluginRoot.Packages.React)

local useSelection = require(script.Parent.useSelection)
local useEditableImage = require(script.Parent.useEditableImage)

local DEFAULT_NAME = "UNKNOWN_NAME"

local function useSelectedEditableImage()
	local selection = useSelection()
	local singleSelection = if #selection == 1 then selection[1] else nil
	local name, setName = React.useState(if singleSelection then singleSelection.Name else nil)

	React.useEffect(function()
		local connection: RBXScriptConnection?
		if singleSelection then
			setName(singleSelection.Name)
			connection = singleSelection:GetPropertyChangedSignal("Name"):Connect(function()
				setName(singleSelection.Name)
			end)
		end

		return function()
			if connection then
				connection:Disconnect()
				connection = nil
			end
		end
	end, { singleSelection })

	return useEditableImage(singleSelection), name or DEFAULT_NAME
end

return useSelectedEditableImage
