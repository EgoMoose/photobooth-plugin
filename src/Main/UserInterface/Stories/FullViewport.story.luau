--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local React = require(pluginRoot.Packages.React)

local Constants = require(pluginRoot.Constants)

local uiRoot = script:FindFirstAncestor("UserInterface")
local FullViewport = require(uiRoot.Components.FullViewport)

local stories = script:FindFirstAncestor("Stories")
local CreateStory = require(stories.Helpers.CreateStory)

local function story()
	local isDisabled, setIsDisabled = React.useState(false)
	local focusLenseSizeRef = React.useRef(Vector2.zero)

	return React.createElement("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
	}, {
		FullViewport = React.createElement(FullViewport, {
			OnMinimize = if Constants.ShowFullscreenActionBarButton
				then function()
					print("Minimize")
				end
				else nil,

			OnCapture = function(rect)
				setIsDisabled(true)
				print(focusLenseSizeRef.current)
				print(table.concat({
					"",
					"Viewport Capture",
					`> Rect: {rect}`,
					`> Size: ({rect.Width}, {rect.Height})`,
				}, "\n"))
				task.wait(1)
				setIsDisabled(false)
			end,

			FocusLenseSizeRef = focusLenseSizeRef,
			Disabled = isDisabled,
		}),
	})
end

return {
	story = CreateStory(story),
}
