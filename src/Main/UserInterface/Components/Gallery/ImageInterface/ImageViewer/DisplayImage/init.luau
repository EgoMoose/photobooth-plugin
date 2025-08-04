local pluginRoot = script:FindFirstAncestor("PluginRoot")
local StudioComponents = require(pluginRoot.Packages.StudioComponents)
local React = require(pluginRoot.Packages.React)

local uiRoot = script:FindFirstAncestor("UserInterface")
local Hooks = require(uiRoot.Hooks)
local Icons = require(uiRoot.Icons)

local HighResImageSplit = require(script.HighResImageSplit)

local OUTLINE_THICKNESS = 2
local DIMENSIONS_FONT_SIZE = 7
local DIMENSIONS_FONT = Font.fromEnum(Enum.Font.Legacy)

export type Props = {
	Size: UDim2,
	Position: UDim2,
	AnchorPoint: Vector2,

	Name: string,
	EditableImage: EditableImage,

	BackgroundType: string,
	SetBackgroundType: (string) -> (),

	Padding: {
		PaddingTop: UDim?,
		PaddingLeft: UDim?,
		PaddingRight: UDim?,
		PaddingBottom: UDim?,
	},
}

local function makeBackgroundTypeAction(text: string, backgroundType: string, setBackgroundType: (string) -> ())
	local renderText = text
	if text == backgroundType then
		renderText = `>  {text}`
	end

	return {
		Text = renderText,
		Icon = Icons.menu[text:lower()],
		OnTriggered = function()
			setBackgroundType(text)
		end,
	}
end

local function usePluginMenu(backgroundType: string, setBackgroundType: (string) -> ())
	return Hooks.usePluginMenu(React.useMemo(function()
		return {
			Title = "Photobooth",
			Icon = "",

			Actions = {
				makeBackgroundTypeAction("Checkerboard", backgroundType, setBackgroundType),
				makeBackgroundTypeAction("Black", backgroundType, setBackgroundType),
				makeBackgroundTypeAction("White", backgroundType, setBackgroundType),
				makeBackgroundTypeAction("None", backgroundType, setBackgroundType),
			},
		}
	end, { backgroundType, setBackgroundType } :: { any }))
end

local function DisplayImage(props: Props)
	local theme = StudioComponents.useTheme()
	local openMenu = usePluginMenu(props.BackgroundType, props.SetBackgroundType)

	local bottomLabel = React.useRef(nil :: TextLabel?)
	local bottomLabelTextFits = Hooks.useRefProperty(bottomLabel, "TextFits", true)

	local size = props.EditableImage.Size
	local aspectRatio = size.X / size.Y
	local dimensionsText = `{size.X} x {size.Y} - {props.Name}`

	return React.createElement("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = props.AnchorPoint,
		Position = props.Position,
		Size = props.Size,
	}, {
		Padded = React.createElement("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
		}, {
			Padding = React.createElement("UIPadding", {
				PaddingLeft = props.Padding.PaddingLeft,
				PaddingRight = props.Padding.PaddingRight,
				PaddingTop = props.Padding.PaddingTop,
				PaddingBottom = props.Padding.PaddingBottom,
			}),
			AspectContainer = React.createElement("Frame", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(1, 1),
			}, {
				SizeConstraint = React.createElement("UISizeConstraint", {
					MaxSize = size,
				}),
				AspectConstraint = React.createElement("UIAspectRatioConstraint", {
					AspectType = Enum.AspectType.ScaleWithParentSize,
					DominantAxis = Enum.DominantAxis.Width,
					AspectRatio = aspectRatio,
				}),

				ImageContainer = React.createElement("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(1, 1),
				}, {
					OutlineStroke = React.createElement("UIStroke", {
						Thickness = OUTLINE_THICKNESS,
						LineJoinMode = Enum.LineJoinMode.Miter,
						Color = theme:GetColor(
							Enum.StudioStyleGuideColor.InputFieldBorder,
							Enum.StudioStyleGuideModifier.Selected
						),
					}),
					AttachedDimensions = React.createElement("TextLabel", {
						Size = UDim2.new(1, OUTLINE_THICKNESS * 2, 0, 10),
						Position = UDim2.new(0, -OUTLINE_THICKNESS, 1, 4),
						BackgroundTransparency = 1,
						Text = dimensionsText,
						TextSize = DIMENSIONS_FONT_SIZE,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextYAlignment = Enum.TextYAlignment.Bottom,
						TextTruncate = Enum.TextTruncate.AtEnd,
						TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText),
						TextTransparency = if bottomLabelTextFits then 0.7 else 1,
						FontFace = DIMENSIONS_FONT,
						ref = bottomLabel,
					}),

					RightClickButton = React.createElement("TextButton", {
						BorderSizePixel = 0,
						BackgroundTransparency = 1,
						Size = UDim2.fromScale(1, 1),
						Text = "",
						ZIndex = 2,
						[React.Event.MouseButton2Click] = function()
							openMenu()
						end,
					}),
					HighResImage = React.createElement(HighResImageSplit, {
						Size = UDim2.fromScale(1, 1),
						Position = UDim2.fromScale(0, 0),
						AnchorPoint = Vector2.new(0, 0),

						EditableImage = props.EditableImage,
					}),
				}),

				BackgroundContrast = React.createElement("Frame", {
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					ClipsDescendants = true,
					ZIndex = -1,
				}, {
					Checkerboard = props.BackgroundType == "Checkerboard" and React.createElement("ImageLabel", {
						BackgroundTransparency = 1,
						Image = "rbxassetid://6032311304",
						ScaleType = Enum.ScaleType.Tile,
						TileSize = UDim2.fromOffset(50, 50),
						Size = UDim2.new(1, 100, 1, 100),
						Position = UDim2.fromOffset(-(size.X % 50) / 2, -(size.Y % 50) / 2),
						ImageColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Titlebar),
					}),

					Black = props.BackgroundType == "Black" and React.createElement("Frame", {
						BorderSizePixel = 0,
						BackgroundTransparency = 0,
						BackgroundColor3 = Color3.new(0, 0, 0),
						Size = UDim2.fromScale(1, 1),
					}),

					White = props.BackgroundType == "White" and React.createElement("Frame", {
						BorderSizePixel = 0,
						BackgroundTransparency = 0,
						BackgroundColor3 = Color3.new(1, 1, 1),
						Size = UDim2.fromScale(1, 1),
					}),
				}),
			}),
		}),

		UnattachedDimensions = not bottomLabelTextFits and React.createElement("TextLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = dimensionsText,
			TextSize = DIMENSIONS_FONT_SIZE,
			--TextWrapped = true,
			TextTransparency = 0.7,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Bottom,
			TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText),
			TextTruncate = Enum.TextTruncate.AtEnd,
			FontFace = DIMENSIONS_FONT,
			ZIndex = -1,
		}, {
			Padding = React.createElement("UIPadding", {
				PaddingLeft = UDim.new(0, 18),
				PaddingBottom = UDim.new(0, 3),
			}),
		}),
	})
end

return DisplayImage
