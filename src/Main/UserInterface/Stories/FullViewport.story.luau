--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local React = require(pluginRoot.Packages.React)

local uiRoot = script:FindFirstAncestor("UserInterface")
local FullViewport = require(uiRoot.Components.FullViewport)

local stories = script:FindFirstAncestor("Stories")
local SharedStoryHooks = require(stories.Helpers.SharedStoryHooks)
local CreateStory = require(stories.Helpers.CreateStory)

workspace:SetAttribute("FocusActionTrigger", false)

local function story()
	local isDisabled, setIsDisabled = React.useState(false)
	local disabled = SharedStoryHooks.useAttribute(workspace, "Disabled", false)

	return React.createElement(FullViewport, {
		OnCapture = function(rect)
			setIsDisabled(true)
			print(table.concat({
				"",
				"Viewport Capture",
				`> Rect: {rect}`,
				`> Size: ({rect.Width}, {rect.Height})`,
			}, "\n"))
			task.wait(1)
			setIsDisabled(false)
		end,
		Disabled = isDisabled or disabled,
	})
end

return CreateStory(story)
