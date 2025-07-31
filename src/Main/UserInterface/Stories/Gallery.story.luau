--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local StudioComponents = require(pluginRoot.Packages.StudioComponents)
local React = require(pluginRoot.Packages.React)

local Constants = require(pluginRoot.Constants)

local uiRoot = script:FindFirstAncestor("UserInterface")
local Gallery = require(uiRoot.Components.Gallery)

local stories = script:FindFirstAncestor("Stories")
local SharedStoryHooks = require(stories.Helpers.SharedStoryHooks)
local CreateStory = require(stories.Helpers.CreateStory)

local function Widget(props: { Size: UDim2 })
	local theme = StudioComponents.useTheme()
	local disabled = SharedStoryHooks.useAttribute(workspace, "Disabled", false)
	local backgroundType, setBackgroundType = React.useState("Checkerboard")

	return React.createElement("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = props.Size,
		BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainBackground),
		BorderColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Border),
	}, {
		Widget = React.createElement(Gallery, {
			UploadCallback = function(details)
				print(details)
				return true, 1234
			end,

			BackgroundType = backgroundType,
			SetBackgroundType = setBackgroundType,

			Disabled = disabled,
		}),
	})
end

local function story()
	local selectedTab, setSelectedTab = React.useState("Small")

	return React.createElement(StudioComponents.TabContainer, {
		SelectedTab = selectedTab,
		OnTabSelected = setSelectedTab,
	}, {
		["Small"] = {
			LayoutOrder = 1,
			Content = React.createElement(Widget, {
				Size = UDim2.fromOffset(Constants.DockWidgetSize.X, Constants.DockWidgetSize.Y),
			}),
		},
		["Medium"] = {
			LayoutOrder = 2,
			Content = React.createElement(Widget, {
				Size = UDim2.fromScale(0.5, 0.5),
			}),
		},
		["Large"] = {
			LayoutOrder = 2,
			Content = React.createElement(Widget, {
				Size = UDim2.new(1, -30, 1, -30),
			}),
		},
	})
end

return CreateStory(story)
