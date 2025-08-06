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

	ImageSize: Vector2,

	children: React.ReactNode,
}

local function useMouseScroll(step: number)
	local goalBinding, setGoal = React.useBinding(0)
	local springBinding, setSpring = Hooks.useSpring(goalBinding, { tension = 300, friction = 50 })
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
		onDragCallback = function(_, input)
			local delta3 = input.Position - dragState.current.start
			setOffset(dragState.current.offset + Vector2.new(delta3.X, delta3.Y))
		end,
	})

	return offset, dragger
end

local function ControlFrame(props: Props)
	local lenseRef = React.useRef(nil)
	local lenseSize = Hooks.useRefProperty(lenseRef, "AbsoluteSize", Vector2.zero):Ceil()

	local scroll = useMouseScroll(0.05)
	local scale = 1 / (1 - math.lerp(0, 0.9, scroll.value))
	local offset, dragger = useOffsetDragging()

	return React.createElement("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	}, {
		Input = React.createElement("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Active = false,
			ZIndex = 2,

			[React.Event.InputBegan] = dragger.onInputBegan :: any,
			[React.Event.InputChanged] = dragger.onInputChanged :: any,
			[React.Event.InputEnded] = dragger.onInputEnded :: any,

			[React.Event.MouseWheelForward] = scroll.onScrollForward :: any,
			[React.Event.MouseWheelBackward] = scroll.onScrollBackward :: any,
		}),

		Content = React.createElement("Frame", {
			BackgroundTransparency = 1,
			AnchorPoint = props.AnchorPoint,
			Position = props.Position,
			Size = props.Size,
		}, {
			Scaled = React.createElement("Frame", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(scale, scale),
			}, props.children),
		}),

		Unscaled = React.createElement("Frame", {
			BackgroundTransparency = 1,
			AnchorPoint = props.AnchorPoint,
			Position = props.Position,
			Size = props.Size,
			ZIndex = -1,
		}, {
			AspectContainer = React.createElement("Frame", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(1, 1),
				ref = lenseRef,
			}, {
				SizeConstraint = React.createElement("UISizeConstraint", {
					MaxSize = props.ImageSize,
				}),
				AspectConstraint = React.createElement("UIAspectRatioConstraint", {
					AspectType = Enum.AspectType.ScaleWithParentSize,
					DominantAxis = Enum.DominantAxis.Width,
					AspectRatio = React.useMemo(function()
						return props.ImageSize.X / props.ImageSize.Y
					end, { props.ImageSize }),
				}),
			}),
		}),
	})
end

return ControlFrame
