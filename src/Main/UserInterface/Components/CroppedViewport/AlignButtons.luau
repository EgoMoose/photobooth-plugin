--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local StudioComponents = require(pluginRoot.Packages.StudioComponents)
local ReactRipple = require(pluginRoot.Packages.ReactRipple)
local Lucide = require(pluginRoot.Packages.Lucide)
local React = require(pluginRoot.Packages.React)

local uiRoot = script:FindFirstAncestor("UserInterface")
local Hooks = require(uiRoot.Hooks)

local TRANSPARENCY = 1

export type Props = {
	Visible: boolean,
	OnJustify: (number?, number?) -> (),
	ZIndex: number?,
	Disabled: boolean?,
}

local function useTransparency(initial: number)
	local transparencyBinding, control = ReactRipple.useSpring(initial)
	local transparency = Hooks.useBindingState(transparencyBinding)
	return transparency, React.useCallback(function(value: number)
		control:setGoal(value)
	end, {})
end

local function AlignButtons(props: Props)
	local alignCenter = assert(Lucide.GetAsset("ratio", 16))

	local alignLeftHorizontal = assert(Lucide.GetAsset("align-horizontal-justify-start", 16))
	local alignCenterHorizontal = assert(Lucide.GetAsset("align-horizontal-justify-center", 16))
	local alignRightHorizontal = assert(Lucide.GetAsset("align-horizontal-justify-end", 16))

	local alignTopVertical = assert(Lucide.GetAsset("align-vertical-justify-start", 16))
	local alignCenterVertical = assert(Lucide.GetAsset("align-vertical-justify-center", 16))
	local alignBottomVertical = assert(Lucide.GetAsset("align-vertical-justify-end", 16))

	local transparency, setTransparency = useTransparency(TRANSPARENCY)

	React.useEffect(function()
		setTransparency(if props.Visible then 0 else TRANSPARENCY)
	end, { props.Visible })

	return React.createElement("CanvasGroup", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		GroupTransparency = transparency,
		ZIndex = props.ZIndex,
	}, {
		AlignControls = React.createElement("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
		}, {
			TopRightCorner = React.createElement("Frame", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.fromScale(1, 0),
				Size = UDim2.fromOffset(32, 28),
			}, {
				AlignCenter = React.createElement(StudioComponents.Button, {
					AnchorPoint = Vector2.new(0, 1),
					Position = UDim2.new(0, 0, 1, 0),
					Size = UDim2.fromOffset(24, 20),

					Icon = {
						Image = alignCenter.Url,
						RectSize = alignCenter.ImageRectSize,
						RectOffset = alignCenter.ImageRectOffset,

						Size = alignCenter.ImageRectSize,
						Transparency = if props.Disabled then 0.7 else 0,
						Color = Color3.new(1, 1, 1),
					},

					OnActivated = function()
						props.OnJustify(0.5, 0.5)
					end,

					Disabled = props.Disabled,
				}),
			}),

			AlignHorizontal = React.createElement("Frame", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -40, 0, 0),
				Size = UDim2.new(1, -40, 0, 28),
			}, {
				Layout = React.createElement("UIListLayout", {
					SortOrder = Enum.SortOrder.LayoutOrder,
					FillDirection = Enum.FillDirection.Horizontal,
					VerticalAlignment = Enum.VerticalAlignment.Bottom,
					HorizontalAlignment = Enum.HorizontalAlignment.Right,
					Padding = UDim.new(0, 4),
				}),

				AlignRight = React.createElement(StudioComponents.Button, {
					Size = UDim2.fromOffset(24, 20),
					LayoutOrder = -1,

					Icon = {
						Image = alignRightHorizontal.Url,
						RectSize = alignRightHorizontal.ImageRectSize,
						RectOffset = alignRightHorizontal.ImageRectOffset,

						Size = alignRightHorizontal.ImageRectSize,
						Transparency = if props.Disabled then 0.7 else 0,
						Color = Color3.new(1, 1, 1),
					},

					OnActivated = function()
						props.OnJustify(1, nil)
					end,

					Disabled = props.Disabled,
				}),

				AlignCenter = React.createElement(StudioComponents.Button, {
					Size = UDim2.fromOffset(24, 20),
					LayoutOrder = -2,

					Icon = {
						Image = alignCenterHorizontal.Url,
						RectSize = alignCenterHorizontal.ImageRectSize,
						RectOffset = alignCenterHorizontal.ImageRectOffset,

						Size = alignCenterHorizontal.ImageRectSize,
						Transparency = if props.Disabled then 0.7 else 0,
						Color = Color3.new(1, 1, 1),
					},

					OnActivated = function()
						props.OnJustify(0.5, nil)
					end,

					Disabled = props.Disabled,
				}),

				AlignLeft = React.createElement(StudioComponents.Button, {
					Size = UDim2.fromOffset(24, 20),
					LayoutOrder = -3,

					Icon = {
						Image = alignLeftHorizontal.Url,
						RectSize = alignLeftHorizontal.ImageRectSize,
						RectOffset = alignLeftHorizontal.ImageRectOffset,

						Size = alignLeftHorizontal.ImageRectSize,
						Transparency = if props.Disabled then 0.7 else 0,
						Color = Color3.new(1, 1, 1),
					},

					OnActivated = function()
						props.OnJustify(0, nil)
					end,

					Disabled = props.Disabled,
				}),
			}),

			AlignVertical = React.createElement("Frame", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, 0, 0, 36),
				Size = UDim2.new(0, 32, 1, -36),
			}, {
				Layout = React.createElement("UIListLayout", {
					SortOrder = Enum.SortOrder.LayoutOrder,
					FillDirection = Enum.FillDirection.Vertical,
					VerticalAlignment = Enum.VerticalAlignment.Top,
					HorizontalAlignment = Enum.HorizontalAlignment.Left,
					Padding = UDim.new(0, 4),
				}),

				AlignTop = React.createElement(StudioComponents.Button, {
					Size = UDim2.fromOffset(24, 20),
					LayoutOrder = 1,

					Icon = {
						Image = alignTopVertical.Url,
						RectSize = alignTopVertical.ImageRectSize,
						RectOffset = alignTopVertical.ImageRectOffset,

						Size = alignTopVertical.ImageRectSize,
						Transparency = if props.Disabled then 0.7 else 0,
						Color = Color3.new(1, 1, 1),
					},

					OnActivated = function()
						props.OnJustify(nil, 0)
					end,

					Disabled = props.Disabled,
				}),

				AlignCenter = React.createElement(StudioComponents.Button, {
					Size = UDim2.fromOffset(24, 20),
					LayoutOrder = 2,

					Icon = {
						Image = alignCenterVertical.Url,
						RectSize = alignCenterVertical.ImageRectSize,
						RectOffset = alignCenterVertical.ImageRectOffset,

						Size = alignCenterVertical.ImageRectSize,
						Transparency = if props.Disabled then 0.7 else 0,
						Color = Color3.new(1, 1, 1),
					},

					OnActivated = function()
						props.OnJustify(nil, 0.5)
					end,

					Disabled = props.Disabled,
				}),

				AlignBottom = React.createElement(StudioComponents.Button, {
					Size = UDim2.fromOffset(24, 20),
					LayoutOrder = 3,

					Icon = {
						Image = alignBottomVertical.Url,
						RectSize = alignBottomVertical.ImageRectSize,
						RectOffset = alignBottomVertical.ImageRectOffset,

						Size = alignBottomVertical.ImageRectSize,
						Transparency = if props.Disabled then 0.7 else 0,
						Color = Color3.new(1, 1, 1),
					},

					OnActivated = function()
						props.OnJustify(nil, 1)
					end,

					Disabled = props.Disabled,
				}),
			}),
		}),
	})
end

return AlignButtons
