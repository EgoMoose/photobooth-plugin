--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local StudioComponents = require(pluginRoot.Packages.StudioComponents)
local React = require(pluginRoot.Packages.React)
local Sift = require(pluginRoot.Packages.Sift)

local ContainerSize = require(script.ContainerSize)
local ActionBar = require(script.ActionBar)
local Grabbers = require(script.Grabbers)
local Blinder = require(script.Blinder)

local uiRoot = script:FindFirstAncestor("UserInterface")
local Hooks = require(uiRoot.Hooks)

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
	Width = 120,
	Height = 28,
	Padding = 8,
}

local ANCHOR_POINT = Vector2.new(0.5, 0.5)
local POSITION = UDim2.fromScale(0.5, 0.5)
local INITIAL_SIZE_SCALE = Vector2.new(0.5, 0.5)

local MAX_EDIT_IMAGE_SIZE = Vector2.new(1024, 1024)

local grabberMargin = GRABBERS.Padding + GRABBERS.Thickness
if GRABBERS.MiddlesEnabled then
	ACTION_BAR.Padding = ACTION_BAR.Padding + grabberMargin
end

local grabberMin = GRABBERS.Length * 3 + ACTION_BAR.Width
local actionBarMargin = ACTION_BAR.Height + ACTION_BAR.Padding

export type Props = {
	OnCapture: (Rect) -> (),
	OnFocus: {
		Trigger: RBXScriptSignal,
		Callback: (Vector2) -> (),
	},
	Disabled: boolean,
}

local function useLenseSize(size: Vector2, viewportSize: Vector2, scale: Vector2)
	local width = viewportSize.X - grabberMargin * 2
	local height = viewportSize.Y - actionBarMargin * 2

	local minX = math.max(0, math.min(width, grabberMin * scale.X))
	local minY = math.max(0, math.min(height, grabberMin * scale.Y))

	local maxX = math.min(MAX_EDIT_IMAGE_SIZE.X * scale.X, width)
	local maxY = math.min(MAX_EDIT_IMAGE_SIZE.Y * scale.Y, height)

	local clampedX = math.clamp(size.X * scale.X, minX, math.max(minX, maxX))
	local clampedY = math.clamp(size.Y * scale.X, minY, math.max(minY, maxY))

	return Vector2.new(clampedX, clampedY)
end

local function CroppedViewport(props: Props)
	local theme = StudioComponents.useTheme()
	local scaleOS = Hooks.usePhotoConfiguration().ScaleOS
	local viewportSize = ContainerSize.useContainerSize()
	local scaledViewport = viewportSize * scaleOS

	local aspectKeysDown, setAspectKeysDown = React.useState({})

	local size, setSize = React.useState(MAX_EDIT_IMAGE_SIZE / 2)
	local sizeInitiated = React.useRef(false)
	local prevSize = React.useRef(MAX_EDIT_IMAGE_SIZE / 2)
	local startDrag = React.useRef(nil :: Vector3?)

	React.useEffect(function()
		local minX = grabberMin + grabberMargin * 2
		local minY = grabberMin + actionBarMargin * 2

		if viewportSize.X >= minX and viewportSize.Y >= minY then
			local targetSize = if sizeInitiated.current then size else scaledViewport * INITIAL_SIZE_SCALE
			local clamped = useLenseSize(targetSize, scaledViewport, Vector2.new(1, 1))
			setSize(clamped)
			prevSize.current = clamped
			sizeInitiated.current = true
		end
	end, { viewportSize })

	local lenseSize = useLenseSize(size, viewportSize, 1 / scaleOS)
	local lenseSizeUDim2 = UDim2.fromOffset(math.ceil(lenseSize.X), math.ceil(lenseSize.Y))

	React.useEffect(function()
		local connection = props.OnFocus.Trigger:Connect(function()
			props.OnFocus.Callback(lenseSize:Ceil())
		end)
		return function()
			connection:Disconnect()
		end
	end, { lenseSize, props.OnFocus.Trigger, props.OnFocus.Callback } :: { any })

	local scaledLenseSize = lenseSize * scaleOS
	local scaledLenseMin = ((scaledViewport - scaledLenseSize) / 2):Ceil()
	local scaledLenseMax = ((scaledViewport + scaledLenseSize) / 2):Ceil()
	local scaledLenseRect = Rect.new(scaledLenseMin, scaledLenseMax)

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
			AnchorPoint = ANCHOR_POINT,
			Position = POSITION,
			Size = lenseSizeUDim2,
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

						setSize(useLenseSize(newSize, scaledViewport, Vector2.new(1, 1)))
					end
				end,

				Disabled = props.Disabled,
			}),
			ActionBar = React.createElement(ActionBar, {
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.new(0.5, 0, 1, ACTION_BAR.Padding),
				Size = UDim2.fromOffset(ACTION_BAR.Width, ACTION_BAR.Height),

				DisplayedAbsSize = Vector2.new(scaledLenseRect.Width, scaledLenseRect.Height),
				OnDimensionInput = function(dimensions)
					setSize(useLenseSize(dimensions, scaledViewport, Vector2.new(1, 1)))
				end,

				OnCapture = function()
					props.OnCapture(scaledLenseRect)
				end,

				Disabled = props.Disabled,
			}),
		}),

		Blinder = React.createElement(Blinder, {
			AnchorPoint = ANCHOR_POINT,
			Position = POSITION,
			Size = lenseSizeUDim2,

			-- this should be hidden by the UI stroke
			-- it acts as a margin of error against half-pixel scaling
			MarginBump = -1,

			Color = Color3.new(0, 0, 0),
			Transparency = 0.7,
			ZIndex = 1,

			Disabled = props.Disabled,
		}),
	})
end

return function(props: Props)
	return React.createElement(ContainerSize.Component, nil, React.createElement(CroppedViewport, props))
end
