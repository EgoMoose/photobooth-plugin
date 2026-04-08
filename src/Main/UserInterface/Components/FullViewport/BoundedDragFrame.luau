--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local React = require(pluginRoot.Packages.React)

local uiRoot = script:FindFirstAncestor("UserInterface")
local Hooks = require(uiRoot.Hooks)

export type Props = {
	InitialPosition: UDim2?,
	AnchorPoint: Vector2?,
	Size: UDim2?,

	Scale: number,

	Disabled: boolean?,
	children: React.Node,
}

local function udim2ToAbs(udim2: UDim2, parentSize: Vector2)
	return Vector2.new(udim2.X.Scale * parentSize.X + udim2.X.Offset, udim2.Y.Scale * parentSize.Y + udim2.Y.Offset)
end

local function BoundedDragFrame(props: Props & { BoundsRect: Rect })
	local position, setPosition = React.useState(props.InitialPosition)
	local anchorPoint = props.AnchorPoint or Vector2.zero
	local size = props.Size or UDim2.new(0, 0, 0, 0)

	local boundsSize = Vector2.new(props.BoundsRect.Width, props.BoundsRect.Height)
	local deltaAbsAnchorPosition = udim2ToAbs(position, boundsSize) * props.Scale
	local absSize = udim2ToAbs(size, boundsSize) * props.Scale
	local deltaAbsPosition = (deltaAbsAnchorPosition - anchorPoint * absSize)

	local clampedAbsPosition = Vector2.new(
		math.clamp(deltaAbsPosition.X, 0, math.max(0, boundsSize.X - absSize.X)),
		math.clamp(deltaAbsPosition.Y, 0, math.max(0, boundsSize.Y - absSize.Y))
	)

	local dragStart = React.useRef(nil :: { input: Vector3, position: UDim2 }?)
	local dragger = Hooks.useMouseDrag({
		onDragCallback = function(_rbx, input)
			if dragStart.current then
				local delta3 = (input.Position - dragStart.current.input) / props.Scale
				setPosition(dragStart.current.position + UDim2.fromOffset(delta3.X, delta3.Y))
			end
		end,
		onBeganCallback = function(_rbx, input)
			dragStart.current = {
				input = input.Position,
				position = UDim2.fromOffset(clampedAbsPosition.X / props.Scale, clampedAbsPosition.Y / props.Scale),
			}
		end,
		onEndedCallback = function()
			dragStart.current = nil
		end,
	})

	return React.createElement("ImageButton", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(clampedAbsPosition.X, clampedAbsPosition.Y),
		Size = props.Size,

		Image = "",
		AutoButtonColor = false,

		[React.Event.InputBegan] = dragger.onInputBegan,
		[React.Event.InputChanged] = dragger.onInputChanged,
		[React.Event.InputEnded] = dragger.onInputEnded,
	}, {
		UIScale = props.Scale ~= 1 and React.createElement("UIScale", {
			Scale = props.Scale,
		}),
	}, props.children)
end

return function(props: Props)
	local boundFrameRef = React.useRef(nil)
	local boundFrameAbsSize = Hooks.useRefProperty(boundFrameRef, "AbsoluteSize", Vector2.zero)
	local boundFrameAbsPosition = Hooks.useRefProperty(boundFrameRef, "AbsolutePosition", Vector2.zero)
	local boundsRect = Rect.new(boundFrameAbsPosition, boundFrameAbsPosition + boundFrameAbsSize)

	return React.createElement("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Active = false,
		ref = boundFrameRef,
	}, {
		Core = React.createElement(BoundedDragFrame, {
			BoundsRect = boundsRect,
			InitialPosition = props.InitialPosition,
			AnchorPoint = props.AnchorPoint,
			Size = props.Size,
			Scale = props.Scale,
			Disabled = props.Disabled,
		}, props.children),
	})
end
