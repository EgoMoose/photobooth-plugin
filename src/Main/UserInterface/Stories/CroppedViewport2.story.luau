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
	local lenseRectRef = React.useRef(Rect.new(0, 0, 0, 0))

	return React.createElement(CroppedViewport, {
		LenseRectRef = lenseRectRef,
	})
end

return {
	react = React,
	reactRoblox = ReactRoblox,
	story = CreateStory.theme(story),
}
