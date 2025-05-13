--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local StudioComponents = require(pluginRoot.Packages.StudioComponents)
local Lucide = require(pluginRoot.Packages.Lucide)
local React = require(pluginRoot.Packages.React)

local uiRoot = script:FindFirstAncestor("UserInterface")
local Constants = require(uiRoot.Constants)

type Props = {
	AnchorPoint: Vector2,
	Position: UDim2,
	Size: UDim2,

	DisplayedAbsSize: Vector2,
	OnDimensionInput: (Vector2) -> (),

	OnMaximize: () -> (),
	OnCapture: () -> (),

	Disabled: boolean,
}

type DimensionProps = {
	AnchorPoint: Vector2,
	Position: UDim2,
	Size: UDim2,

	DisplayedAbsSize: Vector2,
	OnDimensionInput: (Vector2) -> (),

	Disabled: boolean,
}

local function Dimensions(props: DimensionProps)
	local theme = StudioComponents.useTheme()

	return React.createElement("Frame", {
		AnchorPoint = props.AnchorPoint,
		Position = props.Position,
		Size = props.Size,
		BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.InputFieldBackground),
		BorderColor3 = theme:GetColor(Enum.StudioStyleGuideColor.InputFieldBorder),
		BorderMode = Enum.BorderMode.Inset,
	}, {
		Layout = React.createElement("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0, 0),
		}),

		CrossContainer = React.createElement("Frame", {
			Size = UDim2.new(0, 14, 1, 0),
			BackgroundTransparency = 1,
			LayoutOrder = 2,
		}, {
			Cross = React.createElement("TextLabel", {
				Size = UDim2.fromScale(1, 1),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,

				FontFace = Font.fromEnum(Enum.Font.SourceSans),
				TextColor3 = Color3.fromRGB(102, 102, 102),
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
				TextSize = 14,
				Text = "x",
			}),
		}),

		Width = React.createElement("TextBox", {
			Size = UDim2.new(0.5, -7, 1, 0),
			BackgroundTransparency = 1,
			LayoutOrder = 1,

			FontFace = Font.fromEnum(Enum.Font.SourceSans),
			TextColor3 = Color3.fromRGB(102, 102, 102),
			TextXAlignment = Enum.TextXAlignment.Right,
			TextYAlignment = Enum.TextYAlignment.Center,
			TextSize = 14,
			Text = tostring(props.DisplayedAbsSize.X),

			[React.Event.FocusLost] = function(rbx, _enterPressed)
				local dimension = tonumber(rbx.Text)
				if dimension then
					dimension = math.floor(dimension)
					props.OnDimensionInput(Vector2.new(dimension, props.DisplayedAbsSize.Y))
				end
				rbx.Text = tostring(props.DisplayedAbsSize.X)
			end,
		}),

		Height = React.createElement("TextBox", {
			Size = UDim2.new(0.5, -7, 1, 0),
			BackgroundTransparency = 1,
			LayoutOrder = 3,

			FontFace = Font.fromEnum(Enum.Font.SourceSans),
			TextColor3 = Color3.fromRGB(102, 102, 102),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			TextSize = 14,
			Text = tostring(props.DisplayedAbsSize.Y),

			[React.Event.FocusLost] = function(rbx, _enterPressed)
				local dimension = tonumber(rbx.Text)
				if dimension then
					dimension = math.floor(dimension)
					props.OnDimensionInput(Vector2.new(props.DisplayedAbsSize.X, dimension))
				end
				rbx.Text = tostring(props.DisplayedAbsSize.Y)
			end,
		}),
	})
end

local function ActionBar(props: Props)
	local theme = StudioComponents.useTheme()
	local cameraIcon = assert(Lucide.GetAsset("camera", 16))
	local maximizeIcon = assert(Lucide.GetAsset("maximize", 16))

	local dimensionsWidthOffset = 0
	if Constants.FullscreenActionBarButton then
		dimensionsWidthOffset = -24 - 4
	end

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

		Dimensions = React.createElement(Dimensions, {
			AnchorPoint = Vector2.new(0, 0),
			Position = UDim2.fromScale(0, 0),
			Size = UDim2.new(1, -24 - 4 + dimensionsWidthOffset, 1, 0),

			DisplayedAbsSize = props.DisplayedAbsSize,
			OnDimensionInput = props.OnDimensionInput,

			Disabled = props.Disabled,
		}),

		Maximize = Constants.FullscreenActionBarButton and React.createElement("Frame", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -24 - 4, 0, 0),
			Size = UDim2.new(0, 24, 1, 0),
		}, {
			BorderFrame = React.createElement("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				ZIndex = 2,
			}, {
				UIStroke = React.createElement("UIStroke", {
					Thickness = 1,
					Transparency = 0,
					Color = theme:GetColor(
						Enum.StudioStyleGuideColor.InputFieldBorder,
						Enum.StudioStyleGuideModifier.Disabled
					),
				}),
			}),
			Button = React.createElement(StudioComponents.Button, {
				Size = UDim2.fromScale(1, 1),

				Icon = {
					Image = maximizeIcon.Url,
					RectSize = maximizeIcon.ImageRectSize,
					RectOffset = maximizeIcon.ImageRectOffset,

					Size = maximizeIcon.ImageRectSize,
					Transparency = if props.Disabled then 0.7 else 0,
					UseThemeColor = true,
				},

				OnActivated = props.OnMaximize,
				Disabled = props.Disabled,
			}),
		}),

		Capture = React.createElement(StudioComponents.MainButton, {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.fromScale(1, 0),
			Size = UDim2.new(0, 24, 1, 0),

			Icon = {
				Image = cameraIcon.Url,
				RectSize = cameraIcon.ImageRectSize,
				RectOffset = cameraIcon.ImageRectOffset,

				Size = cameraIcon.ImageRectSize,
				Transparency = if props.Disabled then 0.7 else 0,
				Color = Color3.new(1, 1, 1),
			},

			OnActivated = props.OnCapture,
			Disabled = props.Disabled,
		}),
	})
end

return ActionBar
