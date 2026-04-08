--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local StudioComponents = require(pluginRoot.Packages.StudioComponents)
local Lucide = require(pluginRoot.Packages.Lucide)
local React = require(pluginRoot.Packages.React)

local uiRoot = script:FindFirstAncestor("UserInterface")
local BaseButton = require(uiRoot.Components.Shared.BaseButton)
local Hooks = require(uiRoot.Hooks)

export type Props = {
	OnCapture: (Rect) -> (boolean, string?),
	OnMinimize: () -> (),
	Visible: boolean,
	Disabled: boolean?,
}

local function FullViewport(props: Props & { ViewportRect: Rect }) end

return React.memo(function(props: Props)
	local viewportRef = React.useRef(nil :: GuiObject?)
	local viewportAbsSize = Hooks.useRefProperty(viewportRef, "AbsoluteSize", Vector2.new(math.huge, math.huge))
	local viewportAbsPosition = Hooks.useRefProperty(viewportRef, "AbsolutePosition", Vector2.zero)

	local viewportRect = Rect.new(
		viewportAbsPosition.X,
		viewportAbsPosition.Y,
		viewportAbsPosition.X + viewportAbsSize.X,
		viewportAbsPosition.Y + viewportAbsSize.Y
	)

	return React.createElement("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	}, {
		Core = props.Visible and React.createElement(FullViewport, {
			ViewportRect = viewportRect,
			OnCapture = props.OnCapture,
			OnMinimize = props.OnMinimize,
			Visible = props.Visible :: boolean,
			Disabled = props.Disabled,
		}),
	})
end)
