--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local StudioComponents = require(pluginRoot.Packages.StudioComponents)
local Lucide = require(pluginRoot.Packages.Lucide)
local React = require(pluginRoot.Packages.React)

local uiRoot = script:FindFirstAncestor("UserInterface")
local BaseButton = require(uiRoot.Components.Shared.BaseButton)
local Hooks = require(uiRoot.Hooks)

local FreeDrag = require(script.FreeDrag)

export type Props = {
	OnMinimize: () -> ()?,
	OnCapture: (Rect) -> (boolean, string?),
	FocusLenseSizeRef: { current: Vector2? },
	Disabled: boolean,
}

type ActionBarProps = {
	OnMinimize: () -> ()?,
	OnCapture: (Rect) -> (boolean, string?),
	IsDragging: boolean,
	ContainerSize: Vector2,
	Disabled: boolean,
}

local function ActionBar(props: ActionBarProps)
	local moveIcon = assert(Lucide.GetAsset("move", 16))
	local cameraIcon = assert(Lucide.GetAsset("camera", 16))
	local minimizeIcon = assert(Lucide.GetAsset("minimize", 16))

	local theme = StudioComponents.useTheme()
	local scaleOS = Hooks.useStatePath(function(state)
		return state.temporary.scaleOS
	end)

	local underFrameRef = React.useRef(nil)
	local underFrameAbsPosition = Hooks.useRefProperty(underFrameRef, "AbsolutePosition", Vector2.zero)
	local underFrameAbsSize = Hooks.useRefProperty(underFrameRef, "AbsoluteSize", Vector2.zero)
	local underFrameBottomY = underFrameAbsPosition.Y + underFrameAbsSize.Y
	local useUnderFrame = underFrameBottomY <= workspace.CurrentCamera.ViewportSize.Y

	local shakeOffset, makeShake = Hooks.useShake()
	local errorOffset, makeError = Hooks.useShake()

	local overlayColor = React.useMemo(function()
		return theme
			:GetColor(Enum.StudioStyleGuideColor.MainBackground)
			:Lerp(theme:GetColor(Enum.StudioStyleGuideColor.ErrorText), 0.2)
	end, { theme })

	-- stylua: ignore
	local displaySize = Vector2.new(
		math.round(scaleOS.X * props.ContainerSize.X),
		math.round(scaleOS.Y * props.ContainerSize.Y)
	)

	local labelWithOffset = 0
	if props.OnMinimize then
		labelWithOffset = -24 - 4
	end

	return React.createElement("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	}, {
		ShakeFrame = React.createElement("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Position = UDim2.fromOffset(shakeOffset.X, shakeOffset.Y),
		}, {
			Overlay = shakeOffset.Z < 1 and React.createElement("Frame", {
				Active = false,
				BackgroundTransparency = math.lerp(0.6, 1, shakeOffset.Z ^ 2),
				BackgroundColor3 = overlayColor,
				Size = UDim2.fromScale(1, 1),
				ZIndex = 2,
			}),
			ActionBar = React.createElement("Frame", {
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainBackground),
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
					Size = UDim2.new(1, -24 - 16 - 4 - 6 + labelWithOffset, 1, 0),
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

				Minimize = props.OnMinimize and React.createElement(BaseButton, {
					Size = UDim2.new(0, 24, 1, 0),

					BackgroundColorStyle = Enum.StudioStyleGuideColor.Button,
					BorderColorStyle = Enum.StudioStyleGuideColor.Border,
					TextColorStyle = Enum.StudioStyleGuideColor.ButtonText,

					Icon = {
						Image = minimizeIcon.Url,
						RectSize = minimizeIcon.ImageRectSize,
						RectOffset = minimizeIcon.ImageRectOffset,

						Size = minimizeIcon.ImageRectSize,
						Transparency = if props.Disabled then 0.7 else 0,
						UseThemeColor = true,
					},

					OnActivated = props.OnMinimize,
					Disabled = props.Disabled,
					LayoutOrder = 5,
				}),

				Spacing3 = props.OnMinimize and React.createElement("Frame", {
					Size = UDim2.new(0, 4, 1, 0),
					BackgroundTransparency = 1,
					LayoutOrder = 6,
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
						local success, _err = props.OnCapture(Rect.new(Vector2.zero, displaySize))
						if not success then
							makeShake(1, Vector2.new(7, 4), Vector2.new(4, 2))
							makeError(1.5, Vector2.new(7, 4), Vector2.new(0, 0))
						end
					end,
					Disabled = props.Disabled,
					LayoutOrder = 7,
				}),
			}),
		}),

		ErrorLabel = errorOffset.Z < 1 and React.createElement("TextLabel", {
			BackgroundTransparency = 1,
			Position = if useUnderFrame then UDim2.new(0, 0, 1, 2) else UDim2.new(0, 0, -1, -2),
			Size = UDim2.fromScale(1, 1),
			FontFace = Font.fromName("SourceSansPro", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
			Text = "Error: Check the output.",
			TextSize = 14,
			TextTransparency = errorOffset.Z ^ 20,
			TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.ErrorText),
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = if useUnderFrame then Enum.TextYAlignment.Top else Enum.TextYAlignment.Bottom,
		}, {
			UIStroke = React.createElement("UIStroke", {
				Thickness = 1,
				Transparency = errorOffset.Z ^ 20,
				Color = Color3.new(0, 0, 0),
			}),
		}),
		UnderFrame = React.createElement("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Position = UDim2.new(0, 0, 1, 2),
			ref = underFrameRef,
		}),
	})
end

local function InnerBorder(props: { Thickness: number, Padding: number, Disabled: boolean, children: React.ReactNode })
	local theme = StudioComponents.useTheme()

	return React.createElement("Frame", {
		Size = UDim2.new(1, -props.Thickness * 2, 1, -props.Thickness * 2),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
	}, {
		StrokeFrame = React.createElement("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ZIndex = 2,
		}, {
			UIStroke = React.createElement("UIStroke", {
				Thickness = props.Thickness,
				Transparency = 0,
				LineJoinMode = Enum.LineJoinMode.Miter,
				Color = theme:GetColor(
					Enum.StudioStyleGuideColor.InputFieldBorder,
					Enum.StudioStyleGuideModifier.Selected
				),
			}),
		}),
		ChildFrame = React.createElement("Frame", {
			Size = UDim2.new(1, -props.Padding * 2, 1, -props.Padding * 2),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			ZIndex = 1,
		}, props.children),
	})
end

local function FullViewport(props: Props)
	local isDragging, setIsDragging = React.useState(false)
	local containerRef = React.useRef(nil :: GuiObject?)
	local containerSize = Hooks.useRefProperty(containerRef, "AbsoluteSize", Vector2.zero)

	React.useEffect(function()
		props.FocusLenseSizeRef.current = containerSize
	end, { containerSize })

	local draggerSize = Vector2.new(120, 28)
	if props.OnMinimize then
		draggerSize = Vector2.new(148, 28)
	end

	local draggerScale = 1
	if containerSize.X < draggerSize.X * 2 or containerSize.Y < draggerSize.Y * 2 then
		draggerScale = math.min(containerSize.X / (draggerSize.X * 2), containerSize.Y / (draggerSize.Y * 2))
	end

	return React.createElement("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ref = containerRef,
	}, {
		Outline = React.createElement(InnerBorder, {
			Thickness = 2,
			Padding = 1,
			Disabled = false,
		}, {
			Dragger = React.createElement(FreeDrag, {
				SetIsDragging = setIsDragging,

				InitialPosition = UDim2.fromScale(0, 0),
				AnchorPoint = Vector2.new(0, 0),
				Size = UDim2.fromOffset(draggerSize.X, draggerSize.Y),

				Scale = draggerScale,

				Disabled = props.Disabled,
			}, {
				ActionBar = React.createElement(ActionBar, {
					IsDragging = isDragging,
					ContainerSize = containerSize,
					OnMinimize = props.OnMinimize,
					OnCapture = props.OnCapture,
					Disabled = props.Disabled,
				}),
			}),
		}),
	})
end

return FullViewport
