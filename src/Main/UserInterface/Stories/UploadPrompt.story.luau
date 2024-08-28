--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local StudioComponents = require(pluginRoot.Packages.StudioComponents)
local React = require(pluginRoot.Packages.React)

local uiRoot = script:FindFirstAncestor("UserInterface")
local UploadPrompt = require(uiRoot.Components.UploadPrompt)

local stories = script:FindFirstAncestor("Stories")
local SharedStoryAssets = require(stories.Helpers.SharedStoryAssets)
local CreateStory = require(stories.Helpers.CreateStory)

local function Widget(props: { Size: UDim2 })
	local theme = StudioComponents.useTheme()

	return React.createElement("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainBackground),
		BorderColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Border),
		Size = props.Size,
	}, {
		UploadPrompt = React.createElement(UploadPrompt, {
			PlaceholderTitle = DateTime.now():ToIsoDate(),
			EditableImage = SharedStoryAssets.getEditableImage(),

			OnConfirm = function(details)
				print(details)
				return true, 1234
			end,

			CloseCallback = function()
				print("Close!")
			end,

			Disabled = false,
		}),
	})
end

local function Story()
	local selectedTab, setSelectedTab = React.useState("Small")

	return React.createElement(StudioComponents.TabContainer, {
		SelectedTab = selectedTab,
		OnTabSelected = setSelectedTab,
	}, {
		["Small"] = {
			LayoutOrder = 1,
			Content = React.createElement(Widget, {
				Size = UDim2.fromOffset(260, 300),
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

return CreateStory(Story)
