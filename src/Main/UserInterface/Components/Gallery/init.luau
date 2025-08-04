--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local StudioComponents = require(pluginRoot.Packages.StudioComponents)
local React = require(pluginRoot.Packages.React)

local uiRoot = script:FindFirstAncestor("UserInterface")
local Hooks = require(uiRoot.Hooks)

local ConfigurationWindow = require(script.ConfigurationWindow)
local ImageInterface = require(script.ImageInterface)
local UploadWindow = require(script.UploadWindow)
local ActionBar = require(script.ActionBar)

export type Props = {
	IsExpanded: boolean,
	SetIsExpanded: (boolean) -> (),

	BackgroundType: string,
	SetBackgroundType: (string) -> (),

	TryUpload: (number, string, EditableImage) -> number?,
	OnUploadComplete: ({ { Name: string, AssetId: number } }) -> (),

	OnImport: () -> (),

	Disabled: boolean,
}

local function useUploadInfos()
	local uploadInfos, setUploadInfos = React.useState(nil :: { Hooks.EditableImageInfo }?)
	return uploadInfos :: { Hooks.EditableImageInfo }?, setUploadInfos :: ({ Hooks.EditableImageInfo }?) -> ()
end

local function Gallery(props: Props)
	local selectedTab, setSelectedTab = React.useState("Viewer")

	local selection = Hooks.useSelection()
	local editImageInfos = Hooks.useEditableImageInfos(selection)
	local selectedIndex, setSelectedIndex = React.useState(1)
	local uploadExclusions, setUploadExclusions = React.useState({})
	local uploadInfos, setUploadInfos = useUploadInfos()

	return React.createElement("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ClipsDescendants = true,
		ZIndex = -1, -- Fixes dropdown issues
	}, {
		LoadingOverlay = props.Disabled and React.createElement("ImageButton", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0.7,
			AutoButtonColor = false,
			ZIndex = 4,
		}, {
			Loading = React.createElement(StudioComponents.LoadingDots, {
				Size = UDim2.fromScale(1, 1),
			}),
		}),

		Tabs = React.createElement(StudioComponents.TabContainer, {
			SelectedTab = selectedTab,
			OnTabSelected = setSelectedTab,
			Disabled = (props.Disabled or selectedTab == "Settings"),
			Size = UDim2.new(1, 0, 0, 30),
			ZIndex = if selectedTab ~= "Viewer" then 2 else 1,
		}, {
			["Viewer"] = {
				LayoutOrder = 1,
			},
			["Settings"] = {
				LayoutOrder = 2,
			},
		}),

		Overlay = (uploadInfos or selectedTab == "Settings") and React.createElement("ImageButton", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0.7,
			AutoButtonColor = false,
			ZIndex = 3,
		}, {
			Upload = uploadInfos and React.createElement(UploadWindow, {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.new(1, -20, 1, -20),

				UploadInfos = uploadInfos,
				SetUploadInfos = setUploadInfos,

				TryUpload = props.TryUpload,
				OnUploadComplete = props.OnUploadComplete,

				OnCancel = function()
					setUploadInfos(nil)
				end,

				Disabled = props.Disabled,
			}),
			Configuration = selectedTab == "Settings" and React.createElement(ConfigurationWindow, {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.new(1, -20, 1, -20),

				OnConfirm = function()
					setSelectedTab("Viewer")
				end,

				Disabled = props.Disabled,
			}),
		}),

		ImageInterface = React.createElement(ImageInterface, {
			AnchorPoint = Vector2.new(0, 0),
			Position = UDim2.fromOffset(0, 30),
			Size = UDim2.new(1, 0, 1, -66),

			EditableImageInfos = editImageInfos,

			IsExpanded = props.IsExpanded,
			SetIsExpanded = props.SetIsExpanded,

			SelectedIndex = selectedIndex,
			SetSelectedIndex = setSelectedIndex,

			UploadExclusions = uploadExclusions,
			SetUploadExclusions = setUploadExclusions,

			BackgroundType = props.BackgroundType,
			SetBackgroundType = props.SetBackgroundType,

			OnUpload = function()
				local filteredInfos = {}
				for _, info in editImageInfos do
					if not uploadExclusions[info.Instance] then
						table.insert(filteredInfos, info)
					end
				end

				setUploadInfos(filteredInfos)
			end,

			SinkInput = props.Disabled or selectedTab == "Settings" or not not uploadInfos,
			Disabled = props.Disabled or selectedTab == "Settings",
		}),

		ActionBar = React.createElement(ActionBar, {
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.fromScale(0, 1),
			Size = UDim2.new(1, 0, 0, 36),

			SelectedIndex = selectedIndex,
			SetSelectedIndex = setSelectedIndex,
			SelectedCount = #editImageInfos,

			OnImport = props.OnImport,

			Disabled = props.Disabled or selectedTab == "Settings",
		}),
	})
end

return Gallery
