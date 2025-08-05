--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local StudioComponents = require(pluginRoot.Packages.StudioComponents)
local React = require(pluginRoot.Packages.React)

local uiRoot = script:FindFirstAncestor("UserInterface")
local Hooks = require(uiRoot.Hooks)

export type Props = {
	Size: UDim2,
	Position: UDim2,
	AnchorPoint: Vector2,

	children: React.ReactNode,
}

local function useMouseScroll(step: number)
	local goalBinding, setGoal = React.useBinding(0)
	local springBinding, setSpring = Hooks.useSpring(goalBinding)
	local value = Hooks.useBindingState(springBinding)

	local increment = React.useCallback(function(stepAmt: number)
		setGoal(math.clamp(goalBinding:getValue() + stepAmt, 0, 1))
	end, {})

	return {
		value = value,
		onScrollForward = function()
			increment(step)
		end,
		onScrollBackward = function()
			increment(-step)
		end,
	}
end

local function useOffsetDragging()
	local offset, setOffset = React.useState(Vector2.zero)

	local dragState = React.useRef({
		start = Vector3.zero,
		offset = offset,
	})

	local dragger = Hooks.useMouseDrag({
		onBeganCallback = function(_, input)
			dragState.current = {
				start = input.Position,
				offset = offset,
			}
		end,
		onEndedCallback = function() end,
		onDragCallback = function(_, input)
			local delta3 = input.Position - dragState.current.start
			setOffset(dragState.current.offset + Vector2.new(delta3.X, delta3.Y))
		end,
	})

	return offset, dragger
end

local function ControlFrame(props: Props)
	local containerRef = React.useRef(nil)
	-- local containerSize = Hooks.useRefProperty(containerRef, "AbsoluteSize", Vector2.zero)

	-- local scroll = useMouseScroll(0.05)
	-- local scale = math.lerp(0, 2, scroll.value)
	-- local offset, dragger = useOffsetDragging()
	local scale = 0
	local offset = Vector2.zero

	return React.createElement("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ref = containerRef,
	}, {
		Input = React.createElement("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Active = false,
			ZIndex = 2,

			-- [React.Event.InputBegan] = dragger.onInputBegan :: any,
			-- [React.Event.InputChanged] = dragger.onInputChanged :: any,
			-- [React.Event.InputEnded] = dragger.onInputEnded :: any,

			-- [React.Event.MouseWheelForward] = scroll.onScrollForward :: any,
			-- [React.Event.MouseWheelBackward] = scroll.onScrollBackward :: any,
		}),

		Content = React.createElement("Frame", {
			BackgroundTransparency = 1,
			AnchorPoint = props.AnchorPoint,
			Position = props.Position + UDim2.fromOffset(offset.X, offset.Y),
			Size = props.Size + UDim2.fromScale(scale, scale),
		}, props.children),
	})
end

return ControlFrame
