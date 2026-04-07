--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local StudioComponents = require(pluginRoot.Packages.StudioComponents)
local React = require(pluginRoot.Packages.React)

local RenderRect = require(pluginRoot.Main.Bindings.Interface.Helpers.RenderRect)
local Constants = require(pluginRoot.Constants)

local uiRoot = script:FindFirstAncestor("UserInterface")
local Hooks = require(uiRoot.Hooks)

local Blinder = require(script.Blinder)
local Grabbers = require(script.Grabbers)

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

local MIN_CAPTURE_HEIGHT = GRABBERS.Length * 3
local MIN_CAPTURE_WIDTH = math.max(MIN_CAPTURE_HEIGHT, ACTION_BAR.Width)

local MAX_CAPTURE_HEIGHT = Constants.MaxCaptureRectSize.Y
local MAX_CAPTURE_WIDTH = Constants.MaxCaptureRectSize.X

local function clampRect(captureRect: Rect, viewportRect: Rect, direction: Vector2, delta: Vector2)
	local boundMinX = viewportRect.Min.X + GRABBER_MARGIN
	local boundMinY = viewportRect.Min.Y + GRABBER_MARGIN
	local boundMaxX = viewportRect.Max.X - GRABBER_MARGIN
	local boundMaxY = viewportRect.Max.Y - ACTION_BAR_MARGIN

	local dX, dY = direction.X, direction.Y
	if dX == 0 and dY == 0 then
		-- the rect is translating
		captureRect = Rect.new(
			captureRect.Min.X + delta.X,
			captureRect.Min.Y + delta.Y,
			captureRect.Max.X + delta.X,
			captureRect.Max.Y + delta.Y
		)
	else
		local minX, maxX = captureRect.Min.X, captureRect.Max.X
		if dX ~= 0 then
			local dMinX, dMaxX = math.abs(math.min(dX, 0)), math.abs(math.max(dX, 0))
			minX = captureRect.Min.X + delta.X * dMinX
			maxX = captureRect.Max.X + delta.X * dMaxX
			local width = math.clamp(maxX - minX, MIN_CAPTURE_WIDTH, MAX_CAPTURE_WIDTH)
			minX = (minX * dMaxX + maxX * dMinX) - dMinX * width
			maxX = (minX * dMaxX + maxX * dMinX) + dMaxX * width
		end

		local minY, maxY = captureRect.Min.Y, captureRect.Max.Y
		if dY ~= 0 then
			local dMinY, dMaxY = math.abs(math.min(dY, 0)), math.abs(math.max(dY, 0))
			minY = captureRect.Min.Y + delta.Y * dMinY
			maxY = captureRect.Max.Y + delta.Y * dMaxY
			local height = math.clamp(maxY - minY, MIN_CAPTURE_HEIGHT, MAX_CAPTURE_HEIGHT)
			minY = (minY * dMaxY + maxY * dMinY) - dMinY * height
			maxY = (minY * dMaxY + maxY * dMinY) + dMaxY * height
		end

		captureRect = Rect.new(minX, minY, maxX, maxY)
	end

	return Rect.new(
		math.clamp(captureRect.Min.X, boundMinX, boundMaxX),
		math.clamp(captureRect.Min.Y, boundMinY, boundMaxY),
		math.clamp(captureRect.Max.X, boundMinX, boundMaxX),
		math.clamp(captureRect.Max.Y, boundMinY, boundMaxY)
	)
end

local function useCaptureRect(initialRect: Rect, viewportRect: Rect, scaleOS: Vector2)
	local viewportSize = Vector2.new(viewportRect.Width, viewportRect.Height)
	local scaledViewportRect = RenderRect.fromAbs(viewportRect.Min, viewportSize * scaleOS)

	local captureRect, setCaptureRect =
		React.useState(clampRect(initialRect, scaledViewportRect, Vector2.zero, Vector2.zero))

	local setCaptureRectClamped = React.useCallback(function(rect: Rect, direction: Vector2, delta: Vector2)
		setCaptureRect(clampRect(rect, scaledViewportRect, direction, delta))
	end, { scaledViewportRect } :: { any })

	React.useEffect(function()
		setCaptureRectClamped(captureRect, Vector2.zero, Vector2.zero)
	end, { setCaptureRectClamped })

	return captureRect, setCaptureRectClamped
end

export type Props = {
	LenseRectRef: { current: Rect? },
	Disabled: boolean?,
}

local function CroppedViewport(props: Props & { ViewportRect: Rect })
	local theme = StudioComponents.useTheme()
	local scaleOS = Hooks.useStatePath(function(state)
		return state.temporary.scaleOS
	end)

	local dragRectRef = React.useRef(nil :: Rect?)
	local captureRect, setCaptureRect = useCaptureRect(Rect.new(100, 100, 512, 512), props.ViewportRect, scaleOS)

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
			Position = UDim2.fromOffset(renderedCaptureRect.Min.X, renderedCaptureRect.Min.Y),
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

				TranslateEnabled = true,
				CornersEnabled = GRABBERS.CornersEnabled,
				MiddlesEnabled = GRABBERS.MiddlesEnabled,

				OnDragStart = function()
					dragRectRef.current = captureRect
				end,

				OnDrag = function(direction, delta)
					local dragRect = dragRectRef.current :: Rect
					setCaptureRect(dragRect, direction, delta)
				end,

				Disabled = props.Disabled,
			}),
		}),

		Blinder = React.createElement(Blinder, {
			Position = UDim2.fromOffset(renderedCaptureRect.Min.X, renderedCaptureRect.Min.Y),
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
	})
end

return function(props: Props)
	local viewportRef = React.useRef(nil :: GuiObject?)
	local viewportAbsSize = Hooks.useRefProperty(viewportRef, "AbsoluteSize", Vector2.new(math.huge, math.huge))
	local viewportAbsPosition = Vector2.zero --Hooks.useRefProperty(viewportRef, "AbsolutePosition", Vector2.zero)

	local viewportRect = Rect.new(
		viewportAbsPosition.X,
		viewportAbsPosition.Y,
		viewportAbsPosition.X + viewportAbsSize.X,
		viewportAbsPosition.Y + viewportAbsSize.Y
	)

	return React.createElement("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ref = viewportRef,
	}, {
		CroppedViewport = React.createElement(CroppedViewport, {
			ViewportRect = viewportRect,
			LenseRectRef = props.LenseRectRef,
		}),
	})
end
