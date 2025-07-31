--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local StudioComponents = require(pluginRoot.Packages.StudioComponents)
local React = require(pluginRoot.Packages.React)
local Sift = require(pluginRoot.Packages.Sift)

local RenderRect = require(pluginRoot.Utilities.RenderRect)
local Constants = require(pluginRoot.Constants)

local ContainerSize = require(script.Parent.Shared.ContainerSize)

local ActionBar = require(script.ActionBar)
local Grabbers = require(script.Grabbers)
local Blinder = require(script.Blinder)

local uiRoot = script:FindFirstAncestor("UserInterface")
local Hooks = require(uiRoot.Hooks)

local MAX_CAPTURE_RECT_SIZE = Vector2.new(Constants.MaxCaptureRectSize.X, Constants.MaxCaptureRectSize.Y)

local GRABBERS = {
	CornersEnabled = true,
	MiddlesEnabled = true,

	MaintainAspectKeys = Sift.Array.toSet({
		Enum.KeyCode.LeftControl,
		Enum.KeyCode.RightControl,
		Enum.KeyCode.LeftMeta,
		Enum.KeyCode.RightMeta,
	}),

	Length = 30,
	Padding = 8,
	Thickness = 4,
}

local ACTION_BAR = {
	Height = 28,
	Padding = 8,
}

local grabberMargin = GRABBERS.Padding + GRABBERS.Thickness
local actionBarPadding = if GRABBERS.MiddlesEnabled
	then ACTION_BAR.Padding + grabberMargin
	else ACTION_BAR.Padding + grabberMargin
local actionBarMargin = ACTION_BAR.Height + actionBarPadding

export type Props = {
	InitialSize: UDim2,
	FocusLenseSizeRef: { current: Vector2? },
	OnCapture: (Rect) -> (),
	OnMaximize: () -> ()?,
	Disabled: boolean,
}

local function useLenseSize(size: Vector2, viewportSize: Vector2, scale: Vector2, grabberMin: number)
	local width = viewportSize.X - grabberMargin * 2
	local height = viewportSize.Y - actionBarMargin * 2

	local minX = math.max(0, math.min(width, grabberMin * scale.X))
	local minY = math.max(0, math.min(height, grabberMin * scale.Y))

	local maxX = math.min(MAX_CAPTURE_RECT_SIZE.X * scale.X, width)
	local maxY = math.min(MAX_CAPTURE_RECT_SIZE.Y * scale.Y, height)

	local clampedX = math.clamp(size.X * scale.X, minX, math.max(minX, maxX))
	local clampedY = math.clamp(size.Y * scale.X, minY, math.max(minY, maxY))

	return Vector2.new(clampedX, clampedY)
end

local function CroppedViewport(props: Props & { ViewportSize: Vector2 })
	local theme = StudioComponents.useTheme()
	local scaleOS = Hooks.usePhotoConfiguration().ScaleOS

	local viewportSize = props.ViewportSize
	local scaledViewport = Vector2.new(math.round(viewportSize.X * scaleOS.X), math.round(viewportSize.Y * scaleOS.Y))

	local aspectKeysDown, setAspectKeysDown = React.useState({})

	local size, setSize = React.useState(MAX_CAPTURE_RECT_SIZE / 2)
	local sizeInitiated = React.useRef(false)
	local prevSize = React.useRef(MAX_CAPTURE_RECT_SIZE / 2)
	local startDrag = React.useRef(nil :: Vector3?)

	local actionBarWidth = if props.OnMaximize then 148 else 120
	local grabberMin = GRABBERS.Length * 3

	React.useEffect(function()
		local minX = grabberMin + grabberMargin * 2
		local minY = grabberMin + actionBarMargin * 2

		if viewportSize.X >= minX and viewportSize.Y >= minY then
			local initialSize = Vector2.new(
				props.InitialSize.X.Offset + props.InitialSize.X.Scale * scaledViewport.X,
				props.InitialSize.Y.Offset + props.InitialSize.Y.Scale * scaledViewport.Y
			)

			local targetSize = if sizeInitiated.current then size else initialSize
			local clamped = useLenseSize(targetSize, scaledViewport, Vector2.new(1, 1), grabberMin)
			setSize(clamped)
			prevSize.current = clamped
			sizeInitiated.current = true
		end
	end, { viewportSize })

	-- this is used for displaying dimensions + capture rect
	local scaledLenseAbsSize = useLenseSize(size, scaledViewport, Vector2.new(1, 1), grabberMin)
	local scaledLenseAbsPosition = (scaledViewport - scaledLenseAbsSize) / 2
	local scaledLenseRect = RenderRect.fromAbs(scaledLenseAbsPosition, scaledLenseAbsSize)
	local scaledLenseRectSize = Vector2.new(scaledLenseRect.Width, scaledLenseRect.Height)

	-- this is what renders
	local lenseAbsSize = (scaledLenseRectSize / scaleOS):Ceil()
	local lenseAbsPosition = (scaledLenseRect.Min / scaleOS):Floor()
	local lenseRect = Rect.new(lenseAbsPosition, lenseAbsPosition + lenseAbsSize)
	local lenseUDim2Size = UDim2.fromOffset(lenseRect.Width, lenseRect.Height)
	local lenseUDim2Position = UDim2.fromOffset(lenseRect.Min.X, lenseRect.Min.Y)

	React.useEffect(function()
		props.FocusLenseSizeRef.current = scaledLenseRectSize
	end, { scaledLenseRectSize })

	return React.createElement("Frame", {
		Position = UDim2.fromScale(0, 0),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,

		[React.Event.InputBegan] = function(_, input)
			if GRABBERS.MaintainAspectKeys[input.KeyCode] then
				aspectKeysDown[input.KeyCode] = true
				setAspectKeysDown(aspectKeysDown)

				if startDrag.current then
					prevSize.current = size
					startDrag.current = input.Position
				end
			end
		end,
		[React.Event.InputEnded] = function(_, input)
			if GRABBERS.MaintainAspectKeys[input.KeyCode] then
				aspectKeysDown[input.KeyCode] = nil
				setAspectKeysDown(aspectKeysDown)
			end
		end,
	}, {
		Focus = React.createElement("Frame", {
			AnchorPoint = Vector2.zero,
			Position = lenseUDim2Position,
			Size = lenseUDim2Size,
			BackgroundTransparency = 1,
			ZIndex = 2,
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

				CornersEnabled = GRABBERS.CornersEnabled,
				MiddlesEnabled = GRABBERS.MiddlesEnabled,

				OnDragStart = function(_rbx, input)
					prevSize.current = size
					startDrag.current = input.Position
				end,

				OnDragFinish = function()
					startDrag.current = nil
				end,

				OnDrag = function(_rbx, input, direction)
					if startDrag.current then
						local delta3 = input.Position - startDrag.current
						local delta2 = Vector2.new(delta3.X, delta3.Y)

						if next(aspectKeysDown) then
							local directionAbsSum = math.abs(direction.X) + math.abs(direction.Y)
							local isDiagonal = directionAbsSum >= 2

							if isDiagonal then
								local projectionAxis = (prevSize.current * direction).Unit
								delta2 = delta2:Dot(projectionAxis) * projectionAxis
							end
						end

						local offset = 2 * direction * scaleOS * delta2
						local newSize = prevSize.current + offset

						setSize(useLenseSize(newSize, scaledViewport, Vector2.new(1, 1), grabberMin))
					end
				end,

				Disabled = props.Disabled,
			}),
			ActionBar = React.createElement(ActionBar, {
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.new(0.5, 0, 1, actionBarPadding),
				Size = UDim2.fromOffset(actionBarWidth, ACTION_BAR.Height),

				DisplayedAbsSize = scaledLenseRectSize,
				OnDimensionInput = function(dimensions)
					setSize(useLenseSize(dimensions, scaledViewport, Vector2.new(1, 1), grabberMin))
				end,

				OnMaximize = props.OnMaximize,
				OnCapture = function()
					props.OnCapture(scaledLenseRect)
				end,

				Disabled = props.Disabled,
			}),
		}),

		Blinder = React.createElement(Blinder, {
			AnchorPoint = Vector2.zero,
			Position = lenseUDim2Position,
			Size = lenseUDim2Size,

			-- this should be hidden by the UI stroke
			-- it acts as a margin of error against half-pixel scaling
			MarginBump = -1,
			OverlapBump = 10,

			Color = Color3.new(0, 0, 0),
			Transparency = 0.7,
			ZIndex = 1,

			Disabled = props.Disabled,
		}),
	})
end

return function(props: Props)
	local containerSize, setContainerSize = React.useState(Vector2.zero)
	return React.createElement(ContainerSize, {
		SetContainerSize = setContainerSize,
	}, {
		CroppedViewport = React.createElement(CroppedViewport, {
			ViewportSize = containerSize,
			InitialSize = props.InitialSize,
			FocusLenseSizeRef = props.FocusLenseSizeRef,
			OnMaximize = props.OnMaximize,
			OnCapture = props.OnCapture,
			Disabled = props.Disabled,
		}),
	})
end
