--!strict

local AssetService = game:GetService("AssetService") :: AssetService
local ServerStorage = game:GetService("ServerStorage") :: ServerStorage

local NAME = "PhotoboothStoryTest"

local SharedStoryAssets = {}

local function getSharedStoryMeshPart()
	local found = ServerStorage:FindFirstChild(NAME)
	local object = if found and found:IsA("MeshPart") then found.TextureContent.Object else nil

	if object and object:IsA("EditableImage") then
		return found :: MeshPart
	end

	local editImage = AssetService:CreateEditableImageAsync(Content.fromUri("rbxassetid://98795642888307"))

	local meshPart = Instance.new("MeshPart")
	meshPart.Locked = true
	meshPart.Archivable = false
	meshPart.Anchored = true
	meshPart.CanCollide = false
	meshPart.CanTouch = false
	meshPart.Transparency = 0 -- cannot be transparent
	meshPart.Name = NAME
	meshPart.Size = Vector3.new(1, 1, 1)
	meshPart.TextureContent = Content.fromObject(editImage)
	meshPart.Parent = ServerStorage

	return meshPart
end

function SharedStoryAssets.getMeshPart()
	return getSharedStoryMeshPart()
end

function SharedStoryAssets.getEditableImage()
	return getSharedStoryMeshPart().TextureContent.Object :: EditableImage
end

return SharedStoryAssets
