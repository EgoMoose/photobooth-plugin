--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local StudioComponents = require(pluginRoot.Packages.StudioComponents)
local Lucide = require(pluginRoot.Packages.Lucide)
local React = require(pluginRoot.Packages.React)
local Constants = require(pluginRoot.Constants)

local uiRoot = script:FindFirstAncestor("UserInterface")
local LucideButton = require(uiRoot.Components.Shared.LucideButton)

local useImageControls = require(script.Parent.ImageInterface.useImageControls)

local IMPORT_ICON = assert(Lucide.GetAsset("image-up", 16))
local RIGHT_ICON = assert(Lucide.GetAsset("chevron-right", 16))
local LEFT_ICON = assert(Lucide.GetAsset("chevron-left", 16))
local ZOOM_IN_ICON = assert(Lucide.GetAsset("zoom-in", 16))
local ZOOM_OUT_ICON = assert(Lucide.GetAsset("zoom-out", 16))
local RESET_ZOOM_ICON = assert(Lucide.GetAsset("maximize", 16))

local CONTROLS_ENABLED = Constants.GalleryImageControlsEnabled
local BUTTON_ZOOM_STEP = 1.25

export type Props = {
	AnchorPoint: Vector2,
	Position: UDim2,
	Size: UDim2,

	SelectedIndex: number,
	SetSelectedIndex: (number) -> (),
	SelectedCount: number,

	ImageControls: useImageControls.ImageControls,

	OnImport: () -> (),

	Disabled: boolean,
}

local function getImageButtonColor(theme: StudioTheme, modifier: Enum.StudioStyleGuideModifier)
	if modifier == Enum.StudioStyleGuideModifier.Selected then
		return theme:GetColor(Enum.StudioStyleGuideColor.ButtonText, Enum.StudioStyleGuideModifier.Pressed)
	elseif modifier == Enum.StudioStyleGuideModifier.Hover then
		return theme:GetColor(Enum.StudioStyleGuideColor.ButtonText, Enum.StudioStyleGuideModifier.Hover)
	end
	return theme:GetColor(Enum.StudioStyleGuideColor.ButtonText, Enum.StudioStyleGuideModifier.Disabled)
end

local function ActionBar(props: Props)
	local theme = StudioComponents.useTheme()

	local function incrementIndex(step: number)
		local newIndex = ((props.SelectedIndex + step - 1) % props.SelectedCount) + 1
		props.SetSelectedIndex(newIndex)
	end

	local controls = props.ImageControls
	local zoom = controls.zoom
	local maxZoom = controls.maxZoom
	local zoomEnabled = controls.hasImage and not props.Disabled
	local zoomedOut = zoom > 1
	local zoomedIn = zoom < maxZoom
	local zoomPercentText = `{math.floor(zoom * 100 + 0.5)}%`

	return React.createElement("Frame", {
		AnchorPoint = props.AnchorPoint,
		Position = props.Position,
		Size = props.Size,
		BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Titlebar),
		BorderColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Border),
	}, {
		Padding = React.createElement("UIPadding", {
			PaddingLeft = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 4),
			PaddingTop = UDim.new(0, 4),
			PaddingBottom = UDim.new(0, 4),
		}),

		ImageIndexer = React.createElement("Frame", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.fromScale(0, 0.5),
			Size = UDim2.fromOffset(16 * 6, 16),
		}, {
			LeftButton = React.createElement(LucideButton, {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 0, 0.5, 0),
				Size = UDim2.fromOffset(LEFT_ICON.ImageRectSize.X, LEFT_ICON.ImageRectSize.Y),
				Disabled = props.Disabled or props.SelectedCount == 0,
				Icon = LEFT_ICON,

				GetColor = function(modifier)
					return getImageButtonColor(theme, modifier)
				end,

				OnActivated = function()
					incrementIndex(-1)
				end,
			}),

			CountLabel = React.createElement("TextLabel", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.new(1, -40, 1, 0),

				Text = `{math.min(props.SelectedIndex, props.SelectedCount)} / {props.SelectedCount}`,
				TextColor3 = theme:GetColor(
					Enum.StudioStyleGuideColor.ButtonText,
					Enum.StudioStyleGuideModifier.Disabled
				),
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
				TextTruncate = Enum.TextTruncate.AtEnd,
			}),

			RightButton = React.createElement(LucideButton, {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, 0, 0.5, 0),
				Size = UDim2.fromOffset(RIGHT_ICON.ImageRectSize.X, RIGHT_ICON.ImageRectSize.Y),
				Disabled = props.Disabled or props.SelectedCount == 0,
				Icon = RIGHT_ICON,

				GetColor = function(modifier)
					return getImageButtonColor(theme, modifier)
				end,

				OnActivated = function()
					incrementIndex(1)
				end,
			}),
		}),

		Buttons = React.createElement("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
		}, {
			Layout = React.createElement("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				FillDirection = Enum.FillDirection.Horizontal,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				HorizontalAlignment = Enum.HorizontalAlignment.Right,
				Padding = UDim.new(0, 4),
			}),

			Controls = CONTROLS_ENABLED and React.createElement(React.Fragment, nil, {
				ZoomOut = React.createElement(LucideButton, {
					LayoutOrder = 1,
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.new(0, 0, 0.5, 0),
					Size = UDim2.fromOffset(ZOOM_OUT_ICON.ImageRectSize.X, ZOOM_OUT_ICON.ImageRectSize.Y),
					Disabled = props.Disabled,
					Icon = ZOOM_OUT_ICON,

					GetColor = function(modifier)
						return getImageButtonColor(theme, modifier)
					end,

					OnActivated = function()
						if zoomEnabled and zoomedOut then
							controls.zoomBy(1 / BUTTON_ZOOM_STEP, Vector2.new(0.5, 0.5))
						end
					end,
				}),

				ZoomLabel = React.createElement("TextLabel", {
					LayoutOrder = 2,
					BackgroundTransparency = 1,
					Size = UDim2.fromOffset(36, 16),

					Text = zoomPercentText,
					TextColor3 = getImageButtonColor(
						theme,
						if zoomEnabled
							then Enum.StudioStyleGuideModifier.Default
							else Enum.StudioStyleGuideModifier.Disabled
					),
					TextXAlignment = Enum.TextXAlignment.Center,
					TextYAlignment = Enum.TextYAlignment.Center,
				}),

				ZoomIn = React.createElement(LucideButton, {
					LayoutOrder = 3,
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.new(0, 0, 0.5, 0),
					Size = UDim2.fromOffset(ZOOM_IN_ICON.ImageRectSize.X, ZOOM_IN_ICON.ImageRectSize.Y),
					Disabled = props.Disabled,
					Icon = ZOOM_IN_ICON,

					GetColor = function(modifier)
						return getImageButtonColor(theme, modifier)
					end,

					OnActivated = function()
						if zoomEnabled and zoomedIn then
							controls.zoomBy(BUTTON_ZOOM_STEP, Vector2.new(0.5, 0.5))
						end
					end,
				}),

				Reset = React.createElement(LucideButton, {
					LayoutOrder = 4,
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.new(0, 0, 0.5, 0),
					Size = UDim2.fromOffset(RESET_ZOOM_ICON.ImageRectSize.X, RESET_ZOOM_ICON.ImageRectSize.Y),
					Disabled = props.Disabled,
					Icon = RESET_ZOOM_ICON,

					GetColor = function(modifier)
						return getImageButtonColor(theme, modifier)
					end,

					OnActivated = function()
						controls.reset()
					end,
				}),
			}),

			Import = false and React.createElement(StudioComponents.MainButton, {
				LayoutOrder = -1,
				Size = UDim2.new(0, 70, 1, 0),
				TextXAlignment = Enum.TextXAlignment.Center,
				Text = "Import",
				Disabled = props.Disabled,
				OnActivated = function()
					props.OnImport()
				end,

				Icon = {
					Image = IMPORT_ICON.Url,
					RectSize = IMPORT_ICON.ImageRectSize,
					RectOffset = IMPORT_ICON.ImageRectOffset,
					Size = Vector2.new(IMPORT_ICON.ImageRectSize.X, IMPORT_ICON.ImageRectSize.Y),
					UseThemeColor = true,
				},
			}),
		}),
	})
end

return ActionBar
