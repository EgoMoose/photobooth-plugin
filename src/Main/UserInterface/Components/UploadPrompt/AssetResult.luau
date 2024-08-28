--!strict

local TextService = game:GetService("TextService") :: TextService

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local StudioComponents = require(pluginRoot.Packages.StudioComponents)
local Lucide = require(pluginRoot.Packages.Lucide)
local React = require(pluginRoot.Packages.React)

export type Props = {
	AssetId: number?,
	ErrorMsg: string?,
	OnConfirm: () -> (),
	Disabled: boolean,
	ZIndex: number,
}

type EasyCopyTextProps = {
	Text: string,
	Height: number,
	LayoutOrder: number,
	Disabled: boolean,
}

local function getTextSize(text: string)
	local size = TextService:GetTextSize(
		text,
		StudioComponents.Constants.DefaultTextSize,
		StudioComponents.Constants.DefaultFont,
		Vector2.new(math.huge, math.huge)
	)
	return Vector2.new(math.ceil(size.X), math.ceil(size.Y)) + Vector2.one
end

local function EasyCopyText(props: EasyCopyTextProps)
	local theme = StudioComponents.useTheme()
	local textBoxRef = React.useRef(nil :: TextBox?)

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
	end, { textBoxRef })

	local textWidth = getTextSize(props.Text).X
	local copyIcon = assert(Lucide.GetAsset("copy", 16))

	local modifier = Enum.StudioStyleGuideModifier.Default
	if props.Disabled then
		modifier = Enum.StudioStyleGuideModifier.Disabled
	end

	return React.createElement("Frame", {
		Size = UDim2.new(0, textWidth + 4 + 16, 0, props.Height),
		BackgroundTransparency = 1,
		LayoutOrder = props.LayoutOrder,
	}, {
		TextBox = React.createElement("TextBox", {
			Size = UDim2.new(0, textWidth, 1, 0),
			BackgroundTransparency = 1,
			Interactable = false,
			ClearTextOnFocus = false,
			TextEditable = false,
			Text = props.Text,
			TextSize = StudioComponents.Constants.DefaultTextSize,
			Font = StudioComponents.Constants.DefaultFont,
			TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.LinkText, modifier),
			[React.Event.Focused] = function(rbx: TextBox)
				rbx.CursorPosition = string.len(rbx.Text) + 1
				rbx.SelectionStart = 1
				rbx.Interactable = true
			end,
			[React.Event.FocusLost] = function(rbx: TextBox)
				rbx.Interactable = false
			end,
			ref = textBoxRef,
		}),
		Icon = React.createElement("ImageButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.fromScale(1, 0.5),
			Size = UDim2.fromOffset(copyIcon.ImageRectSize.X, copyIcon.ImageRectSize.Y),
			SizeConstraint = Enum.SizeConstraint.RelativeYY,
			BackgroundTransparency = 1,
			Image = copyIcon.Url,
			ImageRectSize = copyIcon.ImageRectSize,
			ImageRectOffset = copyIcon.ImageRectOffset,
			ImageColor3 = theme:GetColor(Enum.StudioStyleGuideColor.TitlebarText, modifier),
			[React.Event.Activated] = function()
				if textBoxRef.current then
					textBoxRef.current:CaptureFocus()
				end
			end,
		}),
	})
end

local function AssetResult(props: Props)
	local theme = StudioComponents.useTheme()

	return React.createElement("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.7,
		ZIndex = props.ZIndex,
	}, {
		Container = React.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(200, 150),
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
				FillDirection = Enum.FillDirection.Vertical,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				Padding = UDim.new(0, 8),
			}),

			Title = React.createElement(StudioComponents.Label, {
				LayoutOrder = 1,
				TextColorStyle = Enum.StudioStyleGuideColor.TitlebarText,
				Size = UDim2.new(1, 0, 0, StudioComponents.Constants.DefaultTextSize),
				Text = "Asset Details",
			}),

			Body = React.createElement("Frame", {
				LayoutOrder = 2,
				Size = UDim2.new(1, -8, 1, -(StudioComponents.Constants.DefaultTextSize + 28 + 8 * 2)),
				BackgroundTransparency = 0,
				BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainBackground),
				BorderColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Border),
			}, {
				ErrorMsg = props.ErrorMsg and React.createElement(React.Fragment, {}, {
					Label = React.createElement(StudioComponents.Label, {
						TextColorStyle = Enum.StudioStyleGuideColor.ErrorText,
						Size = UDim2.fromScale(1, 1),
						Text = `Error: {props.ErrorMsg}`,
					}),
				}),

				Links = props.AssetId and React.createElement(React.Fragment, {}, {
					Layout = React.createElement("UIListLayout", {
						SortOrder = Enum.SortOrder.LayoutOrder,
						FillDirection = Enum.FillDirection.Vertical,
						VerticalAlignment = Enum.VerticalAlignment.Center,
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						Padding = UDim.new(0, 8),
					}),

					ContentURI = React.createElement(EasyCopyText, {
						LayoutOrder = 1,
						Height = 16,
						Text = `rbxassetid://{props.AssetId}`,
						Disabled = props.Disabled,
					}),

					CreatorStoreLink = React.createElement(EasyCopyText, {
						LayoutOrder = 2,
						Height = 16 * 2,
						Text = `https://create.roblox.com\n/store/asset/{props.AssetId}`,
						Disabled = props.Disabled,
					}),
				}),
			}),

			Confirm = React.createElement(StudioComponents.MainButton, {
				LayoutOrder = 3,
				Size = UDim2.fromOffset(80, 28),
				Text = "Confirm",
				OnActivated = props.OnConfirm,
				Disabled = props.Disabled,
			}),
		}),
	})
end

return AssetResult
