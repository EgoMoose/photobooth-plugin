--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local StudioComponents = require(pluginRoot.Packages.StudioComponents)
local React = require(pluginRoot.Packages.React)

local RenderRect = require(pluginRoot.Main.Bindings.Interface.Helpers.RenderRect)
local Constants = require(pluginRoot.Constants)
local State = require(pluginRoot.Main.State)

local uiRoot = script:FindFirstAncestor("UserInterface")
local Hooks = require(uiRoot.Hooks)

local Blinder = require(script.Blinder)
local Grabbers = require(script.Grabbers)
local ActionBar = require(script.ActionBar)
local AlignButtons = require(script.AlignButtons)
local IsKeyDownTracker = require(script.IsKeyDownTracker)

local CROP_MODE_KEYCODE_SET = {
	[Enum.KeyCode.LeftShift] = true,
	[Enum.KeyCode.RightShift] = true,
}

local GRABBERS = {
	CornersEnabled = true,
	MiddlesEnabled = true,

	Length = 30,
	Padding = 8,
	Thickness = 4,
}

local GRABBER_MARGIN = GRABBERS.Padding + GRABBERS.Thickness

local ACTION_BAR = {
	Width = 148,
	Height = 28,
	Padding = 8,
}

local ACTION_BAR_PADDING = ACTION_BAR.Padding + GRABBER_MARGIN
local ACTION_BAR_MARGIN = ACTION_BAR.Height + ACTION_BAR_PADDING

local ALIGN_BUTTONS_HEIGHT = 112
local ALIGN_BUTTONS_WIDTH = 116

local MIN_CAPTURE_HEIGHT = math.max(GRABBERS.Length * 3, ALIGN_BUTTONS_HEIGHT)
local MIN_CAPTURE_WIDTH = math.max(MIN_CAPTURE_HEIGHT, ACTION_BAR.Width, ALIGN_BUTTONS_WIDTH)

local MAX_CAPTURE_HEIGHT = Constants.MaxCaptureRectSize.Y
local MAX_CAPTURE_WIDTH = Constants.MaxCaptureRectSize.X

local function scaleRect(rect: Rect, anchorPoint: Vector2, scale: Vector2)
	local size = Vector2.new(rect.Width, rect.Height)
	local anchor = rect.Min + size * anchorPoint
	return Rect.new(rect.Min + (anchor - rect.Min) * scale, rect.Max + (anchor - rect.Max) * scale)
end

local function positionRect(rect: Rect, anchorPoint: Vector2, position: Vector2)
	local size = Vector2.new(rect.Width, rect.Height)
	local anchor = rect.Min + size * anchorPoint
	return Rect.new(position + (rect.Min - anchor), position + (rect.Max - anchor))
end

local function clampRect(
	captureRect: Rect,
	viewportRect: Rect,
	scaleOS: Vector2,
	direction: Vector2,
	delta: Vector2,
	mirror: boolean
)
	local boundMinX = viewportRect.Min.X + GRABBER_MARGIN * scaleOS.X
	local boundMinY = viewportRect.Min.Y + GRABBER_MARGIN * scaleOS.Y
	local boundMaxX = viewportRect.Max.X - GRABBER_MARGIN * scaleOS.X
	local boundMaxY = viewportRect.Max.Y - GRABBER_MARGIN * scaleOS.Y

	local minWidth = math.min(MIN_CAPTURE_WIDTH * scaleOS.X, boundMaxX - boundMinX)
	local minHeight = math.min(MIN_CAPTURE_HEIGHT * scaleOS.Y, boundMaxY - boundMinY)
	local maxWidth = math.min(MAX_CAPTURE_WIDTH * scaleOS.X, boundMaxX - boundMinX)
	local maxHeight = math.min(MAX_CAPTURE_HEIGHT * scaleOS.Y, boundMaxY - boundMinY)

	local dX, dY = direction.X, direction.Y
	if dX == 0 and dY == 0 then
		-- the rect is translating
		local minX = captureRect.Min.X + delta.X
		local minY = captureRect.Min.Y + delta.Y
		local maxX = captureRect.Max.X + delta.X
		local maxY = captureRect.Max.Y + delta.Y

		local width = math.clamp(maxX - minX, minWidth, maxWidth)
		local height = math.clamp(maxY - minY, minHeight, maxHeight)

		maxX = math.min(math.max(minX, boundMinX) + width, boundMaxX)
		minX = math.max(maxX - width, boundMinX)
		maxY = math.min(math.max(minY, boundMinY) + height, boundMaxY)
		minY = math.max(maxY - height, boundMinY)

		return Rect.new(minX, minY, maxX, maxY)
	elseif mirror then
		local center = (captureRect.Min + captureRect.Max) / 2

		local minX = math.clamp(captureRect.Min.X - delta.X * dX, center.X - maxWidth / 2, center.X - minWidth / 2)
		local minY = math.clamp(captureRect.Min.Y - delta.Y * dY, center.Y - maxHeight / 2, center.Y - minHeight / 2)
		local maxX = math.clamp(captureRect.Max.X + delta.X * dX, center.X + minWidth / 2, center.X + maxWidth / 2)
		local maxY = math.clamp(captureRect.Max.Y + delta.Y * dY, center.Y + minHeight / 2, center.Y + maxHeight / 2)

		return Rect.new(
			math.clamp(minX, boundMinX, boundMaxX),
			math.clamp(minY, boundMinY, boundMaxY),
			math.clamp(maxX, boundMinX, boundMaxX),
			math.clamp(maxY, boundMinY, boundMaxY)
		)
	else
		local minX = captureRect.Min.X
		local minY = captureRect.Min.Y
		local maxX = captureRect.Max.X
		local maxY = captureRect.Max.Y

		if dX ~= 0 then
			local dMinX = math.abs(math.min(dX, 0))
			local dMaxX = math.abs(math.max(dX, 0))
			minX = captureRect.Min.X + delta.X * dMinX
			maxX = captureRect.Max.X + delta.X * dMaxX
			local width = math.clamp(maxX - minX, minWidth, maxWidth)
			minX = (minX * dMaxX + maxX * dMinX) - dMinX * width
			maxX = (minX * dMaxX + maxX * dMinX) + dMaxX * width
		end

		if dY ~= 0 then
			local dMinY = math.abs(math.min(dY, 0))
			local dMaxY = math.abs(math.max(dY, 0))
			minY = captureRect.Min.Y + delta.Y * dMinY
			maxY = captureRect.Max.Y + delta.Y * dMaxY
			local height = math.clamp(maxY - minY, minHeight, maxHeight)
			minY = (minY * dMaxY + maxY * dMinY) - dMinY * height
			maxY = (minY * dMaxY + maxY * dMinY) + dMaxY * height
		end

		return Rect.new(
			math.clamp(minX, boundMinX, boundMaxX),
			math.clamp(minY, boundMinY, boundMaxY),
			math.clamp(maxX, boundMinX, boundMaxX),
			math.clamp(maxY, boundMinY, boundMaxY)
		)
	end
end

local function useScaledViewportRect(viewportRect: Rect, scaleOS: Vector2)
	local getScaledViewportRect = React.useCallback(function()
		local viewportSize = Vector2.new(viewportRect.Width, viewportRect.Height)
		return RenderRect.fromAbs(viewportRect.Min * scaleOS, viewportSize * scaleOS)
	end, { viewportRect, scaleOS } :: { any })

	local scaledViewportRect, setScaledViewportRect = React.useState(getScaledViewportRect())

	React.useEffect(function()
		setScaledViewportRect(getScaledViewportRect())
	end, { getScaledViewportRect })

	return scaledViewportRect
end

local function useCaptureRect(captureRef: { current: Rect }, scaledViewportRect: Rect, scaleOS: Vector2)
	local getClampedCaptureRect = React.useCallback(
		function(rect: Rect, direction: Vector2, delta: Vector2, mirror: boolean)
			return clampRect(rect, scaledViewportRect, scaleOS, direction, delta * scaleOS, mirror)
		end,
		{ scaledViewportRect, scaleOS } :: { any }
	)

	local captureRect, setCaptureRect =
		React.useState(RenderRect.fromRect(getClampedCaptureRect(captureRef.current, Vector2.one, Vector2.zero, true)))

	local setCaptureRectClamped = React.useCallback(
		function(rect: Rect, direction: Vector2, delta: Vector2, mirror: boolean)
			local clampedCaptureRect = RenderRect.fromRect(getClampedCaptureRect(rect, direction, delta, mirror))
			captureRef.current = clampedCaptureRect
			setCaptureRect(clampedCaptureRect)
		end,
		{ getClampedCaptureRect }
	)

	React.useEffect(function()
		local newCenter = scaledViewportRect.Min + Vector2.new(scaledViewportRect.Width, scaledViewportRect.Height) / 2
		local newCaptureRect = positionRect(captureRect, Vector2.new(0.5, 0.5), newCenter)
		setCaptureRectClamped(newCaptureRect, Vector2.one, Vector2.zero, true)
	end, { setCaptureRectClamped })

	return captureRect, setCaptureRectClamped
end

export type Props = {
	OnCapture: (Rect) -> (boolean, string?),
	OnMaximize: () -> (),
	Visible: boolean,
	Disabled: boolean?,
}

local function CroppedViewport(props: Props & { ViewportRect: Rect, CaptureRectRef: { current: Rect } })
	local theme = StudioComponents.useTheme()
	local scaleOS = Hooks.useStatePath(function(state)
		return state.temporary.scaleOS
	end)

	local isCropMode, setIsCropMode = React.useState(false)
	local isDragCropMode, setIsDragCropMode = React.useState(false)

	local dragRectRef = React.useRef(nil :: Rect?)
	local scaledViewportRect = useScaledViewportRect(props.ViewportRect, scaleOS)
	local captureRect, setCaptureRect = useCaptureRect(props.CaptureRectRef, scaledViewportRect, scaleOS)

	local renderedCaptureRect = RenderRect.fromRect(
		Rect.new(
			captureRect.Min.X / scaleOS.X,
			captureRect.Min.Y / scaleOS.Y,
			captureRect.Max.X / scaleOS.X,
			captureRect.Max.Y / scaleOS.Y
		)
	)

	return React.createElement("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	}, {
		Lense = React.createElement("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(
				renderedCaptureRect.Min.X - scaledViewportRect.Min.X,
				renderedCaptureRect.Min.Y - scaledViewportRect.Min.Y
			),
			Size = UDim2.fromOffset(renderedCaptureRect.Width, renderedCaptureRect.Height),
		}, {
			Outline = React.createElement("Frame", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
			}, {
				UIStroke = React.createElement("UIStroke", {
					Thickness = 2,
					Transparency = 0,
					Color = theme:GetColor(
						Enum.StudioStyleGuideColor.InputFieldBorder,
						Enum.StudioStyleGuideModifier.Selected
					),
				}),
			}),

			Grabbers = React.createElement(Grabbers, {
				Transparency = 0.4,
				Thickness = UDim.new(0, GRABBERS.Thickness),
				Padding = UDim.new(0, GRABBERS.Padding),
				Length = UDim.new(0, GRABBERS.Length),

				TranslateEnabled = isCropMode or isDragCropMode,
				CornersEnabled = GRABBERS.CornersEnabled,
				MiddlesEnabled = GRABBERS.MiddlesEnabled,

				OnDragStart = function()
					dragRectRef.current = captureRect
					setIsDragCropMode(isCropMode)
				end,

				OnDrag = function(direction, delta)
					local dragRect = dragRectRef.current :: Rect
					setCaptureRect(dragRect, direction, delta, not (isCropMode or isDragCropMode))
				end,

				OnDragFinish = function()
					setIsDragCropMode(false)
				end,

				Disabled = props.Disabled,
			}),

			ActionBar = React.createElement(ActionBar, {
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.new(0.5, 0, 1, ACTION_BAR_PADDING),
				Size = UDim2.fromOffset(ACTION_BAR.Width, ACTION_BAR.Height),

				ViewportRect = props.ViewportRect,
				DisplayRect = captureRect,

				OnDimensionInput = function(dimensions)
					local center = (captureRect.Min + captureRect.Max) / 2
					local rect = Rect.new(center - dimensions / 2, center + dimensions / 2)
					setCaptureRect(rect, Vector2.zero, Vector2.zero, false)
				end,

				UseRectText = isCropMode or isDragCropMode,
				OnRectInput = function(rect)
					setCaptureRect(rect, Vector2.zero, Vector2.zero, false)
				end,

				OnMaximize = props.OnMaximize,
				OnCapture = function()
					return props.OnCapture(captureRect)
				end,

				Disabled = props.Disabled,
			}),

			AlignButtons = React.createElement(AlignButtons, {
				Visible = isCropMode or isDragCropMode,

				OnJustify = function(jx, jy)
					local justifiedRect = captureRect

					if jx then
						local positionX = scaledViewportRect.Min.X + scaledViewportRect.Width * jx
						justifiedRect =
							positionRect(justifiedRect, Vector2.new(jx, 0), Vector2.new(positionX, justifiedRect.Min.Y))
					end

					if jy then
						local positionY = scaledViewportRect.Min.Y + scaledViewportRect.Height * jy
						justifiedRect =
							positionRect(justifiedRect, Vector2.new(0, jy), Vector2.new(justifiedRect.Min.X, positionY))
					end

					setCaptureRect(justifiedRect, Vector2.zero, Vector2.zero, false)
				end,

				ZIndex = 2,
				Disabled = props.Disabled,
			}),
		}),

		Blinder = React.createElement(Blinder, {
			Position = UDim2.fromOffset(
				renderedCaptureRect.Min.X - scaledViewportRect.Min.X,
				renderedCaptureRect.Min.Y - scaledViewportRect.Min.Y
			),
			Size = UDim2.fromOffset(renderedCaptureRect.Width, renderedCaptureRect.Height),

			-- this should be hidden by the UI stroke
			-- it acts as a margin of error against half-pixel scaling
			MarginBump = -1,
			OverlapBump = 10,

			Color = Color3.new(0, 0, 0),
			Transparency = 0.7,
			ZIndex = -1,

			Disabled = props.Disabled,
		}),

		IsKeyDownTracker = React.createElement(IsKeyDownTracker, {
			Size = UDim2.fromScale(1, 1),
			ZIndex = 2,

			KeyCodeSet = CROP_MODE_KEYCODE_SET,
			OnKeyDownChanged = React.useCallback(function(isKeyDown)
				setIsCropMode(isKeyDown)
			end, { setIsCropMode }),
		}),
	})
end

return function(props: Props)
	local captureRectRef = React.useRef(Rect.new(0, 0, 512, 512))

	local viewportRef = React.useRef(nil :: GuiObject?)
	local viewportAbsSize = Hooks.useRefProperty(viewportRef, "AbsoluteSize", Vector2.new(math.huge, math.huge))
	local viewportAbsPosition = Hooks.useRefProperty(viewportRef, "AbsolutePosition", Vector2.zero)

	local viewportRect = Rect.new(
		viewportAbsPosition.X,
		viewportAbsPosition.Y,
		viewportAbsPosition.X + viewportAbsSize.X,
		viewportAbsPosition.Y + viewportAbsSize.Y
	)

	local isReady, setIsReady = React.useState(false)
	React.useEffect(function()
		local viewportFrame = viewportRef.current
		if viewportFrame then
			local scaleOS = State.read().temporary.scaleOS
			local absSize = viewportFrame.AbsoluteSize
			local absPosition = viewportFrame.AbsolutePosition

			local scaledViewportRect = RenderRect.fromAbs(absPosition * scaleOS, absSize * scaleOS)
			local centerRect = scaleRect(scaledViewportRect, Vector2.new(0.5, 0.5), Vector2.new(0.5, 0.5))

			-- we are setting the initial capture rect ref to be half the viewport from the center of the screen
			captureRectRef.current = RenderRect.fromRect(centerRect)

			setIsReady(true)
		end
	end, {})

	return React.createElement("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Active = false,
		ref = viewportRef,
	}, {
		Core = props.Visible and isReady and React.createElement(CroppedViewport, {
			ViewportRect = viewportRect,
			CaptureRectRef = captureRectRef,
			OnMaximize = props.OnMaximize,
			OnCapture = props.OnCapture,
			Visible = props.Visible :: boolean,
			Disabled = props.Disabled,
		}),
	})
end
