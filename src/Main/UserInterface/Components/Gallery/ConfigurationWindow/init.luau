local pluginRoot = script:FindFirstAncestor("PluginRoot")
local StudioComponents = require(pluginRoot.Packages.StudioComponents)
local ReactRipple = require(pluginRoot.Packages.ReactRipple)
local Semver = require(pluginRoot.Packages.Semver)
local Lucide = require(pluginRoot.Packages.Lucide)
local React = require(pluginRoot.Packages.React)

local StudioMode = require(pluginRoot.Utilities.StudioMode)
local Wally = require(pluginRoot.Wally)

local Constants = require(pluginRoot.Constants)

local Screenshot = require(pluginRoot.Main.Photo.Captures.Screenshot)
local Captures = require(pluginRoot.Main.Photo.Captures)
local State = require(pluginRoot.Main.State)

local uiRoot = script:FindFirstAncestor("UserInterface")
local VerticalScroll = require(uiRoot.Components.Shared.VerticalScroll)
local Hooks = require(uiRoot.Hooks)

local SettingsGroup = require(script.SettingsGroup)

local HORIZONTAL_SPLIT = 0.5
local IS_TEAM_CREATE = StudioMode.isTeamCreate()

export type Props = {
	AnchorPoint: Vector2,
	Position: UDim2,
	Size: UDim2,

	OnConfirm: () -> (),
	Disabled: boolean,
}

type GroupsProps = {
	RootProps: Props,
	State: State.State,
	MutateState: ((State.State) -> ()) -> (),
	LayoutOrder: number,
}

type DropdownItemDetail = {
	Id: string,
	Text: string,
}

local function GeneralGroup(props: GroupsProps)
	local theme = StudioComponents.useTheme()

	local isRefreshing, setIsRefreshing = React.useState(false)
	local refreshHovered, setRefreshHovered = React.useState(false)
	local refreshIcon = assert(Lucide.GetAsset("refresh-cw", 16))

	return React.createElement(SettingsGroup, {
		Disabled = props.RootProps.Disabled,
		LayoutOrder = props.LayoutOrder,
		HorizontalSplit = HORIZONTAL_SPLIT,
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
							props.MutateState(function(state)
								state.temporary.scaleOS = Screenshot.calculateScaleOS()
							end)
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
							else `{props.State.temporary.scaleOS.X}, {props.State.temporary.scaleOS.Y}`,
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
						Value = props.State.saved.alphaBleedingEnabled,
						OnChanged = function()
							props.MutateState(function(state)
								state.saved.alphaBleedingEnabled = not state.saved.alphaBleedingEnabled
							end)
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
						Value = props.State.saved.bindingsEnabled,
						OnChanged = function()
							props.MutateState(function(state)
								state.saved.bindingsEnabled = not state.saved.bindingsEnabled
							end)
						end,
					}),
				}),
			},
		},
	})
end

local function ViewportGroup(props: GroupsProps)
	local captureTypeIndex = props.State.temporary.viewportCaptureTypeIndex
	local dropdownItems = React.useMemo(function()
		local items: { DropdownItemDetail } = {}
		for i, captureType in Captures.Viewport.Order do
			table.insert(items, {
				Id = tostring(i),
				Text = captureType,
			})
		end
		return items
	end, {})

	return React.createElement(SettingsGroup, {
		Disabled = props.RootProps.Disabled,
		LayoutOrder = props.LayoutOrder,
		HorizontalSplit = HORIZONTAL_SPLIT,
		Title = "Viewport",
		List = {
			{
				Name = "Fullscreen",
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
						Value = props.State.temporary.isFullscreen,
						OnChanged = function()
							props.MutateState(function(state)
								state.temporary.isFullscreen = not state.temporary.isFullscreen
							end)
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
						Items = dropdownItems :: { any },
						SelectedItem = tostring(captureTypeIndex),
						OnItemSelected = function(id: string?)
							local index = tonumber(id)
							if index then
								props.MutateState(function(state)
									state.temporary.viewportCaptureTypeIndex = index
								end)
							end
						end,
					}),
				}),
			},
		},
	})
end

local function UserInterfaceGroup(props: GroupsProps)
	local captureTypeIndex = props.State.temporary.uiCaptureTypeIndex
	local dropdownItems = React.useMemo(function()
		local items: { DropdownItemDetail } = {}
		for i, captureType in Captures.UserInterface.Order do
			table.insert(items, {
				Id = tostring(i),
				Text = captureType,
			})
		end
		return items
	end, {})

	return React.createElement(SettingsGroup, {
		Disabled = props.RootProps.Disabled,
		LayoutOrder = props.LayoutOrder,
		HorizontalSplit = HORIZONTAL_SPLIT,
		Title = "User Interface",
		List = {
			{
				Name = "Capture Type",
				Node = React.createElement(React.Fragment, {}, {
					Input = React.createElement(StudioComponents.Dropdown, {
						Disabled = props.RootProps.Disabled,
						Size = UDim2.new(1, -1, 1, 0),
						Position = UDim2.fromOffset(1, 0),
						Items = dropdownItems :: { any },
						SelectedItem = tostring(captureTypeIndex),
						OnItemSelected = function(id: string?)
							local index = tonumber(id)
							if index then
								props.MutateState(function(state)
									state.temporary.uiCaptureTypeIndex = index
								end)
							end
						end,
					}),
				}),
			},
		},
	})
end

local function DevGroup(props: GroupsProps)
	return React.createElement(SettingsGroup, {
		Disabled = props.RootProps.Disabled,
		LayoutOrder = props.LayoutOrder,
		HorizontalSplit = HORIZONTAL_SPLIT,
		Title = "Developer",
		List = {
			{
				Name = if props.State.temporary.isExperimentalMode == props.State.saved.experimentalModeEnabled
					then "Experimental"
					else "Experimental*",
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
						Value = props.State.saved.experimentalModeEnabled,
						OnChanged = function()
							props.MutateState(function(state)
								state.saved.experimentalModeEnabled = not state.saved.experimentalModeEnabled
							end)
						end,
					}),
				}),
			},
		},
	})
end

local function useScrollTransparency()
	local transparencyBinding, control = ReactRipple.useSpring(1)
	local transparency = Hooks.useBindingState(transparencyBinding)
	return transparency, React.useCallback(function(value: number)
		control:setGoal(value)
	end, {})
end

local function ConfigurationWindow(props: Props)
	local theme = StudioComponents.useTheme()
	local latestVersion = Hooks.useLatestVersion()
	local isLocalPlugin = Hooks.useIsLocalPlugin()

	local state = Hooks.useState()
	local mutateState = React.useCallback(State.mutate, {})

	local scrollTransparency, setScrollTransparency = useScrollTransparency()

	local versionText = `v{Wally.package.version}-{if isLocalPlugin then "local" else "cloud"}`
	local needsRestart = state.temporary.isExperimentalMode ~= state.saved.experimentalModeEnabled
	if needsRestart and Constants.AllowExperimentalMode and not IS_TEAM_CREATE then
		versionText = "requires restart*\n" .. versionText
	elseif Semver.validateVersion(Wally.package.version) and Semver.cmp(latestVersion, ">", Wally.package.version) then
		versionText = "update available*\n" .. versionText
	end

	return React.createElement("Frame", {
		AnchorPoint = props.AnchorPoint,
		Position = props.Position,
		Size = props.Size,

		BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainBackground),
		BorderColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Border),
	}, {
		UISizeConstraint = React.createElement("UISizeConstraint", {
			MinSize = Vector2.new(Constants.ConfigWindowSize.X - 20, Constants.ConfigWindowSize.Y - 20),
			MaxSize = Vector2.new((Constants.ConfigWindowSize.X - 20) * 2, (Constants.ConfigWindowSize.Y - 20) * 2),
		}),
		AspectConstraint = React.createElement("UIAspectRatioConstraint", {
			AspectRatio = Constants.ConfigWindowSize.X / Constants.ConfigWindowSize.Y,
		}),
	}, {
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

			[React.Event.MouseEnter] = function()
				setScrollTransparency(0.6)
			end,
			[React.Event.MouseLeave] = function()
				setScrollTransparency(1)
			end,
		}, {
			Scroll = React.createElement(VerticalScroll, {
				AnchorPoint = Vector2.zero,
				Position = UDim2.fromScale(0, 0),
				Size = UDim2.fromScale(1, 1),

				ScrollBarThickness = 2,
				ScrollBarTransparency = scrollTransparency,

				GradientColor = theme:GetColor(Enum.StudioStyleGuideColor.MainBackground),
				GradientHeight = 8,

				Disabled = props.Disabled,
			}, {
				UILayout = React.createElement("UIListLayout", {
					FillDirection = Enum.FillDirection.Vertical,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 0),
				}),
				Padding = React.createElement("UIPadding", {
					PaddingLeft = UDim.new(0, 4),
					PaddingRight = UDim.new(0, 4),
					PaddingTop = UDim.new(0, 4),
					PaddingBottom = UDim.new(0, 4 + 8),
				}),

				General = React.createElement(GeneralGroup, {
					RootProps = props,
					State = state,
					MutateState = mutateState,
					LayoutOrder = 1,
				}),
				Viewport = React.createElement(ViewportGroup, {
					RootProps = props,
					State = state,
					MutateState = mutateState,
					LayoutOrder = 2,
				}),
				UserInterface = React.createElement(UserInterfaceGroup, {
					RootProps = props,
					State = state,
					MutateState = mutateState,
					LayoutOrder = 3,
				}),
				Dev = Constants.AllowExperimentalMode and not IS_TEAM_CREATE and React.createElement(DevGroup, {
					RootProps = props,
					State = state,
					MutateState = mutateState,
					LayoutOrder = 4,
				}),
			}),
		}),
		Version = React.createElement(StudioComponents.Label, {
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.fromScale(0, 1),
			Size = UDim2.fromOffset(80, 28),
			Text = versionText,
			TextSize = 6,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Bottom,
			Disabled = true,
			ZIndex = -1,
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
