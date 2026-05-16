local pluginRoot = script:FindFirstAncestor("PluginRoot")
local React = require(pluginRoot.Packages.React)

local uiRoot = script:FindFirstAncestor("UserInterface")
local Hooks = require(uiRoot.Hooks)

local MIN_VIEW_PIXELS = 8
local WHEEL_ZOOM_FACTOR = 1.2

local CENTER = Vector2.new(0.5, 0.5)

export type ImageControls = {
	zoom: number,
	imageCenter: Vector2,
	fitScale: Vector2,
	maxZoom: number,
	hasImage: boolean,
	reset: () -> (),
	zoomBy: (factor: number, focalUV: Vector2?) -> (),
	setZoomLevel: (newZoom: number) -> (),
	dragger: {
		onInputBegan: (GuiObject, InputObject) -> (),
		onInputChanged: (GuiObject, InputObject) -> (),
		onInputEnded: (GuiObject, InputObject) -> (),
		cancel: () -> (),
		isActive: () -> boolean,
	},
	onInputChanged: (GuiObject, InputObject) -> (),
}

local function computeFitScale(imageSize: Vector2, viewportSize: Vector2): Vector2
	if viewportSize.X <= 0 or viewportSize.Y <= 0 or imageSize.X <= 0 or imageSize.Y <= 0 then
		return Vector2.new(1, 1)
	end
	local scaleX = imageSize.X / viewportSize.X
	local scaleY = imageSize.Y / viewportSize.Y
	local overflow = math.max(scaleX, scaleY)
	if overflow <= 1 then
		return Vector2.new(scaleX, scaleY)
	end
	return Vector2.new(scaleX / overflow, scaleY / overflow)
end

local function clampCenter(center: Vector2, zoomLevel: number, fitScale: Vector2): Vector2
	local halfX = 0.5 * zoomLevel * fitScale.X
	local halfY = 0.5 * zoomLevel * fitScale.Y
	local x = if halfX >= 0.5 then math.clamp(center.X, 1 - halfX, halfX) else 0.5
	local y = if halfY >= 0.5 then math.clamp(center.Y, 1 - halfY, halfY) else 0.5
	return Vector2.new(x, y)
end

local function useImageControls(editableImage: EditableImage?, viewportRef: { current: GuiObject? }): ImageControls
	local imageSize = if editableImage then editableImage.Size else Vector2.one

	local viewportSize = Hooks.useRefProperty(viewportRef, "AbsoluteSize", Vector2.zero)
	local fitScale = computeFitScale(imageSize, viewportSize)

	local maxZoom = 1
	if editableImage then
		local limitX = imageSize.X / fitScale.X
		local limitY = imageSize.Y / fitScale.Y
		maxZoom = math.max(1, math.min(limitX, limitY) / MIN_VIEW_PIXELS)
	end

	local zoom, setZoom = React.useState(1)
	local imageCenter, setImageCenter = React.useState(CENTER)

	local zoomRef = React.useRef(zoom)
	local centerRef = React.useRef(imageCenter)
	local viewportSizeRef = React.useRef(viewportSize)
	local fitScaleRef = React.useRef(fitScale)

	zoomRef.current = zoom
	centerRef.current = imageCenter
	viewportSizeRef.current = viewportSize
	fitScaleRef.current = fitScale

	local function setCenter(newCenter: Vector2)
		local clamped = clampCenter(newCenter, zoomRef.current, fitScaleRef.current)
		centerRef.current = clamped
		setImageCenter(clamped)
	end

	local function setZoomLevel(newZoom: number)
		local z = math.clamp(newZoom, 1, maxZoom)
		zoomRef.current = z
		setZoom(z)
		setCenter(centerRef.current)
	end

	local function reset()
		zoomRef.current = 1
		centerRef.current = CENTER
		setZoom(1)
		setImageCenter(CENTER)
	end

	React.useEffect(function()
		reset()
	end, { editableImage } :: { any })

	React.useEffect(function()
		local clamped = clampCenter(centerRef.current, zoomRef.current, fitScale)
		if clamped ~= centerRef.current then
			centerRef.current = clamped
			setImageCenter(clamped)
		end
	end, { fitScale.X, fitScale.Y } :: { any })

	local function zoomBy(factor: number, focalUV: Vector2?)
		local z = zoomRef.current
		local newZoom = math.clamp(z * factor, 1, maxZoom)
		if newZoom == z then
			return
		end

		local newCenter = centerRef.current
		if focalUV then
			newCenter = focalUV - (focalUV - centerRef.current) * (newZoom / z)
		end
		newCenter = clampCenter(newCenter, newZoom, fitScaleRef.current)

		zoomRef.current = newZoom
		centerRef.current = newCenter
		setZoom(newZoom)
		setImageCenter(newCenter)
	end

	local dragStart = React.useRef({
		screen = Vector2.zero,
		center = CENTER,
	})

	local dragger = Hooks.useMouseDrag({
		deps = { editableImage } :: { any },
		onBeganCallback = function(_rbx, input)
			dragStart.current = {
				screen = Vector2.new(input.Position.X, input.Position.Y),
				center = centerRef.current,
			}
		end,
		onDragCallback = function(_rbx, input)
			local vpSize = viewportSizeRef.current
			if vpSize.X <= 0 or vpSize.Y <= 0 then
				return
			end

			local screenDelta = Vector2.new(input.Position.X, input.Position.Y) - dragStart.current.screen
			local uvDelta = Vector2.new(screenDelta.X / vpSize.X, screenDelta.Y / vpSize.Y)
			setCenter(dragStart.current.center + uvDelta)
		end,
	})

	local function onInputChanged(rbx: GuiObject, input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseWheel then
			local vp = viewportRef.current
			if vp then
				local vpSize = vp.AbsoluteSize
				local vpPos = vp.AbsolutePosition
				if vpSize.X > 0 and vpSize.Y > 0 then
					local relX = math.clamp((input.Position.X - vpPos.X) / vpSize.X, 0, 1)
					local relY = math.clamp((input.Position.Y - vpPos.Y) / vpSize.Y, 0, 1)
					zoomBy(WHEEL_ZOOM_FACTOR ^ input.Position.Z, Vector2.new(relX, relY))
				end
			end
		end
		dragger.onInputChanged(rbx, input)
	end

	return {
		zoom = zoom,
		imageCenter = imageCenter,
		fitScale = fitScale,
		maxZoom = maxZoom,
		hasImage = editableImage ~= nil,
		reset = reset,
		zoomBy = zoomBy,
		setZoomLevel = setZoomLevel,
		dragger = dragger,
		onInputChanged = onInputChanged,
	}
end

return useImageControls
