--!strict

local TextService = game:GetService("TextService") :: TextService

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local StudioComponents = require(pluginRoot.Packages.StudioComponents)
local React = require(pluginRoot.Packages.React)

local uiRoot = script:FindFirstAncestor("UserInterface")
local ContainerSize = require(uiRoot.Components.Shared.ContainerSize)
local Hooks = require(uiRoot.Hooks)
local Icons = require(uiRoot.Icons)

local HighResImageSplit = require(script.Parent.HighResImageSplit)

local OUTLINE_THICKNESS = 2
local DIMENSIONS_FONT_SIZE = 7
local DIMENSIONS_FONT = Font.fromEnum(Enum.Font.Legacy)

export type Props = {
	AnchorPoint: Vector2,
	Position: UDim2,
	Size: UDim2,

	EditableImage: EditableImage,
	EditableImageName: string,

	BackgroundType: string,
	SetBackgroundType: (string) -> (),
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

local function useTextWidth(text: string, font: Font, size: number)
	local width, setWidth = React.useState(0)
	local ticket = React.useRef(0)

	React.useEffect(function()
		local params = Instance.new("GetTextBoundsParams")
		params.Text = text
		params.Font = font
		params.Size = size
		params.Width = math.huge

		ticket.current = ticket.current + 1
		local myTicket = ticket.current
		local size = TextService:GetTextBoundsAsync(params)

		if ticket.current == myTicket then
			setWidth(size.X)
		end
	end, { text, font, size } :: { any })

	return width
end

local function DisplayEditableImage(props: Props)
	local theme = StudioComponents.useTheme()
	local aspectFrameSize, setAspectFrameSize = React.useState(Vector2.zero)
	local openMenu = usePluginMenu(props.BackgroundType, props.SetBackgroundType)

	local size = props.EditableImage.Size
	local aspectRatio = size.X / size.Y

	local dimensionsText = ("%d x %d - %s"):format(size.X, size.Y, props.EditableImageName)
	local dimensionsTextWidth = useTextWidth(dimensionsText, DIMENSIONS_FONT, DIMENSIONS_FONT_SIZE)
	local isDimensionsAttachedToImage = dimensionsTextWidth < (aspectFrameSize.X + OUTLINE_THICKNESS * 2)

	return React.createElement("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		ImageContainer = React.createElement("Frame", {
			AnchorPoint = props.AnchorPoint,
			Position = props.Position,
			Size = props.Size,
			BackgroundTransparency = 1,
		}, {
			AspectFrame = React.createElement("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
			}, {
				SizeConstraint = React.createElement("UISizeConstraint", {
					MaxSize = size,
				}),
				AspectConstraint = React.createElement("UIAspectRatioConstraint", {
					AspectType = Enum.AspectType.ScaleWithParentSize,
					DominantAxis = Enum.DominantAxis.Width,
					AspectRatio = aspectRatio,
				}),
				Container = React.createElement(ContainerSize, {
					SetContainerSize = setAspectFrameSize,
				}, {
					ImageFrame = React.createElement("Frame", {
						ZIndex = 2,
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.fromScale(0.5, 0.5),
						Size = UDim2.fromScale(1, 1),
						BackgroundTransparency = 1,
					}, {
						RightClickButton = React.createElement("TextButton", {
							BorderSizePixel = 0,
							BackgroundTransparency = 1,
							Size = UDim2.fromScale(1, 1),
							Text = "",
							[React.Event.MouseButton2Click] = function()
								openMenu()
							end,
						}),
						HighResImageSplit = React.createElement(HighResImageSplit, {
							AnchorPoint = Vector2.new(0, 0),
							Size = UDim2.fromScale(1, 1),
							Position = UDim2.fromScale(0, 0),
							EditableImage = props.EditableImage,
							ZIndex = -1,
						}),
					}),

					OutlineStroke = React.createElement("UIStroke", {
						Thickness = OUTLINE_THICKNESS,
						LineJoinMode = Enum.LineJoinMode.Miter,
						-- stylua: ignore
						Color = theme:GetColor(
							Enum.StudioStyleGuideColor.InputFieldBorder,
							Enum.StudioStyleGuideModifier.Selected
						),
					}),
					AttachedDimensions = isDimensionsAttachedToImage and React.createElement("TextLabel", {
						Size = UDim2.new(1, OUTLINE_THICKNESS * 2, 0, 10),
						Position = UDim2.new(0, -OUTLINE_THICKNESS, 1, 4),
						BackgroundTransparency = 1,
						Text = dimensionsText,
						TextSize = DIMENSIONS_FONT_SIZE,
						TextTransparency = 0.7,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextYAlignment = Enum.TextYAlignment.Bottom,
						TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText),
						FontFace = DIMENSIONS_FONT,
					}),

					Background = React.createElement("Frame", {
						Size = UDim2.fromScale(1, 1),
						BackgroundTransparency = 1,
						ClipsDescendants = true,
						ZIndex = 1,
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
		}),

		UnattachedDimensions = not isDimensionsAttachedToImage and React.createElement("TextLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = dimensionsText,
			TextSize = DIMENSIONS_FONT_SIZE,
			TextWrapped = true,
			TextTransparency = 0.7,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Bottom,
			TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText),
			FontFace = DIMENSIONS_FONT,
		}),
	})
end

return DisplayEditableImage
