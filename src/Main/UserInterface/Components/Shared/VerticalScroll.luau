local pluginRoot = script:FindFirstAncestor("PluginRoot")
local StudioComponents = require(pluginRoot.Packages.StudioComponents)
local React = require(pluginRoot.Packages.React)

local uiRoot = script:FindFirstAncestor("UserInterface")
local Icons = require(uiRoot.Icons)
local Hooks = require(uiRoot.Hooks)

export type Props = {
	AnchorPoint: Vector2,
	Position: UDim2,
	Size: UDim2,

	ScrollInset: UDim?,
	ScrollBarThickness: number?,
	ScrollBarTransparency: number?,

	GradientHeight: number,
	GradientColor: Color3,

	Disabled: boolean,

	children: React.ReactNode,
}

local function VerticalScroll(props: Props)
	local theme = StudioComponents.useTheme()

	local contentRef = React.useRef(nil :: Frame?)
	local scrollRef = React.useRef(nil :: ScrollingFrame?)

	local contentSize = Hooks.useRefProperty(contentRef, "AbsoluteSize", Vector2.zero)
	local canvasPosition = Hooks.useRefProperty(scrollRef, "CanvasPosition", Vector2.zero)

	local scrollInset = props.ScrollInset or UDim.new(0, 0)

	return React.createElement("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = props.AnchorPoint,
		Position = props.Position,
		Size = props.Size,
	}, {
		Clipped = React.createElement("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			ClipsDescendants = true,
			ZIndex = -2,
		}, {
			Content = React.createElement("Frame", {
				Position = UDim2.fromOffset(0, -canvasPosition.Y),
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.fromScale(1, 0),
				BackgroundTransparency = 1,
				ref = contentRef,
			}, props.children),
		}),

		Gradient = React.createElement("Frame", {
			BorderSizePixel = 0,
			BackgroundColor3 = props.GradientColor,
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.fromScale(0, 1),
			Size = UDim2.new(1, 0, 0, props.GradientHeight),
			ZIndex = -1,
		}, {
			Gradient = React.createElement("UIGradient", {
				Transparency = NumberSequence.new(0, 1),
				Rotation = -90,
			}),
		}),

		ScrollingFrame = React.createElement("ScrollingFrame", {
			BorderSizePixel = 0,
			BackgroundTransparency = 1,
			Size = UDim2.new(1 + scrollInset.Scale, scrollInset.Offset, 1, 0),
			CanvasSize = UDim2.fromOffset(0, contentSize.Y),

			ScrollingEnabled = not props.Disabled,
			ScrollBarThickness = props.ScrollBarThickness or 4,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			ScrollBarImageColor3 = theme:GetColor(Enum.StudioStyleGuideColor.DimmedText),
			ScrollBarImageTransparency = props.ScrollBarTransparency or 0,

			TopImage = Icons.scroll["scroll-top"],
			MidImage = Icons.scroll["scroll-middle"],
			BottomImage = Icons.scroll["scroll-bottom"],

			ref = scrollRef,
		}),
	})
end

return VerticalScroll
