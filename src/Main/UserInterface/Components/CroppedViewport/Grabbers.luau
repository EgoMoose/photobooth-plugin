--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local React = require(pluginRoot.Packages.React)

local uiRoot = script:FindFirstAncestor("UserInterface")
local Hooks = require(uiRoot.Hooks)

-- stylua: ignore
type OnDragCallback = (
	direction: Vector2,
	delta: Vector2
) -> ()

export type Props = {
	Transparency: number,
	Thickness: UDim,
	Padding: UDim,
	Length: UDim,

	TranslateEnabled: boolean,
	CornersEnabled: boolean,
	MiddlesEnabled: boolean,

	OnDrag: OnDragCallback,
	OnDragStart: OnDragCallback,
	-- OnDragFinish: () -> (),

	Disabled: boolean?,
}

type GenericGrabberProps = {
	RootProps: Props,
	AnchorPoint: Vector2,
	Disabled: boolean?,
}

type GrabberProps = GenericGrabberProps & {
	Color: Color3,
	Direction: Vector2,
	OnInputBegan: (GuiObject, InputObject) -> (),
	OnInputChanged: (GuiObject, InputObject) -> (),
	OnInputEnded: (GuiObject, InputObject) -> (),
}

local function GrabCorner(props: GrabberProps)
	local signX = props.Direction.X
	local signY = props.Direction.Y

	return React.createElement("Frame", {
		AnchorPoint = props.AnchorPoint,
		Position = UDim2.fromScale(props.AnchorPoint.X, props.AnchorPoint.Y),
		Size = UDim2.new(
			props.RootProps.Length.Scale,
			props.RootProps.Length.Offset,
			props.RootProps.Length.Scale,
			props.RootProps.Length.Offset
		),
		BackgroundTransparency = 1,
	}, {
		Corner = React.createElement("ImageButton", {
			AutoButtonColor = false,
			AnchorPoint = props.AnchorPoint,
			Position = UDim2.fromScale(props.AnchorPoint.X, props.AnchorPoint.Y),
			Size = UDim2.new(
				props.RootProps.Thickness.Scale,
				props.RootProps.Thickness.Offset,
				props.RootProps.Thickness.Scale,
				props.RootProps.Thickness.Offset
			),
			BackgroundTransparency = props.RootProps.Transparency,
			BackgroundColor3 = props.Color,
			BorderSizePixel = 0,

			[React.Event.InputBegan] = if props.RootProps then props.OnInputBegan else nil,
			[React.Event.InputChanged] = if props.RootProps then props.OnInputChanged else nil,
			[React.Event.InputEnded] = if props.RootProps then props.OnInputEnded else nil,
		}),
		Vertical = React.createElement("ImageButton", {
			AutoButtonColor = false,
			AnchorPoint = props.AnchorPoint,
			Position = UDim2.new(
				props.AnchorPoint.X,
				0,
				props.AnchorPoint.Y + props.RootProps.Thickness.Scale * -signY,
				props.RootProps.Thickness.Offset * -signY
			),
			Size = UDim2.new(
				props.RootProps.Thickness.Scale,
				props.RootProps.Thickness.Offset,
				1 - props.RootProps.Thickness.Scale,
				-props.RootProps.Thickness.Offset
			),
			BackgroundTransparency = props.RootProps.Transparency,
			BackgroundColor3 = props.Color,
			BorderSizePixel = 0,

			[React.Event.InputBegan] = if props.RootProps then props.OnInputBegan else nil,
			[React.Event.InputChanged] = if props.RootProps then props.OnInputChanged else nil,
			[React.Event.InputEnded] = if props.RootProps then props.OnInputEnded else nil,
		}),
		Horizontal = React.createElement("ImageButton", {
			AutoButtonColor = false,
			AnchorPoint = props.AnchorPoint,
			Position = UDim2.new(
				props.AnchorPoint.X + props.RootProps.Thickness.Scale * -signX,
				props.RootProps.Thickness.Offset * -signX,
				props.AnchorPoint.Y,
				0
			),
			Size = UDim2.new(
				1 - props.RootProps.Thickness.Scale,
				-props.RootProps.Thickness.Offset,
				props.RootProps.Thickness.Scale,
				props.RootProps.Thickness.Offset
			),
			BackgroundTransparency = props.RootProps.Transparency,
			BackgroundColor3 = props.Color,
			BorderSizePixel = 0,

			[React.Event.InputBegan] = if props.RootProps then props.OnInputBegan else nil,
			[React.Event.InputChanged] = if props.RootProps then props.OnInputChanged else nil,
			[React.Event.InputEnded] = if props.RootProps then props.OnInputEnded else nil,
		}),
	})
end

local function GrabCardinal(props: GrabberProps)
	local isHorizontal = (math.abs(props.Direction.X) == 1)
	local width = if isHorizontal then props.RootProps.Thickness else props.RootProps.Length
	local height = if isHorizontal then props.RootProps.Length else props.RootProps.Thickness

	return React.createElement("ImageButton", {
		AutoButtonColor = false,
		AnchorPoint = props.AnchorPoint,
		Position = UDim2.fromScale(props.AnchorPoint.X, props.AnchorPoint.Y),
		Size = UDim2.new(width.Scale, width.Offset, height.Scale, height.Offset),
		BackgroundTransparency = props.RootProps.Transparency,
		BackgroundColor3 = props.Color,
		BorderSizePixel = 0,

		[React.Event.InputBegan] = if props.RootProps then props.OnInputBegan else nil,
		[React.Event.InputChanged] = if props.RootProps then props.OnInputChanged else nil,
		[React.Event.InputEnded] = if props.RootProps then props.OnInputEnded else nil,
	})
end

local function GrabDragger(props: GenericGrabberProps)
	local isCorner = not (props.AnchorPoint.X == 0.5 or props.AnchorPoint.Y == 0.5)
	-- stylua: ignore
	local direction = Vector2.new(
		(2 * props.AnchorPoint.X) - 1,
		(2 * props.AnchorPoint.Y) - 1
	)

	local initialDragRef = React.useRef(nil :: Vector3?)
	local dragger = Hooks.useMouseDrag({
		onDragCallback = function(_rbx, input)
			if initialDragRef.current then
				local delta3 = input.Position - initialDragRef.current
				local delta2 = Vector2.new(delta3.X, delta3.Y)
				props.RootProps.OnDrag(direction, delta2)
			end
		end,
		onBeganCallback = function(_rbx, input)
			initialDragRef.current = input.Position
			props.RootProps.OnDragStart(direction, Vector2.zero)
		end,
		onEndedCallback = function()
			initialDragRef.current = nil
		end,
		deps = { props.RootProps.OnDrag, props.RootProps.OnDragStart },
	})

	if props.Disabled and dragger.isActive() then
		dragger.cancel()
	end

	local color = Color3.fromRGB(255, 255, 255)
	if props.Disabled or dragger.isActive() then
		color = Color3.fromRGB(60, 60, 60)
	end

	return React.createElement(if isCorner then GrabCorner else GrabCardinal, {
		RootProps = props.RootProps,
		AnchorPoint = props.AnchorPoint,
		Color = color,
		Direction = direction,
		OnInputBegan = dragger.onInputBegan,
		OnInputChanged = dragger.onInputChanged,
		OnInputEnded = dragger.onInputEnded,
	})
end

local function TranslateDragger(props: GenericGrabberProps)
	-- stylua: ignore
	local direction = Vector2.new(
		(2 * props.AnchorPoint.X) - 1,
		(2 * props.AnchorPoint.Y) - 1
	)

	local initialDragRef = React.useRef(nil :: Vector3?)
	local dragger = Hooks.useMouseDrag({
		onDragCallback = function(_rbx, input)
			if initialDragRef.current then
				local delta3 = input.Position - initialDragRef.current
				local delta2 = Vector2.new(delta3.X, delta3.Y)
				props.RootProps.OnDrag(direction, delta2)
			end
		end,
		onBeganCallback = function(_rbx, input)
			initialDragRef.current = input.Position
			props.RootProps.OnDragStart(direction, Vector2.zero)
		end,
		onEndedCallback = function()
			initialDragRef.current = nil
		end,
		deps = { props.RootProps.OnDrag, props.RootProps.OnDragStart },
	})

	if props.Disabled and dragger.isActive() then
		dragger.cancel()
	end

	return React.createElement("ImageButton", {
		BackgroundTransparency = 1,
		AnchorPoint = props.AnchorPoint,
		Position = UDim2.fromScale(props.AnchorPoint.X, props.AnchorPoint.Y),
		Size = UDim2.fromScale(1, 1),

		[React.Event.InputBegan] = dragger.onInputBegan,
		[React.Event.InputChanged] = dragger.onInputChanged,
		[React.Event.InputEnded] = dragger.onInputEnded,
	})
end

local function Grabbers(props: Props)
	local gap = props.Thickness + props.Padding

	return React.createElement("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	}, {
		Gapped = React.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(1 + gap.Scale * 2, gap.Offset * 2, 1 + gap.Scale * 2, gap.Offset * 2),
			BackgroundTransparency = 1,
			ZIndex = -1,
		}, {
			TopLeft = props.CornersEnabled and React.createElement(GrabDragger, {
				AnchorPoint = Vector2.new(0, 0),
				RootProps = props,
			}),
			TopMiddle = props.MiddlesEnabled and React.createElement(GrabDragger, {
				AnchorPoint = Vector2.new(0.5, 0),
				RootProps = props,
			}),
			TopRight = props.CornersEnabled and React.createElement(GrabDragger, {
				AnchorPoint = Vector2.new(1, 0),
				RootProps = props,
			}),
			RightMiddle = props.MiddlesEnabled and React.createElement(GrabDragger, {
				AnchorPoint = Vector2.new(1, 0.5),
				RootProps = props,
			}),
			BottomRight = props.CornersEnabled and React.createElement(GrabDragger, {
				AnchorPoint = Vector2.new(1, 1),
				RootProps = props,
			}),
			BottomMiddle = props.MiddlesEnabled and React.createElement(GrabDragger, {
				AnchorPoint = Vector2.new(0.5, 1),
				RootProps = props,
			}),
			BottomLeft = props.CornersEnabled and React.createElement(GrabDragger, {
				AnchorPoint = Vector2.new(0, 1),
				RootProps = props,
			}),
			LeftMiddle = props.MiddlesEnabled and React.createElement(GrabDragger, {
				AnchorPoint = Vector2.new(0, 0.5),
				RootProps = props,
			}),
		}),

		Translate = props.TranslateEnabled and React.createElement(TranslateDragger, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			RootProps = props,
		}),
	})
end

return Grabbers
