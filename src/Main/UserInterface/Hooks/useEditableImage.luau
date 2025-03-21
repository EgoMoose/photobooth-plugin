--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local React = require(pluginRoot.Packages.React)

local CLASS_TO_CONTENT_PROPERTY: { [string]: string } = {
	-- ["Decal"] = "TextureContent",
	["MeshPart"] = "TextureContent",
	-- ["ImageLabel"] = "ImageContent",
	-- ["ImageButton"] = "ImageContent",
}

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
	local contentProperty = if instance then CLASS_TO_CONTENT_PROPERTY[instance.ClassName] else nil

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
