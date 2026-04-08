--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local ReactRoblox = require(pluginRoot.Packages.ReactRoblox)
local React = require(pluginRoot.Packages.React)

local State = require(pluginRoot.Main.State)
State.storybook()

local uiRoot = script:FindFirstAncestor("UserInterface")
local FullViewport = require(uiRoot.Components.FullViewport2)

local stories = script:FindFirstAncestor("Stories")
local CreateStory = require(stories.Helpers.CreateStory)

local function story()
	local isDisabled, setIsDisabled = React.useState(false)
	local focusLenseSizeRef = React.useRef(Rect.new(0, 0, 0, 0))

	return React.createElement("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
	}, {
		FullViewport = React.createElement(FullViewport, {
			OnMinimize = function()
				print("Minimize")
			end,

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
				return true
			end,

			Visible = true,
			Disabled = isDisabled,
		}),
	})
end

return {
	react = React,
	reactRoblox = ReactRoblox,
	story = CreateStory.theme(story),
}
