--!strict

local HttpService = game:GetService("HttpService")

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local React = require(pluginRoot.Packages.React)

local usePlugin = require(script.Parent.usePlugin)
local useConstant = require(script.Parent.useConstant)

export type Props = {
	Title: string,
	Icon: string,

	Actions: {
		{
			Text: string,
			Icon: string,
			OnTriggered: () -> (),
		}
	},
}

local function usePluginMenu(props: Props)
	local plugin = assert(usePlugin())
	local unique = useConstant(function()
		return HttpService:GenerateGUID()
	end)

	local isOpen = React.useRef(false)
	local menu, setMenu = React.useState(nil :: PluginMenu?)
	React.useEffect(function()
		local pluginMenu = plugin:CreatePluginMenu(unique, props.Title, props.Icon)
		setMenu(pluginMenu)

		local actions = {}
		for i, actionInfo in props.Actions do
			local action = pluginMenu:AddNewAction(`{unique}_{i}`, actionInfo.Text, actionInfo.Icon)
			action.Triggered:Connect(actionInfo.OnTriggered)
			table.insert(actions, action)
		end

		return function()
			for _, action in actions do
				action:Destroy()
			end
			pluginMenu:Destroy()
		end
	end, { props })

	return function()
		if menu and not isOpen.current then
			isOpen.current = true
			menu:ShowAsync()
			isOpen.current = false
		end
	end
end

return usePluginMenu
