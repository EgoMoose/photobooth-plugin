--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local StudioComponents = require(pluginRoot.Packages.StudioComponents)
local React = require(pluginRoot.Packages.React)

local uiRoot = script:FindFirstAncestor("UserInterface")
local Hooks = require(uiRoot.Hooks)
local Icons = require(uiRoot.Icons)

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

local function DisplayEditableImage(props: Props)
	local theme = StudioComponents.useTheme()
	local imgLabelRef = React.useRef(nil :: ImageLabel?)
	local openMenu = usePluginMenu(props.BackgroundType, props.SetBackgroundType)

	React.useEffect(function()
		local imgLabel = imgLabelRef.current
		if not imgLabel then
			return
		end

		imgLabel.ImageContent = Content.fromObject(props.EditableImage)
	end, { imgLabelRef.current, props.EditableImage } :: { any })

	local size = props.EditableImage.Size
	local aspectRatio = size.X / size.Y

	return React.createElement("Frame", {
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
			ImageLabel = React.createElement("ImageButton", {
				ZIndex = 2,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				ref = imgLabelRef,
				[React.Event.MouseButton2Click] = function()
					openMenu()
				end,
			}),
			SizeConstraint = React.createElement("UISizeConstraint", {
				MaxSize = size,
			}),
			AspectConstraint = React.createElement("UIAspectRatioConstraint", {
				AspectType = Enum.AspectType.ScaleWithParentSize,
				DominantAxis = Enum.DominantAxis.Width,
				AspectRatio = aspectRatio,
			}),
			OutlineStroke = React.createElement("UIStroke", {
				Thickness = 2,
				LineJoinMode = Enum.LineJoinMode.Miter,
				-- stylua: ignore
				Color = theme:GetColor(
					Enum.StudioStyleGuideColor.InputFieldBorder,
					Enum.StudioStyleGuideModifier.Selected
				),
			}),
			Dimensions = React.createElement("TextLabel", {
				Size = UDim2.new(1, 0, 0, 10),
				Position = UDim2.new(0, 0, 1, 4),
				BackgroundTransparency = 1,
				Text = ("%d x %d - %s"):format(size.X, size.Y, props.EditableImageName),
				TextScaled = true,
				TextTransparency = 0.7,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Bottom,
				TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText),
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
	})
end

return DisplayEditableImage
