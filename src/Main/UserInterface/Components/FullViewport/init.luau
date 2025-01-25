--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local StudioComponents = require(pluginRoot.Packages.StudioComponents)
local Lucide = require(pluginRoot.Packages.Lucide)
local React = require(pluginRoot.Packages.React)

local FreeDrag = require(script.FreeDrag)

local uiRoot = script:FindFirstAncestor("UserInterface")
local Hooks = require(uiRoot.Hooks)

export type Props = {
	OnCapture: (Rect) -> (),
	Disabled: boolean,
}

local function ActionBar(props: Props)
	local moveIcon = assert(Lucide.GetAsset("move", 16))
	local cameraIcon = assert(Lucide.GetAsset("camera", 16))

	local theme = StudioComponents.useTheme()
	local containerSize = FreeDrag.useContainerSize()
	local scaleOS = Hooks.usePhotoConfiguration().ScaleOS

	local displaySize = (scaleOS * containerSize):Ceil()

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
				props.OnCapture(Rect.new(Vector2.zero, containerSize))
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
	children: React.ReactNode,
}

local function HoverFade(props: HoverFadeProps)
	local isDragging = FreeDrag.useIsDragging()
	local goal, setGoal = React.useBinding(props.HoverOffTransparency)
	local transparency, setTransparency = Hooks.useSpring(goal)

	React.useMemo(function()
		if not isDragging then
			setTransparency(props.HoverOnTransparency)
		end
	end, { isDragging })

	return React.createElement("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		Fade = React.createElement("CanvasGroup", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			GroupTransparency = if isDragging then props.HoverOnTransparency else transparency,
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

local function FullViewport(props: Props)
	return React.createElement(FreeDrag.Component, {
		InitialPosition = UDim2.fromScale(0, 0),
		AnchorPoint = Vector2.new(0, 0),
		Size = UDim2.fromOffset(120, 28),

		Disabled = props.Disabled,
	}, {
		HoverFade = React.createElement(HoverFade, {
			DetectionSize = UDim2.new(1, 500, 1, 500),
			HoverOnTransparency = 0,
			HoverOffTransparency = 0.7,
		}, {
			ActionBar = React.createElement(ActionBar, props),
		}),
	})
end

return FullViewport
