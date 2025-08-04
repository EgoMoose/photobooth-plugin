--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local React = require(pluginRoot.Packages.React)

local CLASS_TO_CONTENT_PROPERTY: { [string]: string } = {
	-- ["Decal"] = "TextureContent",
	["MeshPart"] = "TextureContent",
	-- ["ImageLabel"] = "ImageContent",
	-- ["ImageButton"] = "ImageContent",
}

export type EditableImageInfo = {
	Name: string,
	Instance: Instance,
	EditableImage: EditableImage,
}

local function tryGetEditImage(instance: Instance, contentProperty: string): EditableImage?
	local content = (instance :: any)[contentProperty] :: Content
	local object = content and content.Object

	if object and object:IsA("EditableImage") then
		return object
	end

	return nil
end

local function getEditableImageInfos(instances: { Instance })
	local editableImagesInfo: { EditableImageInfo } = {}
	for _, instance in instances do
		for class, contentProperty in CLASS_TO_CONTENT_PROPERTY do
			if instance:IsA(class) then
				local editImage = tryGetEditImage(instance, contentProperty)
				if editImage then
					table.insert(editableImagesInfo, {
						Name = instance.Name,
						Instance = instance,
						EditableImage = editImage,
					})

					break
				end
			end
		end
	end
	return editableImagesInfo
end

local function useEditableImageInfos(instances: { Instance })
	local editableImageInfos, setEditableImageInfos = React.useState(getEditableImageInfos(instances))

	React.useEffect(function()
		setEditableImageInfos(getEditableImageInfos(instances))

		local connections = {}
		for _, instance in instances do
			for class, contentProperty in CLASS_TO_CONTENT_PROPERTY do
				if instance:IsA(class) then
					table.insert(
						connections,
						instance:GetPropertyChangedSignal(contentProperty):Connect(function()
							setEditableImageInfos(getEditableImageInfos(instances))
						end)
					)

					table.insert(
						connections,
						instance:GetPropertyChangedSignal("Name"):Connect(function()
							setEditableImageInfos(getEditableImageInfos(instances))
						end)
					)
				end
			end
		end

		return function()
			for _, connection in connections do
				connection:Disconnect()
			end
		end
	end, { instances })

	return editableImageInfos
end

return useEditableImageInfos
