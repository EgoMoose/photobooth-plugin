--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local React = require(pluginRoot.Packages.React)

type Props = {
	AnchorPoint: Vector2?,
	Position: UDim2?,
	Size: UDim2?,

	MarginBump: number,
	OverlapBump: number,

	Transparency: number,
	Color: Color3,

	ZIndex: number,
}

local function Blinder(props: Props)
	local anchorPoint = props.AnchorPoint or Vector2.zero
	local position = props.Position or UDim2.new(0, 0, 0, 0)
	local size = props.Size or UDim2.new(0, 0, 0, 0)

	local centerXScale = position.X.Scale + size.X.Scale * (0.5 - anchorPoint.X)
	local centerYScale = position.Y.Scale + size.Y.Scale * (0.5 - anchorPoint.Y)
	local centerXOffset = position.X.Offset + size.X.Offset * (0.5 - anchorPoint.X)
	local centerYOffset = position.Y.Offset + size.Y.Offset * (0.5 - anchorPoint.Y)

	-- using a canvas group avoid overlap lines that may occur
	-- when half-pixels are involved
	return React.createElement("CanvasGroup", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		GroupTransparency = props.Transparency,
		GroupColor3 = props.Color,
		ZIndex = props.ZIndex,
	}, {
		Top = React.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(
				centerXScale,
				centerXOffset,
				centerYScale - size.Y.Scale / 2,
				centerYOffset - size.Y.Offset / 2 + props.MarginBump
			),
			Size = UDim2.new(2, 0, 2, 0),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 0,
			BorderSizePixel = 0,
		}),
		Bottom = React.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(
				centerXScale,
				centerXOffset,
				centerYScale + size.Y.Scale / 2,
				centerYOffset + size.Y.Offset / 2 - props.MarginBump
			),
			Size = UDim2.new(2, 0, 2, 0),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 0,
			BorderSizePixel = 0,
		}),
		Left = React.createElement("Frame", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(
				centerXScale - size.X.Scale / 2,
				centerXOffset - size.X.Offset / 2 + props.MarginBump,
				centerYScale,
				centerYOffset
			),
			Size = UDim2.new(2, 0, size.Y.Scale, size.Y.Offset + (props.OverlapBump - props.MarginBump) * 2),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 0,
			BorderSizePixel = 0,
		}),
		Right = React.createElement("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(
				centerXScale + size.X.Scale / 2,
				centerXOffset + size.X.Offset / 2 - props.MarginBump,
				centerYScale,
				centerYOffset
			),
			Size = UDim2.new(2, 0, size.Y.Scale, size.Y.Offset + (props.OverlapBump - props.MarginBump) * 2),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 0,
			BorderSizePixel = 0,
		}),
	})
end

return Blinder
