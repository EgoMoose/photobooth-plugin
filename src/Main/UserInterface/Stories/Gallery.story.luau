--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local StudioComponents = require(pluginRoot.Packages.StudioComponents)
local React = require(pluginRoot.Packages.React)

local uiRoot = script:FindFirstAncestor("UserInterface")
local Gallery = require(uiRoot.Components.Gallery)

local stories = script:FindFirstAncestor("Stories")
local CreateStory = require(stories.Helpers.CreateStory)

local function Widget(props: { Size: UDim2 })
	local theme = StudioComponents.useTheme()
	local backgroundType, setBackgroundType = React.useState("Checkerboard")
	local isExpanded, setIsExpanded = React.useState(true)

	return React.createElement("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = props.Size,
		BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainBackground),
		BorderColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Border),
	}, {
		Widget = React.createElement(Gallery, {
			IsExpanded = isExpanded,
			SetIsExpanded = setIsExpanded,

			BackgroundType = backgroundType,
			SetBackgroundType = setBackgroundType,

			TryUpload = function(i, name)
				print(i, name)
				task.wait(1)
				return if i % 2 == 1 then 123 else nil
			end,
			OnUploadComplete = function(completed)
				print(completed)
			end,

			Disabled = false,
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
				Size = UDim2.fromOffset(500, 350),
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

return {
	story = CreateStory(story),
}
