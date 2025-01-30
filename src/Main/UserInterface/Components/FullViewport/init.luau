--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local StudioComponents = require(pluginRoot.Packages.StudioComponents)
local Lucide = require(pluginRoot.Packages.Lucide)
local React = require(pluginRoot.Packages.React)

local uiRoot = script:FindFirstAncestor("UserInterface")
local ContainerSize = require(uiRoot.Components.Shared.ContainerSize)
local Hooks = require(uiRoot.Hooks)

local FreeDrag = require(script.FreeDrag)

export type Props = {
	OnCapture: (Rect) -> (),
	FocusLenseSizeRef: { current: Vector2? },
	Disabled: boolean,
}

type ActionBarProps = {
	OnCapture: (Rect) -> (),
	IsDragging: boolean,
	ContainerSize: Vector2,
	Disabled: boolean,
}

local function ActionBar(props: ActionBarProps)
	local moveIcon = assert(Lucide.GetAsset("move", 16))
	local cameraIcon = assert(Lucide.GetAsset("camera", 16))

	local theme = StudioComponents.useTheme()
	local scaleOS = Hooks.usePhotoConfiguration().ScaleOS

	local displaySize = (scaleOS * props.ContainerSize):Ceil()

	return React.createElement("Frame", {
		Size = UDim2.fromScale(1, 1),
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
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			Padding = UDim.new(0, 0),
		}),

		Icon = React.createElement("ImageLabel", {
			Image = moveIcon.Url,
			ImageRectSize = moveIcon.ImageRectSize,
			ImageRectOffset = moveIcon.ImageRectOffset,

			Size = UDim2.fromOffset(moveIcon.ImageRectSize.X, moveIcon.ImageRectSize.Y),
			BackgroundTransparency = 1,
			ImageColor3 = Color3.fromRGB(102, 102, 102),
			LayoutOrder = 1,
		}),

		Spacing1 = React.createElement("Frame", {
			Size = UDim2.new(0, 4, 1, 0),
			BackgroundTransparency = 1,
			LayoutOrder = 2,
		}),

		Label = React.createElement("TextLabel", {
			Size = UDim2.new(1, -24 - 16 - 4 - 6, 1, 0),
			BackgroundTransparency = 1,

			Text = `{displaySize.X} x {displaySize.Y}`,
			TextColor3 = Color3.fromRGB(102, 102, 102),
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextSize = 8,

			LayoutOrder = 3,
		}),

		Spacing2 = React.createElement("Frame", {
			Size = UDim2.new(0, 6, 1, 0),
			BackgroundTransparency = 1,
			LayoutOrder = 4,
		}),

		Capture = React.createElement(StudioComponents.MainButton, {
			Size = UDim2.new(0, 24, 1, 0),

			Icon = {
				Image = cameraIcon.Url,
				RectSize = cameraIcon.ImageRectSize,
				RectOffset = cameraIcon.ImageRectOffset,

				Size = cameraIcon.ImageRectSize,
				Transparency = if props.Disabled then 0.7 else 0,
				Color = Color3.new(1, 1, 1),
			},

			OnActivated = function()
				props.OnCapture(Rect.new(Vector2.zero, props.ContainerSize))
			end,
			Disabled = props.Disabled,
			LayoutOrder = 5,
		}),
	})
end

type HoverFadeProps = {
	DetectionSize: UDim2,
	HoverOnTransparency: number,
	HoverOffTransparency: number,
	IsDragging: boolean,
	children: React.ReactNode,
}

local function HoverFade(props: HoverFadeProps)
	if props.HoverOnTransparency == props.HoverOffTransparency then
		return React.createElement(React.Fragment, nil, props.children)
	end

	local goal, setGoal = React.useBinding(props.HoverOffTransparency)
	local transparency, setTransparency = Hooks.useSpring(goal)

	React.useMemo(function()
		if not props.IsDragging then
			setTransparency(props.HoverOnTransparency)
		end
	end, { props.IsDragging })

	return React.createElement("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		Fade = React.createElement("CanvasGroup", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			GroupTransparency = if props.IsDragging then props.HoverOnTransparency else transparency,
		}, props.children),

		Detection = React.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = props.DetectionSize,

			BackgroundTransparency = 1,
			ZIndex = -1,

			[React.Event.InputBegan] = function(_rbx, input: InputObject)
				if input.UserInputType == Enum.UserInputType.MouseMovement then
					setGoal(props.HoverOnTransparency)
				end
			end,
			[React.Event.InputEnded] = function(_rbx, input: InputObject)
				if input.UserInputType == Enum.UserInputType.MouseMovement then
					setGoal(props.HoverOffTransparency)
				end
			end,
		}),
	})
end

local function InnerBorder(props: { Thickness: number, Disabled: boolean, children: React.ReactNode })
	local theme = StudioComponents.useTheme()

	return React.createElement("Frame", {
		Size = UDim2.new(1, -props.Thickness * 2, 1, -props.Thickness * 2),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		ZIndex = 2,
	}, {
		UIStroke = React.createElement("UIStroke", {
			Thickness = props.Thickness,
			Transparency = 0,
			Color = theme:GetColor(Enum.StudioStyleGuideColor.InputFieldBorder, Enum.StudioStyleGuideModifier.Selected),
		}),
	}, props.children)
end

local function FullViewport(props: Props)
	local isDragging, setIsDragging = React.useState(false)
	local containerSize, setContainerSize = React.useState(Vector2.zero)

	React.useEffect(function()
		props.FocusLenseSizeRef.current = containerSize
	end, { containerSize })

	return React.createElement(ContainerSize, {
		SetContainerSize = setContainerSize,
	}, {
		Outline = React.createElement(InnerBorder, {
			Thickness = 2,
			Disabled = false,
		}, {
			Dragger = React.createElement(FreeDrag, {
				SetIsDragging = setIsDragging,

				InitialPosition = UDim2.fromScale(0, 0),
				AnchorPoint = Vector2.new(0, 0),
				Size = UDim2.fromOffset(120, 28),

				Disabled = props.Disabled,
			}, {
				HoverFade = React.createElement(HoverFade, {
					DetectionSize = UDim2.new(1, 500, 1, 500),
					HoverOnTransparency = 0,
					HoverOffTransparency = 0,
					IsDragging = isDragging,
				}, {
					ActionBar = React.createElement(ActionBar, {
						IsDragging = isDragging,
						ContainerSize = containerSize,
						OnCapture = props.OnCapture,
						Disabled = props.Disabled,
					}),
				}),
			}),
		}),
	})
end

return FullViewport
