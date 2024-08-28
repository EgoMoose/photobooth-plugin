--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local StudioComponents = require(pluginRoot.Packages.StudioComponents)
local Lucide = require(pluginRoot.Packages.Lucide)
local React = require(pluginRoot.Packages.React)

local Image = require(pluginRoot.Utilities.Image)

local UPLOADING_ENABLED = false

export type UploadInfo = {
	Title: string,
	EditableImage: EditableImage,
}

export type Props = {
	AnchorPoint: Vector2,
	Position: UDim2,
	Size: UDim2,

	EditableImage: EditableImage?,
	EditableImageName: string,

	OnUpload: (UploadInfo) -> (),

	Disabled: boolean,
}

local function ActionBar(props: Props)
	local theme = StudioComponents.useTheme()

	local uploadIcon = assert(Lucide.GetAsset("upload", 16))
	local uploadDisabled = not (UPLOADING_ENABLED and not props.Disabled and props.EditableImage)

	return React.createElement("Frame", {
		AnchorPoint = props.AnchorPoint,
		Position = props.Position,
		Size = props.Size,
		BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Titlebar),
		BorderColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Border),
	}, {
		Padding = React.createElement("UIPadding", {
			PaddingLeft = UDim.new(0, 4),
			PaddingRight = UDim.new(0, 4),
			PaddingTop = UDim.new(0, 4),
			PaddingBottom = UDim.new(0, 4),
		}),
		Layout = React.createElement("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			Padding = UDim.new(0, 4),
		}),

		Upload = UPLOADING_ENABLED and React.createElement(StudioComponents.MainButton, {
			LayoutOrder = -1,
			Size = UDim2.new(0, 70, 1, 0),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.fromScale(1, 0.5),
			TextXAlignment = Enum.TextXAlignment.Center,
			Text = "Upload",
			Disabled = uploadDisabled,
			OnActivated = function()
				if props.EditableImage then
					props.OnUpload({
						Title = props.EditableImageName,
						EditableImage = Image.fromEditableImage(props.EditableImage):Save(), -- this effectively clones the edit image
					})
				end
			end,

			Icon = {
				Image = uploadIcon.Url,
				RectSize = uploadIcon.ImageRectSize,
				RectOffset = uploadIcon.ImageRectOffset,
				Transparency = if uploadDisabled and theme.Name == "Dark" then 0.7 else nil,
				Size = Vector2.new(uploadIcon.ImageRectSize.X, uploadIcon.ImageRectSize.Y),
			},
		}),
	})
end

return ActionBar
