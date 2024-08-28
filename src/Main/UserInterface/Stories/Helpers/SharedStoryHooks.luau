--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local React = require(pluginRoot.Packages.React)

local SharedStoryHooks = {}

function SharedStoryHooks.useAttribute<T>(instance: Instance, attributeName: string, default: T): T
	local attribute, setAttribute = React.useState(instance:GetAttribute(attributeName) or default)

	React.useEffect(function()
		setAttribute(instance:GetAttribute(attributeName) or default)
		local connection = instance:GetAttributeChangedSignal(attributeName):Connect(function()
			setAttribute(instance:GetAttribute(attributeName) or default)
		end)

		return function()
			connection:Disconnect()
		end
	end)

	return attribute
end

return SharedStoryHooks
