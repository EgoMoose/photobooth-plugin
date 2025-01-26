--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local React = require(pluginRoot.Packages.React)

local uiRoot = script:FindFirstAncestor("UserInterface")
local Hooks = require(uiRoot.Hooks)

local containerSizeContext = React.createContext(Vector2.new(0, 0))
local isDraggingContext = React.createContext(false)

export type Props = {
	InitialPosition: UDim2,
	AnchorPoint: Vector2,
	Size: UDim2,

	Disabled: boolean,
	children: React.ReactNode,
}

local function convertToAbsSize(udim2: UDim2, containerSize: Vector2)
	return Vector2.new(
		udim2.X.Scale * containerSize.X + udim2.X.Offset,
		udim2.Y.Scale * containerSize.Y + udim2.Y.Offset
	)
end

local function useContainerSize()
	return React.useContext(containerSizeContext)
end

local function useIsDragging()
	return React.useContext(isDraggingContext)
end

local function FreeDrag(props: Props)
	local containerSize = useContainerSize()
	local position, setPosition = React.useState(props.InitialPosition)

	local absSize = convertToAbsSize(props.Size, containerSize)
	local absAnchorPosition = convertToAbsSize(position, containerSize)
	local absAnchorSize = props.AnchorPoint * absSize
	local absPosition = absAnchorPosition - absAnchorSize

	local clampedPosition = UDim2.fromOffset(
		math.clamp(absPosition.X, 0, math.max(0, containerSize.X - absSize.X)),
		math.clamp(absPosition.Y, 0, math.max(0, containerSize.Y - absSize.Y))
	)

	local dragStart = React.useRef(nil :: { input: Vector3, position: UDim2 }?)
	local dragger = Hooks.useMouseDrag({
		onDragCallback = function(_rbx, input)
			if dragStart.current then
				local delta3 = input.Position - dragStart.current.input
				setPosition(dragStart.current.position + UDim2.fromOffset(delta3.X, delta3.Y))
			end
		end,
		onBeganCallback = function(_rbx, input)
			dragStart.current = {
				input = input.Position,
				position = clampedPosition + UDim2.fromOffset(absAnchorSize.X, absAnchorSize.Y),
			}
		end,
	})

	local isDragging = React.useMemo(dragger.isActive)

	return React.createElement(isDraggingContext.Provider, {
		value = isDragging,
	}, {
		React.createElement("TextButton", {
			Size = props.Size,
			Position = clampedPosition,
			BackgroundTransparency = 1,

			AutoButtonColor = false,
			Text = "",

			[React.Event.InputBegan] = dragger.onInputBegan,
			[React.Event.InputChanged] = dragger.onInputChanged,
			[React.Event.InputEnded] = dragger.onInputEnded,
		}, props.children),
	})
end

local function FreeDragComponent(props: Props)
	local containerSize, setContainerSize = React.useState(Vector2.new(0, 0))
	local containerRef = React.useRef(nil :: GuiObject?)

	React.useEffect(function()
		local frame = containerRef.current :: GuiObject
		setContainerSize(frame.AbsoluteSize)

		local connection = frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			setContainerSize(frame.AbsoluteSize)
		end)

		return function()
			connection:Disconnect()
		end
	end, { containerRef.current })

	return React.createElement("Frame", {
		Name = "ViewportSizeFrame",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ref = containerRef,
	}, {
		React.createElement(containerSizeContext.Provider, {
			value = containerSize,
		}, {
			React.createElement(FreeDrag, props),
		}),
	})
end

return {
	Component = FreeDragComponent,
	useContainerSize = useContainerSize,
	useIsDragging = useIsDragging,
}
