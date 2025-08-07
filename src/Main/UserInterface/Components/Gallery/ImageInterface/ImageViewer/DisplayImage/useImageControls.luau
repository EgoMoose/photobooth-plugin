--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local React = require(pluginRoot.Packages.React)

local uiRoot = script:FindFirstAncestor("UserInterface")
local Hooks = require(uiRoot.Hooks)

local MIN_ZOOM_PIXELS = 20

local function translateRect(rect: Rect, offset: Vector2)
	return Rect.new(rect.Min + offset, rect.Max + offset)
end

local function scaleRect(rect: Rect, scale: number, anchorPoint: Vector2)
	local anchor = rect.Min + Vector2.new(rect.Width, rect.Height) * anchorPoint
	return Rect.new(anchor + (rect.Min - anchor) * scale, anchor + (rect.Max - anchor) * scale)
end

local function clampRect(rect: Rect, size: Vector2)
	local minX, maxX, width = rect.Min.X, rect.Max.X, rect.Width
	local minY, maxY, height = rect.Min.Y, rect.Max.Y, rect.Height

	if width >= size.X then
		minX, maxX = 0, size.X
	else
		maxX = math.min(size.X, math.max(0, minX) + width)
		minX = maxX - width
	end

	if height >= size.Y then
		minY, maxY = 0, size.Y
	else
		maxY = math.min(size.Y, math.max(0, minY) + height)
		minY = maxY - height
	end

	return Rect.new(minX, minY, maxX, maxY)
end

local function useImageControls(size: Vector2, inputRef: { current: GuiObject? })
	local inputSize = Hooks.useRefProperty(inputRef, "AbsoluteSize", Vector2.zero)
	local inputScale = inputSize / size

	local rectBind, setRect = React.useBinding(Rect.new(Vector2.zero, size))
	local rect = Hooks.useBindingState(rectBind)

	local state = React.useRef({
		zoom = 0,
		scale = 1,
	})

	local dragger = Hooks.useMouseDrag({
		deps = { size, inputScale },
		onDragCallback = function(_rbx, input)
			local delta = Vector2.new(-input.Delta.X, -input.Delta.Y)
			local scaledDelta = (delta / inputScale) / state.current.scale
			setRect(clampRect(translateRect(rectBind:getValue(), scaledDelta), size))
		end,
	})

	local incrementZoom = React.useCallback(function(zoom: number)
		state.current.zoom = math.clamp(state.current.zoom + zoom, 0, 1)

		local minAxis = math.min(size.X, size.Y)
		local scale = minAxis / math.max(MIN_ZOOM_PIXELS, math.lerp(minAxis, MIN_ZOOM_PIXELS, state.current.zoom))

		local scaledRect = scaleRect(rectBind:getValue(), state.current.scale / scale, Vector2.new(0.5, 0.5))
		setRect(clampRect(scaledRect, size))

		state.current.scale = scale
	end, { size })

	local reset = React.useCallback(function()
		dragger.cancel()
		state.current.zoom = 0
		state.current.scale = 1
		setRect(Rect.new(Vector2.zero, size))
	end, {})

	return {
		rect = Rect.new(rect.Min / size, rect.Max / size),

		onInputBegan = dragger.onInputBegan,
		onInputChanged = dragger.onInputChanged,
		onInputEnded = dragger.onInputEnded,

		onZoomIn = function()
			incrementZoom(0.01)
		end,
		onZoomOut = function()
			incrementZoom(-0.01)
		end,

		reset = reset,
	}
end

return useImageControls
