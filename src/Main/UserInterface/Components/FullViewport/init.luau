--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local StudioComponents = require(pluginRoot.Packages.StudioComponents)
local React = require(pluginRoot.Packages.React)

local uiRoot = script:FindFirstAncestor("UserInterface")
local Hooks = require(uiRoot.Hooks)

local BoundedDragFrame = require(script.BoundedDragFrame)
local ActionBar = require(script.ActionBar)

local DRAGGER_SIZE = Vector2.new(148, 28)
local DRAGGER_SIZE_2 = DRAGGER_SIZE * 2

export type Props = {
	OnCapture: (Rect) -> (boolean, string?),
	OnMinimize: () -> (),
	Visible: boolean,
	Disabled: boolean?,
}

local function InnerBorder(props: { Thickness: number, Padding: number, Disabled: boolean, children: React.ReactNode })
	local theme = StudioComponents.useTheme()

	return React.createElement("Frame", {
		Size = UDim2.new(1, -props.Thickness * 2, 1, -props.Thickness * 2),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
	}, {
		StrokeFrame = React.createElement("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ZIndex = 2,
		}, {
			UIStroke = React.createElement("UIStroke", {
				Thickness = props.Thickness,
				Transparency = 0,
				LineJoinMode = Enum.LineJoinMode.Miter,
				Color = theme:GetColor(
					Enum.StudioStyleGuideColor.InputFieldBorder,
					Enum.StudioStyleGuideModifier.Selected
				),
			}),
		}),
		ChildFrame = React.createElement("Frame", {
			Size = UDim2.new(1, -props.Padding * 2, 1, -props.Padding * 2),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			ZIndex = 1,
		}, props.children),
	})
end

local function FullViewport(props: Props & { ViewportRect: Rect })
	local draggerScale = 1
	local viewportWidth = props.ViewportRect.Width
	local viewportHeight = props.ViewportRect.Height
	if viewportWidth < DRAGGER_SIZE_2.X or viewportHeight < DRAGGER_SIZE_2.Y then
		draggerScale = math.min(viewportWidth / DRAGGER_SIZE_2.X, viewportHeight / DRAGGER_SIZE_2.Y)
	end

	return React.createElement(InnerBorder, {
		Thickness = 2,
		Padding = 1,
		Disabled = false,
	}, {
		BoundedDragFrame = React.createElement(BoundedDragFrame, {
			InitialPosition = UDim2.fromScale(0, 0),
			Size = UDim2.fromOffset(DRAGGER_SIZE.X, DRAGGER_SIZE.Y),
			Scale = draggerScale,
			Disabled = props.Disabled,
		}, {
			ActionBar = React.createElement(ActionBar, {
				ViewportRect = props.ViewportRect,
				OnMinimize = props.OnMinimize,
				OnCapture = props.OnCapture,
				Disabled = props.Disabled,
			}),
		}),
	})
end

local FullViewportMemo = React.memo(FullViewport)

return React.memo(function(props: Props)
	local viewportRef = React.useRef(nil :: GuiObject?)
	local viewportAbsSize = Hooks.useRefProperty(viewportRef, "AbsoluteSize", Vector2.new(math.huge, math.huge))
	local viewportAbsPosition = Hooks.useRefProperty(viewportRef, "AbsolutePosition", Vector2.zero)
	local viewportRect = Rect.new(viewportAbsPosition, viewportAbsPosition + viewportAbsSize)

	return React.createElement("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Active = false,
		ref = viewportRef,
	}, {
		Core = props.Visible and React.createElement(FullViewportMemo, {
			ViewportRect = viewportRect,
			OnCapture = props.OnCapture,
			OnMinimize = props.OnMinimize,
			Visible = props.Visible :: boolean,
			Disabled = props.Disabled,
		}),
	})
end)
