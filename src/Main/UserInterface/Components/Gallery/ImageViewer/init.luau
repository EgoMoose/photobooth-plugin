--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local React = require(pluginRoot.Packages.React)

local DisplayNoImage = require(script.DisplayNoImage)
local DisplayEditableImage = require(script.DisplayEditableImage)

export type Props = {
	AnchorPoint: Vector2,
	Position: UDim2,
	Size: UDim2,

	EditableImage: EditableImage?,
	EditableImageName: string,

	BackgroundType: string,
	SetBackgroundType: (string) -> (),
}

local function ImageViewer(props: Props)
	return React.createElement("Frame", {
		AnchorPoint = props.AnchorPoint,
		Position = props.Position,
		Size = props.Size,
		BackgroundTransparency = 1,
	}, {
		Padding = React.createElement("UIPadding", {
			PaddingLeft = UDim.new(0, 4),
			PaddingRight = UDim.new(0, 4),
			PaddingTop = UDim.new(0, 4),
			PaddingBottom = UDim.new(0, 4),
		}),

		DisplayNoImage = not props.EditableImage and React.createElement(DisplayNoImage, {
			AnchorPoint = Vector2.new(0, 0),
			Position = UDim2.fromScale(0, 0),
			Size = UDim2.fromScale(1, 1),
		}),

		DisplayEditableImage = props.EditableImage and React.createElement(DisplayEditableImage, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(1, -20, 1, -20),

			EditableImage = props.EditableImage,
			EditableImageName = props.EditableImageName,

			BackgroundType = props.BackgroundType,
			SetBackgroundType = props.SetBackgroundType,
		}),
	})
end

return ImageViewer
