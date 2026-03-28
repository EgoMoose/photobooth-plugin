--!strict

local CollectionService = game:GetService("CollectionService") :: CollectionService

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local StudioComponents = require(pluginRoot.Packages.StudioComponents)
local ReactRoblox = require(pluginRoot.Packages.ReactRoblox)
local React = require(pluginRoot.Packages.React)

local State = require(pluginRoot.Main.State)
State.storybook()

local Photo = require(pluginRoot.Main.Photo)

local LOADED_TAG = "PhotoboothStoryImage"

return {
	react = React,
	reactRoblox = ReactRoblox,
	story = function()
		return React.createElement(React.Fragment, nil, {
			Layout = React.createElement("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				FillDirection = Enum.FillDirection.Horizontal,
				VerticalAlignment = Enum.VerticalAlignment.Top,
				HorizontalAlignment = Enum.HorizontalAlignment.Left,
				Padding = UDim.new(0, 8),
			}),

			Load = React.createElement(StudioComponents.MainButton, {
				Size = UDim2.fromOffset(100, 32),
				Text = "Load",
				OnActivated = function()
					local results = Photo.importFiles(game:GetService("StarterGui"))
					for _, meshPart in results do
						CollectionService:AddTag(meshPart, LOADED_TAG)
					end
				end,
			}),
			CleanUp = React.createElement(StudioComponents.Button, {
				Size = UDim2.fromOffset(100, 32),
				Text = "Clean Up",
				OnActivated = function()
					for _, instance in CollectionService:GetTagged(LOADED_TAG) do
						instance:Destroy()
					end
				end,
			}),
		})
	end,
}
