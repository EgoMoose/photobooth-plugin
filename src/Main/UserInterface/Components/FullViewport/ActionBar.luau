--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local StudioComponents = require(pluginRoot.Packages.StudioComponents)
local Lucide = require(pluginRoot.Packages.Lucide)
local React = require(pluginRoot.Packages.React)

local uiRoot = script:FindFirstAncestor("UserInterface")
local BaseButton = require(uiRoot.Components.Shared.BaseButton)
local Hooks = require(uiRoot.Hooks)

export type Props = {
	ViewportRect: Rect,
	OnMinimize: () -> (),
	OnCapture: (Rect) -> (boolean, string?),
	Disabled: boolean?,
}

local function ActionBar(props: Props)
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
	local useUnderFrame = underFrameBottomY <= props.ViewportRect.Max.Y

	local shakeOffset, makeShake = Hooks.useShake()
	local errorOffset, makeError = Hooks.useShake()

	local overlayColor = React.useMemo(function()
		return theme
			:GetColor(Enum.StudioStyleGuideColor.MainBackground)
			:Lerp(theme:GetColor(Enum.StudioStyleGuideColor.ErrorText), 0.2)
	end, { theme })

	-- stylua: ignore
	local displaySize = Vector2.new(
		math.round(scaleOS.X * props.ViewportRect.Width),
		math.round(scaleOS.Y * props.ViewportRect.Height)
	)

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
					Size = UDim2.new(1, -78, 1, 0),
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

				Minimize = React.createElement(BaseButton, {
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
			Text = "Error: Check the studio output (Window > Output)",
			TextSize = 14,
			TextTransparency = errorOffset.Z ^ 20,
			TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.ErrorText),
			TextWrapped = true,
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

return ActionBar
