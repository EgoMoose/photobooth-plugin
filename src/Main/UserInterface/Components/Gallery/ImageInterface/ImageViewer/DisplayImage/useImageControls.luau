--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local React = require(pluginRoot.Packages.React)
local Trove = require(pluginRoot.Packages.Trove)

local uiRoot = script:FindFirstAncestor("UserInterface")
local Hooks = require(uiRoot.Hooks)

local MIN_ZOOM_PIXELS = 20

local function translateRect(rect: Rect, offset: Vector2)
	return Rect.new(rect.Min + offset, rect.Max + offset)
end

local function scaleRect(rect: Rect, scale: number, anchorPoint: Vector2)
	local anchor = rect.Min + Vector2.new(rect.Width, rect.Height) * anchorPoint
	-- stylua: ignore
	return Rect.new(
		(anchor + (rect.Min - anchor) * scale):Floor(),
		(anchor + (rect.Max - anchor) * scale):Ceil()
	)
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

local function useImageControls2(size: Vector2, inputRef: { current: GuiObject? }, aspectRef: { current: GuiObject? })
	local rectBind, setRect = React.useBinding(Rect.new(Vector2.zero, size))
	local zoomPercentBind, setZoomPercent = React.useBinding(1)

	React.useEffect(function()
		local trove = Trove.new()
		local inputFrame = inputRef.current :: GuiObject
		local aspectFrame = aspectRef.current :: GuiObject

		setZoomPercent(aspectFrame.AbsoluteSize.X / size.X)
		setRect(scaleRect(rectBind:getValue(), zoomPercentBind:getValue(), Vector2.new(0.5, 0.5)))

		trove:Add(aspectFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			setZoomPercent(aspectFrame.AbsoluteSize.X / size.X)
			setRect(scaleRect(Rect.new(Vector2.zero, size), zoomPercentBind:getValue(), Vector2.new(0.5, 0.5)))
		end))

		local isDragging = false
		local prevDragPosition = Vector3.zero
		trove:Add(inputFrame.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				isDragging = true
				prevDragPosition = input.Position
			end
		end))

		trove:Add(inputFrame.InputChanged:Connect(function(input)
			if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
				local delta3 = input.Position - prevDragPosition
				prevDragPosition = input.Position

				local scale = aspectFrame.AbsoluteSize / size
				local scaledDelta = Vector2.new(-delta3.X, -delta3.Y) / scale

				setRect(clampRect(translateRect(rectBind:getValue(), scaledDelta), size))
			elseif input.UserInputType == Enum.UserInputType.MouseWheel then
				setZoomPercent(zoomPercentBind:getValue() + input.Position.Z * 0.05)
			end
		end))

		trove:Add(inputFrame.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				isDragging = false
			end
		end))

		return trove:WrapClean()
	end, { size })

	local rect = Hooks.useBindingState(rectBind)
	local zoom = Hooks.useBindingState(zoomPercentBind)

	return Rect.new(rect.Min / size, rect.Max / size)
end

local function useImageControls(size: Vector2, inputRef: { current: GuiObject? }, aspectRef: { current: GuiObject? })
	local inputPosition = Hooks.useRefProperty(inputRef, "AbsolutePosition", Vector2.zero)
	local inputSize = Hooks.useRefProperty(inputRef, "AbsoluteSize", Vector2.zero)
	local inputScale = math.min(inputSize.X / size.X, inputSize.Y / size.Y)

	local aspectSize = Hooks.useRefProperty(aspectRef, "AbsoluteSize", Vector2.zero)

	local scaleBind, setScale = React.useBinding(1)

	local rectBind, setRect = React.useBinding(Rect.new(Vector2.zero, size))
	local rect = Hooks.useBindingState(rectBind)

	local state = React.useRef({
		position = Vector3.zero,
	})

	local dragger = Hooks.useMouseDrag({
		deps = { size, inputScale } :: { any },
		onBeganCallback = function(_rbx, input)
			state.current.position = input.Position
		end,
		onDragCallback = function(_rbx, input)
			local delta = input.Position - state.current.position
			state.current.position = input.Position

			local scaledDelta = (Vector2.new(-delta.X, -delta.Y) / inputScale) / scaleBind:getValue()
			setRect(clampRect(translateRect(rectBind:getValue(), scaledDelta), size))
		end,
	})

	local incrementZoom = React.useCallback(function(delta: number)
		local prevScale = scaleBind:getValue()
		setScale(math.clamp(prevScale + delta, 1E-6, 8))

		print(scaleBind:getValue())

		local scaledRect = scaleRect(rectBind:getValue(), prevScale / scaleBind:getValue(), Vector2.new(0.5, 0.5))
		local translatedRect = scaledRect --translateRect(scaledRect, offset)
		setRect(clampRect(translatedRect, size))
	end, { size })

	local reset = React.useCallback(function()
		dragger.cancel()
		setRect(Rect.new(Vector2.zero, size))
	end, { size, aspectSize })

	local scaledRect = Rect.new(rect.Min / size, rect.Max / size)

	return {
		rect = scaledRect,

		onInputBegan = function(rbx: GuiObject, input: InputObject)
			dragger.onInputBegan(rbx, input)
		end,
		onInputChanged = function(rbx: GuiObject, input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseWheel then
				local relative = Vector2.new(input.Position.X, input.Position.Y) - inputPosition
				local fromCenter = relative - inputSize / 2
				incrementZoom(input.Position.Z * 0.05)
			end
			dragger.onInputChanged(rbx, input)
		end,
		onInputEnded = function(rbx: GuiObject, input: InputObject)
			dragger.onInputEnded(rbx, input)
		end,

		reset = reset,
	}
end

return useImageControls2
