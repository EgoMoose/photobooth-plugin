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

	children: React.ReactNode,
}

local function VerticalScroll(props: Props)
	local theme = StudioComponents.useTheme()

	local contentRef = React.useRef(nil :: Frame?)
	local scrollRef = React.useRef(nil :: ScrollingFrame?)

	local contentSize = Hooks.useRefProperty(contentRef, "AbsoluteSize", Vector2.zero)
	local canvasPosition = Hooks.useRefProperty(scrollRef, "CanvasPosition", Vector2.zero)

	return React.createElement("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = props.AnchorPoint,
		Position = props.Position,
		Size = props.Size,
	}, {
		UIStroke = React.createElement("UIStroke", {
			Thickness = 1,
			Transparency = 0,
			Color = theme:GetColor(Enum.StudioStyleGuideColor.Border),
		}),

		Clipped = React.createElement("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			ClipsDescendants = true,
			ZIndex = -1,
		}, {
			Content = React.createElement("Frame", {
				Position = UDim2.fromOffset(0, -canvasPosition.Y),
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.fromScale(1, 0),
				BackgroundTransparency = 1,
				ref = contentRef,
			}, props.children),
		}),

		ScrollingFrame = React.createElement("ScrollingFrame", {
			BorderSizePixel = 0,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			CanvasSize = UDim2.fromOffset(0, contentSize.Y),

			ScrollBarThickness = 4,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			ScrollBarImageColor3 = theme:GetColor(Enum.StudioStyleGuideColor.DimmedText),
			ScrollBarImageTransparency = 0,

			TopImage = Icons.scroll["scroll-top"],
			MidImage = Icons.scroll["scroll-middle"],
			BottomImage = Icons.scroll["scroll-bottom"],

			ref = scrollRef,
		}),
	})
end

return VerticalScroll
