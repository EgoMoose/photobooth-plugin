--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local React = require(pluginRoot.Packages.React)

local uiRoot = script:FindFirstAncestor("UserInterface")
local Hooks = require(uiRoot.Hooks)

local NoImage = require(script.NoImage)
local DisplayImage = require(script.DisplayImage)

export type Props = {
	AnchorPoint: Vector2,
	Position: UDim2,
	Size: UDim2,

	EditableImageInfo: Hooks.EditableImageInfo?,

	BackgroundType: string,
	SetBackgroundType: (string) -> (),

	Padding: {
		PaddingTop: UDim?,
		PaddingLeft: UDim?,
		PaddingRight: UDim?,
		PaddingBottom: UDim?,
	}?,
}

local function ImageViewer(props: Props)
	return React.createElement("Frame", {
		AnchorPoint = props.AnchorPoint,
		Position = props.Position,
		Size = props.Size,
		BackgroundTransparency = 1,
	}, {
		NoImage = not props.EditableImageInfo and React.createElement(NoImage, {
			AnchorPoint = Vector2.new(0, 0),
			Position = UDim2.fromScale(0, 0),
			Size = UDim2.fromScale(1, 1),
		}),

		DisplayImage = props.EditableImageInfo and React.createElement(DisplayImage, {
			Size = UDim2.fromScale(1, 1),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),

			Name = props.EditableImageInfo.Name,
			EditableImage = props.EditableImageInfo.EditableImage,

			BackgroundType = props.BackgroundType,
			SetBackgroundType = props.SetBackgroundType,

			Padding = props.Padding or {},
		}),
	})
end

return ImageViewer
