--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local React = require(pluginRoot.Packages.React)

local uiRoot = script:FindFirstAncestor("UserInterface")
<<<<<<<< HEAD:src/Main/UserInterface/Stories/CroppedViewport.story.luau
local CroppedViewport = require(uiRoot.Components.CroppedViewport)
========
local FullViewport = require(uiRoot.Components.FullViewport)
>>>>>>>> full-viewport-captures:src/Main/UserInterface/Stories/FullViewport.story.luau

local stories = script:FindFirstAncestor("Stories")
local SharedStoryHooks = require(stories.Helpers.SharedStoryHooks)
local CreateStory = require(stories.Helpers.CreateStory)

workspace:SetAttribute("FocusActionTrigger", false)

local function story()
	local isDisabled, setIsDisabled = React.useState(false)
	local disabled = SharedStoryHooks.useAttribute(workspace, "Disabled", false)
	local focusLenseSizeRef = React.useRef(Vector2.zero)

<<<<<<<< HEAD:src/Main/UserInterface/Stories/CroppedViewport.story.luau
	return React.createElement(CroppedViewport, {
========
	return React.createElement(FullViewport, {
>>>>>>>> full-viewport-captures:src/Main/UserInterface/Stories/FullViewport.story.luau
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
		Disabled = isDisabled or disabled,
	})
end

return CreateStory(story)
