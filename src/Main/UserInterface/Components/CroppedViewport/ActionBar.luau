--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local StudioComponents = require(pluginRoot.Packages.StudioComponents)
local Lucide = require(pluginRoot.Packages.Lucide)
local React = require(pluginRoot.Packages.React)

local uiRoot = script:FindFirstAncestor("UserInterface")
local BaseButton = require(uiRoot.Components.Shared.BaseButton)
local Hooks = require(uiRoot.Hooks)

type Props = {
	AnchorPoint: Vector2,
	Position: UDim2,
	Size: UDim2,

	ViewportRect: Rect,
	DisplayRect: Rect,

	OnDimensionInput: (Vector2) -> (),

	UseRectText: boolean,
	OnRectInput: (Rect) -> (),

	OnMaximize: () -> (),
	OnCapture: () -> (boolean, string?),

	Disabled: boolean?,
}

type DimensionProps = {
	AnchorPoint: Vector2,
	Position: UDim2,
	Size: UDim2,

	UseRectText: boolean,
	DisplayRect: Rect,
	OnDimensionInput: (Vector2) -> (),
	OnRectInput: (Rect) -> (),

	Disabled: boolean?,
}

local function Dimensions(props: DimensionProps)
	local theme = StudioComponents.useTheme()
	local isRectTextFocused, setIsRectTextFocused = React.useState(false)
	local displayRectText = props.UseRectText or isRectTextFocused

	return React.createElement("Frame", {
		AnchorPoint = props.AnchorPoint,
		Position = props.Position,
		Size = props.Size,
		BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.InputFieldBackground),
		BorderColor3 = theme:GetColor(Enum.StudioStyleGuideColor.InputFieldBorder),
		BorderMode = Enum.BorderMode.Inset,
	}, {
		SizeInput = not displayRectText and React.createElement("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
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

					FontFace = Font.fromName("SourceSansPro"),
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

				FontFace = Font.fromName("SourceSansPro"),
				TextColor3 = Color3.fromRGB(102, 102, 102),
				TextXAlignment = Enum.TextXAlignment.Right,
				TextYAlignment = Enum.TextYAlignment.Center,
				TextSize = 14,
				Text = tostring(props.DisplayRect.Width),

				[React.Event.FocusLost] = function(rbx, _enterPressed)
					local dimension = tonumber(rbx.Text)
					if dimension then
						dimension = math.floor(dimension)
						props.OnDimensionInput(Vector2.new(dimension, props.DisplayRect.Height))
					end
					rbx.Text = tostring(props.DisplayRect.Width)
				end,
			}),

			Height = React.createElement("TextBox", {
				Size = UDim2.new(0.5, -7, 1, 0),
				BackgroundTransparency = 1,
				LayoutOrder = 3,

				FontFace = Font.fromName("SourceSansPro"),
				TextColor3 = Color3.fromRGB(102, 102, 102),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Center,
				TextSize = 14,
				Text = tostring(props.DisplayRect.Height),

				[React.Event.FocusLost] = function(rbx, _enterPressed)
					local dimension = tonumber(rbx.Text)
					if dimension then
						dimension = math.floor(dimension)
						props.OnDimensionInput(Vector2.new(props.DisplayRect.Width, dimension))
					end
					rbx.Text = tostring(props.DisplayRect.Height)
				end,
			}),
		}),

		RectInput = displayRectText and React.createElement("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
		}, {
			Padding = React.createElement("UIPadding", {
				PaddingLeft = UDim.new(0, 2),
				PaddingRight = UDim.new(0, 2),
				PaddingTop = UDim.new(0, 0),
				PaddingBottom = UDim.new(0, 0),
			}),

			RectBox = React.createElement("TextBox", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,

				FontFace = Font.fromName("SourceSansPro"),
				TextColor3 = Color3.fromRGB(102, 102, 102),
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
				ClearTextOnFocus = false,
				ClipsDescendants = true,
				TextScaled = true,
				Text = tostring(props.DisplayRect),

				[React.Event.FocusLost] = function(rbx: TextBox, _enterPressed: boolean)
					local components = {}
					for i, section in rbx.Text:gsub("%s+", ""):split(",") do
						components[i] = tonumber(section)
					end

					if #components == 4 then
						local minX = components[1]
						local minY = components[2]
						local maxX = components[3]
						local maxY = components[4]

						if minX and minY and maxX and maxY then
							props.OnRectInput(Rect.new(minX, minY, maxX, maxY))
						end
					end
					rbx.Text = tostring(props.DisplayRect)
					setIsRectTextFocused(false)
				end,

				[React.Event.Focused] = function()
					setIsRectTextFocused(true)
				end,
			}),
		}),
	})
end

local function ActionBar(props: Props)
	local theme = StudioComponents.useTheme()
	local cameraIcon = assert(Lucide.GetAsset("camera", 16))
	local maximizeIcon = assert(Lucide.GetAsset("maximize", 16))

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

	return React.createElement("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = props.AnchorPoint,
		Position = props.Position,
		Size = props.Size,
	}, {
		ShakeFrame = React.createElement("Frame", {
			Size = UDim2.fromScale(1, 1),
			Position = UDim2.fromOffset(shakeOffset.X, shakeOffset.Y),
			BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainBackground),
			BorderColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Border),
		}, {
			Overlay = shakeOffset.Z < 1 and React.createElement("Frame", {
				Active = false,
				BackgroundTransparency = math.lerp(0.6, 1, shakeOffset.Z ^ 2),
				BackgroundColor3 = overlayColor,
				Size = UDim2.fromScale(1, 1),
				ZIndex = 2,
			}),
			Content = React.createElement("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
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
					Size = UDim2.new(1, -28 * 2, 1, 0),

					UseRectText = props.UseRectText,
					DisplayRect = props.DisplayRect,
					OnDimensionInput = props.OnDimensionInput,
					OnRectInput = props.OnRectInput,

					Disabled = props.Disabled,
				}),

				Maximize = React.createElement(BaseButton, {
					AnchorPoint = Vector2.new(1, 0),
					Position = UDim2.new(1, -24 - 4, 0, 0),
					Size = UDim2.new(0, 24, 1, 0),

					BackgroundColorStyle = Enum.StudioStyleGuideColor.Button,
					BorderColorStyle = Enum.StudioStyleGuideColor.Border,
					TextColorStyle = Enum.StudioStyleGuideColor.ButtonText,

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

					OnActivated = function()
						local success, _err = props.OnCapture()
						if not success then
							makeShake(1, Vector2.new(7, 4), Vector2.new(4, 2))
							makeError(1.5, Vector2.new(7, 4), Vector2.new(0, 0))
						end
					end,
					Disabled = props.Disabled,
				}),
			}),
		}),

		ErrorLabel = errorOffset.Z < 1 and React.createElement("TextLabel", {
			BackgroundTransparency = 1,
			Position = if useUnderFrame then UDim2.new(0, 0, 1, 2) else UDim2.new(1, 8, 0, 0),
			Size = UDim2.fromScale(1, 1),
			FontFace = Font.fromName("SourceSansPro", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
			Text = "Error: Check the studio output (Window > Output)",
			TextSize = 14,
			TextTransparency = errorOffset.Z ^ 20,
			TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.ErrorText),
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Center, --if useUnderFrame then Enum.TextXAlignment.Center else Enum.TextXAlignment.Left,
			TextYAlignment = if useUnderFrame then Enum.TextYAlignment.Top else Enum.TextYAlignment.Center,
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

return React.memo(ActionBar)
