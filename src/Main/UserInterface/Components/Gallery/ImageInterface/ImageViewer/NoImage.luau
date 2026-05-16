local pluginRoot = script:FindFirstAncestor("PluginRoot")
local StudioComponents = require(pluginRoot.Packages.StudioComponents)
local Lucide = require(pluginRoot.Packages.Lucide)
local React = require(pluginRoot.Packages.React)

export type Props = {
	AnchorPoint: Vector2,
	Position: UDim2,
	Size: UDim2,
}

local function DisplayNoImage(props: Props)
	local theme = StudioComponents.useTheme()
	local imageIcon = assert(Lucide.GetAsset("images", 48))

	return React.createElement("Frame", {
		AnchorPoint = props.AnchorPoint,
		Position = props.Position,
		Size = props.Size,
		BackgroundTransparency = 1,
	}, {
		Layout = React.createElement("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			FillDirection = Enum.FillDirection.Vertical,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0, 4),
		}),

		Icon = React.createElement("ImageLabel", {
			LayoutOrder = 0,
			Size = UDim2.fromOffset(imageIcon.ImageRectSize.X, imageIcon.ImageRectSize.Y),
			BackgroundTransparency = 1,
			Image = imageIcon.Url,
			ImageColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText),
			ImageTransparency = 0.7,
			ImageRectSize = imageIcon.ImageRectSize,
			ImageRectOffset = imageIcon.ImageRectOffset,
		}),
		Label1 = React.createElement("TextLabel", {
			LayoutOrder = 1,
			Size = UDim2.new(0, 200, 0, 28),
			BackgroundTransparency = 1,
			Text = "Photobooth Gallery",
			TextScaled = true,
			TextTransparency = 0.7,
			TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText),
		}),
		Label2 = React.createElement("TextLabel", {
			LayoutOrder = 3,
			Size = UDim2.new(0, 200, 0, 18),
			BackgroundTransparency = 1,
			Text = "No Image Selected",
			TextScaled = true,
			TextTransparency = 0.7,
			TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText),
		}),
	})
end

return DisplayNoImage
