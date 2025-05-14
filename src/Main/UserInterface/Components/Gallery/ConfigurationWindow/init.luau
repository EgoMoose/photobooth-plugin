--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local StudioComponents = require(pluginRoot.Packages.StudioComponents)
local Lucide = require(pluginRoot.Packages.Lucide)
local React = require(pluginRoot.Packages.React)
local Wally = require(pluginRoot.Wally)

local Screenshot = require(pluginRoot.Main.Photo.Captures.Screenshot)
local Captures = require(pluginRoot.Main.Photo.Captures)
local Photo = require(pluginRoot.Main.Photo)

local uiRoot = script:FindFirstAncestor("UserInterface")
local Constants = require(uiRoot.Constants)
local Hooks = require(uiRoot.Hooks)

local SettingsGroup = require(script.SettingsGroup)

export type Props = {
	OnConfirm: () -> (),
	Disabled: boolean,
}

type GroupsProps = {
	RootProps: Props,
	Configuration: Photo.Configuration,
	SetConfiguration: (Photo.Configuration) -> (),
	LayoutOrder: number,
}

local function GeneralGroup(props: GroupsProps)
	local theme = StudioComponents.useTheme()

	local isRefreshing, setIsRefreshing = React.useState(false)
	local refreshHovered, setRefreshHovered = React.useState(false)
	local refreshIcon = assert(Lucide.GetAsset("refresh-cw", 16))

	return React.createElement(SettingsGroup, {
		Disabled = props.RootProps.Disabled,
		LayoutOrder = props.LayoutOrder,
		HorizontalSplit = 0.5,
		Title = "General",
		List = {
			{
				Name = "OS Scale",
				Node = React.createElement("ImageButton", {
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,

					[React.Event.InputBegan] = function(_, input)
						if input.UserInputType == Enum.UserInputType.MouseMovement then
							setRefreshHovered(true)
						end
					end,
					[React.Event.InputEnded] = function(_, input)
						if input.UserInputType == Enum.UserInputType.MouseMovement then
							setRefreshHovered(false)
						end
					end,

					[React.Event.Activated] = function()
						if not isRefreshing then
							setIsRefreshing(true)
							local config = table.clone(props.Configuration)
							config.ScaleOS = Screenshot.calculateScaleOS()
							props.SetConfiguration(config)
							setIsRefreshing(false)
						end
					end,
				}, {
					Padding = React.createElement("UIPadding", {
						PaddingLeft = UDim.new(0, 8),
						PaddingRight = UDim.new(0, 8),
						PaddingTop = UDim.new(0, 4),
						PaddingBottom = UDim.new(0, 4),
					}),

					Label = React.createElement(StudioComponents.Label, {
						Disabled = true,
						Size = UDim2.fromScale(1, 1),
						TextXAlignment = Enum.TextXAlignment.Left,
						Text = if isRefreshing
							then "..."
							else `{props.Configuration.ScaleOS.X}, {props.Configuration.ScaleOS.Y}`,
					}),
					Refresh = React.createElement("ImageLabel", {
						AnchorPoint = Vector2.new(1, 0.5),
						Position = UDim2.new(1, 0, 0.5, 0),
						Size = UDim2.fromOffset(refreshIcon.ImageRectSize.X, refreshIcon.ImageRectSize.Y),
						BackgroundTransparency = 1,
						ImageRectOffset = refreshIcon.ImageRectOffset,
						ImageRectSize = refreshIcon.ImageRectSize,
						Image = refreshIcon.Url,
						ImageColor3 = theme:GetColor(
							Enum.StudioStyleGuideColor.MainText,
							if not refreshHovered
								then Enum.StudioStyleGuideModifier.Disabled
								else Enum.StudioStyleGuideModifier.Default
						),
					}),
				}),
			},
			{
				Name = "Alpha Bleed",
				Node = React.createElement(React.Fragment, {}, {
					Padding = React.createElement("UIPadding", {
						PaddingLeft = UDim.new(0, 5),
						PaddingRight = UDim.new(0, 5),
						PaddingTop = UDim.new(0, 4),
						PaddingBottom = UDim.new(0, 4),
					}),
					Checkbox = React.createElement(StudioComponents.Checkbox, {
						Disabled = props.RootProps.Disabled,
						Size = UDim2.fromScale(1, 1),
						Value = props.Configuration.AlphaBleedingEnabled,
						OnChanged = function()
							local config = table.clone(props.Configuration)
							config.AlphaBleedingEnabled = not config.AlphaBleedingEnabled
							props.SetConfiguration(config)
						end,
					}),
				}),
			},
			{
				Name = "Bindings",
				Node = React.createElement(React.Fragment, {}, {
					Padding = React.createElement("UIPadding", {
						PaddingLeft = UDim.new(0, 5),
						PaddingRight = UDim.new(0, 5),
						PaddingTop = UDim.new(0, 4),
						PaddingBottom = UDim.new(0, 4),
					}),
					Checkbox = React.createElement(StudioComponents.Checkbox, {
						Disabled = props.RootProps.Disabled,
						Size = UDim2.fromScale(1, 1),
						Value = props.Configuration.BindingsEnabled,
						OnChanged = function()
							local config = table.clone(props.Configuration)
							config.BindingsEnabled = not config.BindingsEnabled
							props.SetConfiguration(config)
						end,
					}),
				}),
			},
		},
	})
end

local function ViewportGroup(props: GroupsProps)
	return React.createElement(SettingsGroup, {
		Disabled = props.RootProps.Disabled,
		LayoutOrder = props.LayoutOrder,
		HorizontalSplit = 0.5,
		Title = "Viewport",
		List = {
			{
				Name = "Fullscreen",
				Node = Screenshot.isFullscreenAllowed() and React.createElement(React.Fragment, {}, {
					Padding = React.createElement("UIPadding", {
						PaddingLeft = UDim.new(0, 5),
						PaddingRight = UDim.new(0, 5),
						PaddingTop = UDim.new(0, 4),
						PaddingBottom = UDim.new(0, 4),
					}),
					Checkbox = React.createElement(StudioComponents.Checkbox, {
						Disabled = props.RootProps.Disabled,
						Size = UDim2.fromScale(1, 1),
						Value = props.Configuration.IsFullscreen,
						OnChanged = function()
							local config = table.clone(props.Configuration)
							config.IsFullscreen = not config.IsFullscreen
							props.SetConfiguration(config)
						end,
					}),
				}),
			},
			{
				Name = "Capture Type",
				Node = React.createElement(React.Fragment, {}, {
					Input = React.createElement(StudioComponents.Dropdown, {
						Disabled = props.RootProps.Disabled,
						Size = UDim2.new(1, -1, 1, 0),
						Position = UDim2.fromOffset(1, 0),
						Items = Captures.Viewport.Order,
						SelectedItem = props.Configuration.ViewportCaptureType :: string,
						OnItemSelected = function(item: string?)
							if item then
								local config = table.clone(props.Configuration)
								config.ViewportCaptureType = item :: Captures.ViewportCaptureTypes
								props.SetConfiguration(config)
							end
						end,
					}),
				}),
			},
		},
	})
end

local function UserInterfaceGroup(props: GroupsProps)
	return React.createElement(SettingsGroup, {
		Disabled = props.RootProps.Disabled,
		LayoutOrder = props.LayoutOrder,
		HorizontalSplit = 0.5,
		Title = "User Interface",
		List = {
			{
				Name = "Capture Type",
				Node = React.createElement(React.Fragment, {}, {
					Input = React.createElement(StudioComponents.Dropdown, {
						Disabled = props.RootProps.Disabled,
						Size = UDim2.new(1, -1, 1, 0),
						Position = UDim2.fromOffset(1, 0),
						Items = Captures.UserInterface.Order,
						SelectedItem = props.Configuration.UserInterfaceCaptureType :: string,
						OnItemSelected = function(item: string?)
							if item then
								local config = table.clone(props.Configuration)
								config.UserInterfaceCaptureType = item :: Captures.UICaptureTypes
								props.SetConfiguration(config)
							end
						end,
					}),
				}),
			},
		},
	})
end

local function ConfigurationWindow(props: Props)
	local theme = StudioComponents.useTheme()
	local isLocalPlugin = Hooks.useIsLocalPlugin()
	local configuration, setConfiguration = Hooks.usePhotoConfiguration()

	return React.createElement(React.Fragment, nil, {
		Padding = React.createElement("UIPadding", {
			PaddingLeft = UDim.new(0, 4),
			PaddingRight = UDim.new(0, 4),
			PaddingTop = UDim.new(0, 4),
			PaddingBottom = UDim.new(0, 4),
		}),
		Title = React.createElement(StudioComponents.Label, {
			Position = UDim2.fromOffset(0, 0),
			Size = UDim2.new(1, 0, 0, 20),
			Text = "Settings",
			TextXAlignment = Enum.TextXAlignment.Left,
		}, {
			Padding = React.createElement("UIPadding", {
				PaddingLeft = UDim.new(0, 2),
				PaddingRight = UDim.new(0, 0),
				PaddingTop = UDim.new(0, 0),
				PaddingBottom = UDim.new(0, 0),
			}),
		}),
		Inner = React.createElement("Frame", {
			Position = UDim2.fromOffset(0, 24),
			Size = UDim2.new(1, 0, 1, -56 - 2),
			BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainBackground),
			BorderColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Border),
		}, {
			Scroll = React.createElement(StudioComponents.ScrollFrame, {
				Layout = {
					ClassName = "UIListLayout",
					Padding = UDim.new(0, 0),
					FillDirection = Enum.FillDirection.Vertical,
					SortOrder = Enum.SortOrder.LayoutOrder,
				},
				PaddingLeft = UDim.new(0, 4),
				PaddingRight = UDim.new(0, 4),
				PaddingTop = UDim.new(0, 4),
				PaddingBottom = UDim.new(0, 4),
			}, {
				Content = React.createElement(React.Fragment, nil, {
					General = React.createElement(GeneralGroup, {
						RootProps = props,
						Configuration = configuration,
						SetConfiguration = setConfiguration,
						LayoutOrder = 1,
					}),
					Viewport = React.createElement(ViewportGroup, {
						RootProps = props,
						Configuration = configuration,
						SetConfiguration = setConfiguration,
						LayoutOrder = 2,
					}),
					UserInterface = React.createElement(UserInterfaceGroup, {
						RootProps = props,
						Configuration = configuration,
						SetConfiguration = setConfiguration,
						LayoutOrder = 3,
					}),
				}),
			}),
		}),
		Version = React.createElement(StudioComponents.Label, {
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.fromScale(0, 1),
			Size = UDim2.fromOffset(80, 28),
			Text = `v{Wally.package.version}-{if isLocalPlugin then "local" else "cloud"}`,
			TextSize = 6,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Bottom,
			Disabled = true,
		}, {
			Padding = React.createElement("UIPadding", {
				PaddingLeft = UDim.new(0, 2),
				PaddingRight = UDim.new(0, 0),
				PaddingTop = UDim.new(0, 0),
				PaddingBottom = UDim.new(0, 0),
			}),
		}),
		Close = React.createElement(StudioComponents.MainButton, {
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.fromScale(1, 1),
			Size = UDim2.fromOffset(80, 28),
			Text = "Confirm",
			OnActivated = props.OnConfirm,
			Disabled = props.Disabled,
		}),
	})
end

return ConfigurationWindow
