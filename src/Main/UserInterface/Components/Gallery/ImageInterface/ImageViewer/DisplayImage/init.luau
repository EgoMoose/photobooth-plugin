local pluginRoot = script:FindFirstAncestor("PluginRoot")
local StudioComponents = require(pluginRoot.Packages.StudioComponents)
local React = require(pluginRoot.Packages.React)
local Constants = require(pluginRoot.Constants)

local uiRoot = script:FindFirstAncestor("UserInterface")
local Hooks = require(uiRoot.Hooks)
local Icons = require(uiRoot.Icons)

local useImageControls = require(script.Parent.Parent.useImageControls)
local HighResImageSplit = require(script.HighResImageSplit)

local OUTLINE_THICKNESS = 2
local DIMENSIONS_FONT_SIZE = 7
local DIMENSIONS_FONT = Font.fromEnum(Enum.Font.Legacy)

local CONTROLS_ENABLED = Constants.GalleryImageControlsEnabled

export type Props = {
	Size: UDim2,
	Position: UDim2,
	AnchorPoint: Vector2,

	Name: string,
	EditableImage: EditableImage,

	BackgroundType: string,
	SetBackgroundType: (string) -> (),

	ImageControls: useImageControls.ImageControls,
	ViewerRef: { current: GuiObject? },
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
			Title = "Photobooth_Gallery_Alpha_Background",
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

	local controls = props.ImageControls

	local size = props.EditableImage.Size
	local dimensionsText = `{size.X} x {size.Y} - {props.Name}`

	local zoom = controls.zoom
	local imageCenter = controls.imageCenter
	local fitScale = controls.fitScale

	local imageLayerSize = UDim2.fromScale(zoom * fitScale.X, zoom * fitScale.Y)
	local imageLayerPosition = UDim2.fromScale(imageCenter.X, imageCenter.Y)

	return React.createElement("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ClipsDescendants = true,
		ref = props.ViewerRef,
	}, {
		Inner = React.createElement("Frame", {
			BackgroundTransparency = 1,
			AnchorPoint = props.AnchorPoint,
			Position = props.Position,
			Size = props.Size,
		}, {
			ImageLayer = React.createElement("Frame", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = imageLayerSize,
				Position = imageLayerPosition,
			}, {
				StrokeFrame = React.createElement("Frame", {
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
				}),

				BackgroundContrast = React.createElement("Frame", {
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					ClipsDescendants = true,
					ZIndex = -1,
				}, {
					Checkerboard = props.BackgroundType == "Checkerboard" and React.createElement("ImageLabel", {
						BackgroundTransparency = 1,
						Image = Icons.misc.checkerboard,
						ScaleType = Enum.ScaleType.Tile,
						TileSize = UDim2.fromOffset(50, 50),
						Size = UDim2.new(1, 100, 1, 100),
						Position = UDim2.fromOffset(-50, -50),
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

				HighResImage = React.createElement(HighResImageSplit, {
					Size = UDim2.fromScale(1, 1),
					Position = UDim2.fromScale(0, 0),
					AnchorPoint = Vector2.new(0, 0),

					EditableImage = props.EditableImage,
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
			}),

			InputLayer = React.createElement("TextButton", {
				BorderSizePixel = 0,
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				Text = "",
				AutoButtonColor = false,
				ZIndex = 2,

				[React.Event.InputBegan] = if CONTROLS_ENABLED then controls.dragger.onInputBegan else nil,
				[React.Event.InputChanged] = if CONTROLS_ENABLED then controls.onInputChanged else nil,
				[React.Event.InputEnded] = if CONTROLS_ENABLED then controls.dragger.onInputEnded else nil,
				[React.Event.MouseButton2Click] = function()
					openMenu()
				end,
			}),
		}),

		UnattachedDimensions = not bottomLabelTextFits and React.createElement("TextLabel", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.fromScale(1, 0),
			Size = UDim2.new(1, -16, 1, 0),
			BackgroundTransparency = 1,
			Text = dimensionsText,
			TextSize = DIMENSIONS_FONT_SIZE,
			TextTransparency = 0.7,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Bottom,
			TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText),
			TextTruncate = Enum.TextTruncate.AtEnd,
			FontFace = DIMENSIONS_FONT,
			ZIndex = 3,
		}, {
			Padding = React.createElement("UIPadding", {
				PaddingLeft = UDim.new(0, 3),
				PaddingRight = UDim.new(0, 3),
				PaddingBottom = UDim.new(0, 4),
			}),
		}),
	})
end

return DisplayImage
