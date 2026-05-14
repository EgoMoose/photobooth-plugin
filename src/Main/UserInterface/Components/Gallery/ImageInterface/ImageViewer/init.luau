--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local React = require(pluginRoot.Packages.React)

local uiRoot = script:FindFirstAncestor("UserInterface")
local Hooks = require(uiRoot.Hooks)

local useImageControls = require(script.Parent.useImageControls)

local NoImage = require(script.NoImage)
local DisplayImage = require(script.DisplayImage)

export type Props = {
	AnchorPoint: Vector2,
	Position: UDim2,
	Size: UDim2,

	EditableImageInfo: Hooks.EditableImageInfo?,

	BackgroundType: string,
	SetBackgroundType: (string) -> (),

	ImageControls: useImageControls.ImageControls,
	ViewerRef: { current: GuiObject? },

	Padding: {
		PaddingTop: UDim?,
		PaddingLeft: UDim?,
		PaddingRight: UDim?,
		PaddingBottom: UDim?,
	}?,
}

local function ImageViewer(props: Props)
	return React.createElement("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = props.AnchorPoint,
		Position = props.Position,
		Size = props.Size,
	}, {
		NoImage = not props.EditableImageInfo and React.createElement(NoImage, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(1, -44, 1, -44),
		}),

		DisplayImage = props.EditableImageInfo and React.createElement(DisplayImage, {
			Size = UDim2.new(1, -44, 1, -44),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),

			Name = props.EditableImageInfo.Name,
			EditableImage = props.EditableImageInfo.EditableImage,

			BackgroundType = props.BackgroundType,
			SetBackgroundType = props.SetBackgroundType,

			ImageControls = props.ImageControls,
			ViewerRef = props.ViewerRef,
		}),
	})
end

return ImageViewer
