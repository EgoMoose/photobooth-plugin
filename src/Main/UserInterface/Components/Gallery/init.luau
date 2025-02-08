--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local StudioComponents = require(pluginRoot.Packages.StudioComponents)
local React = require(pluginRoot.Packages.React)

local uiRoot = script:FindFirstAncestor("UserInterface")
local UploadPrompt = require(uiRoot.Components.UploadPrompt)
local Constants = require(uiRoot.Constants)
local Hooks = require(uiRoot.Hooks)

local ConfigurationWindow = require(script.ConfigurationWindow)
local ImageViewer = require(script.ImageViewer)
local ActionBar = require(script.ActionBar)

export type Props = {
	UploadCallback: UploadPrompt.UploadCallback,
	BackgroundType: string,
	SetBackgroundType: (string) -> (),
	Disabled: boolean,
}

type WindowContainerProps = {
	AnchorPoint: Vector2,
	Position: UDim2,
	Size: UDim2,
	children: React.ReactNode,
}

local function WindowContainer(props: WindowContainerProps)
	local theme = StudioComponents.useTheme()

	return React.createElement("Frame", {
		AnchorPoint = props.AnchorPoint,
		Position = props.Position,
		Size = props.Size,
		BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainBackground),
		BorderColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Border),
	}, {
		UISizeConstraint = React.createElement("UISizeConstraint", {
			MinSize = Vector2.new(Constants.DockWidgetSize.X - 20, Constants.DockWidgetSize.Y - 20),
			MaxSize = Vector2.new((Constants.DockWidgetSize.X - 20) * 2, (Constants.DockWidgetSize.Y - 20) * 2),
		}),
	}, props.children)
end

local function Gallery(props: Props)
	local selectedTab, setSelectedTab = React.useState("Viewer")
	local uploadInfo, setUploadInfo = React.useState(nil :: ActionBar.UploadInfo?)
	local editImage, editImageName = Hooks.useSelectedEditableImage()

	return React.createElement("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = -1, -- Fixes dropdown issues
	}, {
		LoadingOverlay = props.Disabled and React.createElement("ImageButton", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0.7,
			AutoButtonColor = false,
			ZIndex = 3,
		}, {
			Loading = props.Disabled and React.createElement(StudioComponents.LoadingDots, {
				Size = UDim2.fromScale(1, 1),
			}),
		}),

		WindowOverlay = (not not uploadInfo or selectedTab == "Settings") and React.createElement("ImageButton", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0.7,
			AutoButtonColor = false,
			ZIndex = 2,
		}, {
			Window = React.createElement(WindowContainer, {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.new(1, -20, 1, -20),
			}, {
				UploadPrompt = uploadInfo and React.createElement(UploadPrompt, {
					PlaceholderTitle = uploadInfo.Title,
					EditableImage = uploadInfo.EditableImage,

					OnConfirm = props.UploadCallback,
					CloseCallback = function()
						setUploadInfo(nil :: any)
					end,

					Disabled = not not props.Disabled,
				}),

				Configuration = not uploadInfo and React.createElement(ConfigurationWindow, {
					OnConfirm = function()
						setSelectedTab("Viewer")
					end,

					Disabled = props.Disabled :: boolean,
				}),
			}),
		}),

		Tabs = React.createElement(StudioComponents.TabContainer, {
			SelectedTab = selectedTab,
			OnTabSelected = setSelectedTab,
			Disabled = (props.Disabled or selectedTab == "Settings"),
			ZIndex = 1,
		}, {
			["Viewer"] = {
				LayoutOrder = 1,
				Content = React.createElement("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(1, 1),
				}, {
					ImageViewer = React.createElement(ImageViewer, {
						AnchorPoint = Vector2.new(0, 0),
						Position = UDim2.fromScale(0, 0),
						Size = UDim2.new(1, 0, 1, -36),

						EditableImage = editImage,
						EditableImageName = editImageName,

						BackgroundType = props.BackgroundType,
						SetBackgroundType = props.SetBackgroundType,
					}),
					ActionBar = React.createElement(ActionBar, {
						AnchorPoint = Vector2.new(0, 1),
						Position = UDim2.fromScale(0, 1),
						Size = UDim2.new(1, 0, 0, 36),

						EditableImage = editImage,
						EditableImageName = editImageName,

						OnUpload = function(info)
							setUploadInfo(info)
						end,

						Disabled = props.Disabled,
					}),
				}),
			},
			["Settings"] = {
				LayoutOrder = 2,
				Content = React.createElement("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(1, 1),
				}, {
					ActionBar = React.createElement(ActionBar, {
						AnchorPoint = Vector2.new(0, 1),
						Position = UDim2.fromScale(0, 1),
						Size = UDim2.new(1, 0, 0, 36),

						EditableImage = editImage,
						EditableImageName = editImageName,

						OnUpload = function()
							-- Do nothing, the button is disabled anyways
						end,

						Disabled = true,
					}),
				}),
			},
		}),
	})
end

return Gallery
