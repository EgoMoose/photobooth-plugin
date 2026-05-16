local SelectionService = game:GetService("Selection") :: Selection

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local React = require(pluginRoot.Packages.React)

local function useSelection()
	local selection, setSelection = React.useState(SelectionService:Get())

	React.useEffect(function()
		setSelection(SelectionService:Get())
		local connection = SelectionService.SelectionChanged:Connect(function()
			setSelection(SelectionService:Get())
		end)

		return function()
			connection:Disconnect()
		end
	end, {})

	return selection
end

return useSelection
