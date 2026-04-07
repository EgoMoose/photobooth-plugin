--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local ReactRoblox = require(pluginRoot.Packages.ReactRoblox)
local React = require(pluginRoot.Packages.React)

local State = require(pluginRoot.Main.State)
State.storybook()

local uiRoot = script:FindFirstAncestor("UserInterface")
local CroppedViewport = require(uiRoot.Components.CroppedViewport2)

local stories = script:FindFirstAncestor("Stories")
local CreateStory = require(stories.Helpers.CreateStory)

local function story()
	local isDisabled, setIsDisabled = React.useState(false)
	local captureRectRef = React.useRef(Rect.new(0, 0, 0, 0))

	return React.createElement(CroppedViewport, {
		CaptureRectRef = captureRectRef,

		OnMaximize = function()
			print("Maximize")
		end,

		OnCapture = function(rect)
			setIsDisabled(true)
			print(captureRectRef.current)
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

		Disabled = isDisabled,
	})
end

return {
	react = React,
	reactRoblox = ReactRoblox,
	story = CreateStory.theme(story),
}
