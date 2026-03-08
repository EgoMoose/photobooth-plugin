--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local StudioComponents = require(pluginRoot.Packages.StudioComponents)
local Lucide = require(pluginRoot.Packages.Lucide)
local React = require(pluginRoot.Packages.React)

local uiRoot = script:FindFirstAncestor("UserInterface")
local LucideButton = require(uiRoot.Components.Shared.LucideButton)
local Hooks = require(uiRoot.Hooks)

local OUTLINE_THICKNESS = 1
local COPY_BUTTON_ICON = assert(Lucide.GetAsset("square-check-big", 16))
local CANCEL_BUTTON_ICON = assert(Lucide.GetAsset("circle-x", 16))

type Props = {
	AnchorPoint: Vector2,
	Position: UDim2,
	Size: UDim2,

	Name: string,
	EditableImage: EditableImage,

	AssetId: number?,
	Progress: number,
	StatusText: string?,
	OnCancel: () -> (),

	LayoutOrder: number,
	Disabled: boolean,
}

type ProgressBarProps = {
	AnchorPoint: Vector2,
	Position: UDim2,
	Size: UDim2,
	Value: number,
	Disabled: boolean,
}

local function ProgressBar(props: ProgressBarProps)
	local theme = StudioComponents.useTheme()

	local modifier = Enum.StudioStyleGuideModifier.Default
	if props.Disabled then
		modifier = Enum.StudioStyleGuideModifier.Disabled
	end

	return React.createElement("Frame", {
		AnchorPoint = props.AnchorPoint,
		Position = props.Position,
		Size = props.Size,

		BackgroundColor3 = if props.Disabled
			then theme:GetColor(Enum.StudioStyleGuideColor.DialogMainButton, modifier)
			else theme:GetColor(Enum.StudioStyleGuideColor.InputFieldBackground),
		BorderSizePixel = 0,
	}, {
		UICorner = React.createElement("UICorner", {
			CornerRadius = UDim.new(1, 0),
		}),

		Clipped = React.createElement("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(props.Value, 1),
			Visible = props.Value > 0,
			ClipsDescendants = true,
		}, {
			Bar = React.createElement("Frame", {
				BorderSizePixel = 0,
				BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.DialogMainButton, modifier),
				Size = UDim2.fromScale(1 / props.Value, 1),
			}, {
				UICorner = React.createElement("UICorner", {
					CornerRadius = UDim.new(1, 0),
				}),
			}),
		}),
	})
end

local function getImageButtonColor(theme: StudioTheme, modifier: Enum.StudioStyleGuideModifier?)
	if modifier == Enum.StudioStyleGuideModifier.Selected then
		return theme:GetColor(Enum.StudioStyleGuideColor.ButtonText, Enum.StudioStyleGuideModifier.Pressed)
	elseif modifier == Enum.StudioStyleGuideModifier.Hover then
		return theme:GetColor(Enum.StudioStyleGuideColor.ButtonText, Enum.StudioStyleGuideModifier.Hover)
	end
	return theme:GetColor(Enum.StudioStyleGuideColor.ButtonText, Enum.StudioStyleGuideModifier.Disabled)
end

local function CopyButton(props: { Text: string })
	local theme = StudioComponents.useTheme()
	local textBoxRef = React.useRef(nil :: TextBox?)
	local textBounds = Hooks.useRefProperty(textBoxRef, "TextBounds", Vector2.zero)

	local hovered, setHovered = React.useState(false)
	local pressed, setPressed = React.useState(false)
	local modifier = Enum.StudioStyleGuideModifier.Default
	if pressed or hovered then
		modifier = Enum.StudioStyleGuideModifier.Hover
	end

	React.useEffect(function()
		local textBox = textBoxRef.current
		if not textBox then
			return
		end

		local cursorChanged = textBox:GetPropertyChangedSignal("CursorPosition"):Connect(function()
			local cursorPosition = string.len(textBox.Text) + 1
			if textBox:IsFocused() and textBox.CursorPosition ~= cursorPosition then
				textBox.CursorPosition = cursorPosition
			end
		end)

		local selectionStartChanged = textBox:GetPropertyChangedSignal("SelectionStart"):Connect(function()
			if textBox:IsFocused() and textBox.SelectionStart ~= 1 then
				textBox.SelectionStart = 1
			end
		end)

		return function()
			cursorChanged:Disconnect()
			selectionStartChanged:Disconnect()
		end
	end, {})

	return React.createElement("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ClipsDescendants = true,
	}, {
		Button = React.createElement("ImageButton", {
			ZIndex = 2,
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.fromScale(1, 0),
			Size = UDim2.new(0, textBounds.X + 6 + COPY_BUTTON_ICON.ImageRectSize.X, 1),

			[React.Event.InputBegan] = function(_, input: InputObject)
				if input.UserInputType == Enum.UserInputType.MouseMovement then
					setHovered(true)
				elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
					setPressed(true)
					if textBoxRef.current then
						textBoxRef.current:CaptureFocus()
					end
				end
			end,
			[React.Event.InputEnded] = function(_, input: InputObject)
				if input.UserInputType == Enum.UserInputType.MouseMovement then
					setHovered(false)
				elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
					setPressed(false)
				end
			end,
		}),

		Icon = React.createElement("ImageLabel", {
			BackgroundTransparency = 1,

			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.fromScale(1, 0),
			Size = UDim2.fromOffset(COPY_BUTTON_ICON.ImageRectSize.X, COPY_BUTTON_ICON.ImageRectSize.Y),

			Image = COPY_BUTTON_ICON.Url,
			ImageRectSize = COPY_BUTTON_ICON.ImageRectSize,
			ImageRectOffset = COPY_BUTTON_ICON.ImageRectOffset,
			ImageColor3 = getImageButtonColor(theme, modifier),
		}),

		TextBox = React.createElement("TextBox", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -COPY_BUTTON_ICON.ImageRectSize.X, 0, 0),
			Size = UDim2.new(1, -COPY_BUTTON_ICON.ImageRectSize.X, 0, COPY_BUTTON_ICON.ImageRectSize.Y),

			Interactable = false,
			ClearTextOnFocus = false,
			TextEditable = false,

			Text = props.Text,
			TextColor3 = getImageButtonColor(theme, modifier),
			TextSize = StudioComponents.Constants.DefaultTextSize,
			TextXAlignment = Enum.TextXAlignment.Right,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Font = StudioComponents.Constants.DefaultFont,

			[React.Event.Focused] = function(rbx: TextBox)
				rbx.CursorPosition = string.len(rbx.Text) + 1
				rbx.SelectionStart = 1
				rbx.Interactable = true
			end,
			[React.Event.FocusLost] = function(rbx: TextBox)
				rbx.Interactable = false
			end,

			ref = textBoxRef,
		}, {
			Padding = React.createElement("UIPadding", {
				PaddingLeft = UDim.new(0, 0),
				PaddingRight = UDim.new(0, 6),
				PaddingTop = UDim.new(0, 0),
				PaddingBottom = UDim.new(0, 0),
			}),
		}),
	})
end

local function UploadLineItem(props: Props)
	local theme = StudioComponents.useTheme()

	local uploadPercentGoal, setUploadPercentGoal = React.useBinding(props.Progress)
	local uploadPercentBinding, setUploadPercent = Hooks.useSpring(uploadPercentGoal)
	local uploadPercent = Hooks.useBindingState(uploadPercentBinding)

	React.useEffect(function()
		setUploadPercentGoal(props.Progress)
		if props.Progress == 0 then
			setUploadPercent(props.Progress)
		end
	end, { props.Progress })

	return React.createElement("Frame", {
		AnchorPoint = props.AnchorPoint,
		Position = props.Position,
		Size = props.Size,

		BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Titlebar),
		BorderColor3 = theme:GetColor(Enum.StudioStyleGuideColor.DialogButtonBorder),

		LayoutOrder = props.LayoutOrder,
	}, {
		Padding = React.createElement("UIPadding", {
			PaddingLeft = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 8),
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

		LayoutIndex = React.createElement(StudioComponents.Label, {
			LayoutOrder = 1,
			Size = UDim2.new(0, 24, 1, 0),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			Text = `{props.LayoutOrder}.`,
		}),

		ImageContainer = React.createElement("Frame", {
			LayoutOrder = 2,
			Size = UDim2.fromScale(1, 1),
			SizeConstraint = Enum.SizeConstraint.RelativeYY,
			BackgroundTransparency = 1,
		}, {
			ThicknessContainer = React.createElement("Frame", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.new(1, -OUTLINE_THICKNESS * 2, 1, -OUTLINE_THICKNESS * 2),
			}, {
				AspectContainer = React.createElement("Frame", {
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.fromScale(1, 1),
				}, {
					AspectConstraint = React.createElement("UIAspectRatioConstraint", {
						AspectType = Enum.AspectType.ScaleWithParentSize,
						DominantAxis = Enum.DominantAxis.Width,
						AspectRatio = props.EditableImage.Size.X / props.EditableImage.Size.Y,
					}),
					OutlineStroke = React.createElement("UIStroke", {
						Thickness = OUTLINE_THICKNESS,
						LineJoinMode = Enum.LineJoinMode.Miter,
						Color = theme:GetColor(
							Enum.StudioStyleGuideColor.InputFieldBorder,
							Enum.StudioStyleGuideModifier.Selected
						),
					}),

					ImageLabel = React.createElement("ImageLabel", {
						BackgroundTransparency = 1,
						Size = UDim2.fromScale(1, 1),
						ImageContent = Content.fromObject(props.EditableImage),
					}),
				}),
			}),
		}),

		Details = React.createElement("Frame", {
			LayoutOrder = 3,
			BackgroundTransparency = 1,
			Size = UDim2.new(1 - props.Size.Y.Scale, -props.Size.Y.Offset - 24, 0, 4 + 16 + 6),
		}, {
			Padded = React.createElement("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, -8, 1, 0),
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.fromScale(1, 0),
			}, {
				Top = React.createElement("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 1, -4),
				}, {
					TitleLabel = React.createElement(StudioComponents.Label, {
						Size = UDim2.fromScale(0.5, 1),
						TextXAlignment = Enum.TextXAlignment.Left,
						TextYAlignment = Enum.TextYAlignment.Top,
						TextTruncate = Enum.TextTruncate.AtEnd,
						Text = props.Name,
					}),

					RightCorner = React.createElement("Frame", {
						BackgroundTransparency = 1,
						AnchorPoint = Vector2.new(1, 0),
						Position = UDim2.fromScale(1, 0),
						Size = UDim2.fromScale(0.5, 1),
					}, {
						StatusLabel = props.StatusText and React.createElement("TextLabel", {
							BackgroundTransparency = 1,
							AnchorPoint = Vector2.new(1, 0),
							Position = UDim2.fromScale(1, 0),
							Size = UDim2.new(1, 0, 0, StudioComponents.Constants.DefaultTextSize),

							Text = props.StatusText,
							TextXAlignment = Enum.TextXAlignment.Right,
							TextColor3 = getImageButtonColor(theme, Enum.StudioStyleGuideModifier.Default),
							TextSize = StudioComponents.Constants.DefaultTextSize,
							Font = StudioComponents.Constants.DefaultFont,
						}),

						CopyButton = not props.StatusText and props.AssetId and React.createElement(CopyButton, {
							Text = `rbxassetid://{props.AssetId}`,
						}),

						CancelButton = not props.StatusText
							and not props.AssetId
							and React.createElement(LucideButton, {
								AnchorPoint = Vector2.new(1, 0),
								Position = UDim2.fromScale(1, 0),
								Size = UDim2.fromOffset(
									CANCEL_BUTTON_ICON.ImageRectSize.X,
									CANCEL_BUTTON_ICON.ImageRectSize.Y
								),

								Icon = CANCEL_BUTTON_ICON,
								GetColor = function(modifier)
									return getImageButtonColor(theme, modifier)
								end,

								OnActivated = function()
									props.OnCancel()
								end,
							}),
					}),
				}),

				Bottom = React.createElement("Frame", {
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(0, 1),
					Position = UDim2.fromScale(0, 1),
					Size = UDim2.new(1, 0, 0, 4),
				}, {
					Progress = React.createElement(ProgressBar, {
						AnchorPoint = Vector2.new(0, 0),
						Position = UDim2.fromScale(0, 0),
						Size = UDim2.fromScale(1, 1),

						Value = uploadPercent,
						Disabled = props.Disabled,
					}),
				}),
			}),
		}),
	})
end

return UploadLineItem
