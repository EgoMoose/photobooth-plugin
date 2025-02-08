--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local React = require(pluginRoot.Packages.React)

local uiRoot = script:FindFirstAncestor("UserInterface")
local ContainerSize = require(uiRoot.Components.Shared.ContainerSize)
local Hooks = require(uiRoot.Hooks)

local isDraggingContext = React.createContext(false)

export type Props = {
	SetIsDragging: (boolean) -> (),

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

local function FreeDrag(props: Props & { ContainerSize: Vector2 })
	local position, setPosition = React.useState(props.InitialPosition)

	local containerSize = props.ContainerSize
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

	local isDragging = dragger.isActive()
	React.useEffect(function()
		if props.Disabled then
			dragger.cancel()
			props.SetIsDragging(false)
		else
			props.SetIsDragging(isDragging)
		end
	end, { isDragging })

	return React.createElement(isDraggingContext.Provider, {
		value = isDragging,
	}, {
		React.createElement("ImageButton", {
			Size = props.Size,
			Position = clampedPosition,
			BackgroundTransparency = 1,

			Image = "",
			AutoButtonColor = false,

			[React.Event.InputBegan] = dragger.onInputBegan,
			[React.Event.InputChanged] = dragger.onInputChanged,
			[React.Event.InputEnded] = dragger.onInputEnded,
		}, props.children),
	})
end

return function(props: Props)
	local containerSize, setContainerSize = React.useState(Vector2.zero)

	return React.createElement(ContainerSize, {
		SetContainerSize = setContainerSize,
	}, {
		FreeDrag = React.createElement(FreeDrag, {
			SetIsDragging = props.SetIsDragging,
			ContainerSize = containerSize,

			InitialPosition = props.InitialPosition,
			AnchorPoint = props.AnchorPoint,
			Size = props.Size,

			Disabled = props.Disabled,
		}, props.children),
	})
end
