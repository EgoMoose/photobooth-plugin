--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local React = require(pluginRoot.Packages.React)

local function getContentProperty(instance: Instance)
	local contentProperty: string?
	if instance:IsA("MeshPart") then
		contentProperty = "TextureContent"
	end

	return contentProperty
end

local function tryGetEditImage(instance: Instance, contentProperty: string): EditableImage?
	local content = (instance :: any)[contentProperty] :: Content
	local object = content and content.Object

	if object and object:IsA("EditableImage") then
		return object
	end

	return nil
end

local function useEditableImage(instance: Instance?)
	local ticket, setTicket = React.useState(1)
	local contentProperty = if instance then getContentProperty(instance) else nil

	React.useEffect(function()
		local connection: RBXScriptConnection?

		if instance and contentProperty then
			connection = instance:GetPropertyChangedSignal(contentProperty):Connect(function()
				setTicket(ticket + 1)
			end)
		end

		return function()
			if connection then
				connection:Disconnect()
			end
		end
	end, {})

	return if instance and contentProperty then tryGetEditImage(instance, contentProperty) else nil
end

return useEditableImage
