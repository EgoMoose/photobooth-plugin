--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local StudioComponents = require(pluginRoot.Packages.StudioComponents)
local React = require(pluginRoot.Packages.React)

local DescriptionTextInput = require(script.DescriptionTextInput)

export type Details = {
	Title: string,
	Description: string,
	EditableImage: EditableImage,
}

export type Props = {
	PlaceholderTitle: string,
	PlaceholderDescription: string,
	EditableImage: EditableImage,

	OnConfirm: (Details) -> (),
	OnCancel: () -> (),

	Disabled: boolean,
	ZIndex: number,
}

local function isBlankString(text: string)
	local noWhitespace = text:gsub("%s+", "")
	return #noWhitespace == 0
end

local function UploadDetails(props: Props)
	local theme = StudioComponents.useTheme()

	local titleText, setTitleText = React.useState("")
	local descriptionText, setDescriptionText = React.useState("")

	local size = props.EditableImage.Size
	local aspectRatio = size.X / size.Y

	return React.createElement(StudioComponents.Background, {
		Size = UDim2.fromScale(1, 1),
		ZIndex = props.ZIndex,
	}, {
		Upper = React.createElement("Frame", {
			Size = UDim2.new(1, 0, 1, -36),
			BackgroundTransparency = 1,
		}, {
			Image = React.createElement("Frame", {
				Size = UDim2.new(1, 0, 0.5, 0),
				BackgroundTransparency = 1,
			}, {
				Padding = React.createElement("UIPadding", {
					PaddingLeft = UDim.new(0, 8),
					PaddingRight = UDim.new(0, 8),
					PaddingTop = UDim.new(0, 8),
					PaddingBottom = UDim.new(0, 8),
				}),

				LabelContainer = React.createElement("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainBackground),
					BorderColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Border),
				}, {
					SizeConstraint = React.createElement("UISizeConstraint", {
						MaxSize = size,
					}),
					AspectConstraint = React.createElement("UIAspectRatioConstraint", {
						AspectType = Enum.AspectType.ScaleWithParentSize,
						DominantAxis = Enum.DominantAxis.Width,
						AspectRatio = aspectRatio,
					}),

					ImageLabel = props.EditableImage and React.createElement("ImageLabel", {
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.fromScale(0.5, 0.5),
						Size = UDim2.new(1, 0, 1, 0),
						BackgroundTransparency = 1,
						ImageContent = Content.fromObject(props.EditableImage),
					}),

					Grid = React.createElement("Frame", {
						Size = UDim2.fromScale(1, 1),
						BackgroundTransparency = 1,
						ClipsDescendants = true,
						ZIndex = 1,
					}, {
						Checkered = React.createElement("ImageLabel", {
							BackgroundTransparency = 1,
							Image = "rbxassetid://6032311304",
							ScaleType = Enum.ScaleType.Tile,
							TileSize = UDim2.fromOffset(50, 50),
							Size = UDim2.new(1, 100, 1, 100),
							Position = UDim2.fromOffset(-(size.X % 50) / 2, -(size.Y % 50) / 2),
							ImageColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Titlebar),
						}),
					}),
				}),
			}),
			Info = React.createElement("Frame", {
				AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.fromScale(0, 1),
				Size = UDim2.new(1, 0, 0.5, 0),
				BackgroundTransparency = 1,
			}, {
				Layout = React.createElement("UIListLayout", {
					SortOrder = Enum.SortOrder.LayoutOrder,
					FillDirection = Enum.FillDirection.Vertical,
					VerticalAlignment = Enum.VerticalAlignment.Top,
					HorizontalAlignment = Enum.HorizontalAlignment.Left,
					Padding = UDim.new(0, 4),
				}),
				Padding = React.createElement("UIPadding", {
					PaddingLeft = UDim.new(0, 12),
					PaddingRight = UDim.new(0, 4),
					PaddingTop = UDim.new(0, 4),
					PaddingBottom = UDim.new(0, 4),
				}),

				Title = React.createElement("Frame", {
					LayoutOrder = 1,
					Size = UDim2.new(1, 0, 0, 22),
					BackgroundTransparency = 1,
				}, {
					Label = React.createElement(StudioComponents.Label, {
						Disabled = props.Disabled,
						Text = "Title",
						TextXAlignment = Enum.TextXAlignment.Left,
						TextYAlignment = Enum.TextYAlignment.Top,
						Position = UDim2.fromOffset(0, 2),
						Size = UDim2.new(0, 68, 1, 0),
					}),
					Input = React.createElement(StudioComponents.TextInput, {
						Disabled = props.Disabled,
						Text = titleText,
						OnChanged = setTitleText,
						PlaceholderText = props.PlaceholderTitle,
						ClearTextOnFocus = false,
						AnchorPoint = Vector2.new(1, 0),
						Position = UDim2.fromScale(1, 0),
						Size = UDim2.new(1, -68, 1, 0),
					}),
				}),

				Description = React.createElement("Frame", {
					LayoutOrder = 2,
					Size = UDim2.new(1, 0, 1, -22 - 4),
					BackgroundTransparency = 1,
				}, {
					Label = React.createElement(StudioComponents.Label, {
						Disabled = props.Disabled,
						Text = "Description",
						TextXAlignment = Enum.TextXAlignment.Left,
						TextYAlignment = Enum.TextYAlignment.Top,
						Position = UDim2.fromOffset(0, 2),
						Size = UDim2.new(0, 68, 1, 0),
					}),
					Input = React.createElement(DescriptionTextInput, {
						Disabled = props.Disabled,
						Text = descriptionText,
						OnChanged = setDescriptionText,
						PlaceholderText = props.PlaceholderDescription,
						ClearTextOnFocus = false,
						AnchorPoint = Vector2.new(1, 0),
						Position = UDim2.fromScale(1, 0),
						Size = UDim2.new(1, -68, 1, 0),
					}),
				}),
			}),
		}),

		Lower = React.createElement("Frame", {
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.fromScale(0, 1),
			Size = UDim2.new(1, 0, 0, 36),
			BackgroundTransparency = 0,
			BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Titlebar),
			BorderColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Border),
		}, {
			Layout = React.createElement("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				FillDirection = Enum.FillDirection.Horizontal,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				HorizontalAlignment = Enum.HorizontalAlignment.Right,
				Padding = UDim.new(0, 4),
			}),
			Padding = React.createElement("UIPadding", {
				PaddingLeft = UDim.new(0, 4),
				PaddingRight = UDim.new(0, 4),
				PaddingTop = UDim.new(0, 4),
				PaddingBottom = UDim.new(0, 4),
			}),

			Confirm = React.createElement(StudioComponents.MainButton, {
				Disabled = props.Disabled,
				LayoutOrder = -1,
				Size = UDim2.fromOffset(80, 28),
				Text = "Confirm",
				OnActivated = function()
					props.OnConfirm({
						EditableImage = props.EditableImage,
						Title = if not isBlankString(titleText) then titleText else props.PlaceholderTitle,
						Description = if not isBlankString(descriptionText)
							then descriptionText
							else props.PlaceholderDescription,
					})
				end,
			}),
			Cancel = React.createElement(StudioComponents.Button, {
				Disabled = props.Disabled,
				LayoutOrder = -2,
				Size = UDim2.fromOffset(80, 28),
				Text = "Cancel",
				OnActivated = props.OnCancel,
			}),
		}),
	})
end

return UploadDetails
