--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local StudioComponents = require(pluginRoot.Packages.StudioComponents)
local Lucide = require(pluginRoot.Packages.Lucide)
local React = require(pluginRoot.Packages.React)

local uiRoot = script:FindFirstAncestor("UserInterface")
local LucideButton = require(uiRoot.Components.Shared.LucideButton)

local FIT_ICON = assert(Lucide.GetAsset("scan-eye", 16))
local ZOOM_IN_ICON = assert(Lucide.GetAsset("zoom-in", 16))
local ZOOM_OUT_ICON = assert(Lucide.GetAsset("zoom-out", 16))

local RIGHT_ICON = assert(Lucide.GetAsset("chevron-right", 16))
local LEFT_ICON = assert(Lucide.GetAsset("chevron-left", 16))

export type Props = {
	AnchorPoint: Vector2,
	Position: UDim2,
	Size: UDim2,

	SelectedIndex: number,
	SetSelectedIndex: (number) -> (),
	SelectedCount: number,

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

		ImageViewerControls = React.createElement("Frame", {
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

			Zoom = React.createElement("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(0.25, 1),
			}, {
				ZoomIn = React.createElement(LucideButton, {
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.fromScale(1, 0.5),
					Size = UDim2.fromOffset(ZOOM_IN_ICON.ImageRectSize.X, ZOOM_IN_ICON.ImageRectSize.Y),
					Disabled = props.Disabled or props.SelectedCount == 0,
					Icon = ZOOM_IN_ICON,

					GetColor = function(modifier)
						return getImageButtonColor(theme, modifier)
					end,

					OnActivated = function()
						print("Zoom In!")
					end,
				}),

				ZoomOut = React.createElement(LucideButton, {
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.fromScale(0, 0.5),
					Size = UDim2.fromOffset(ZOOM_OUT_ICON.ImageRectSize.X, ZOOM_OUT_ICON.ImageRectSize.Y),
					Disabled = props.Disabled or props.SelectedCount == 0,
					Icon = ZOOM_OUT_ICON,

					GetColor = function(modifier)
						return getImageButtonColor(theme, modifier)
					end,

					OnActivated = function()
						print("Zoom Out!")
					end,
				}),
			}),

			LeftButton = false and React.createElement(LucideButton, {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 0, 0.5, 0),
				Size = UDim2.fromOffset(FIT_ICON.ImageRectSize.X, FIT_ICON.ImageRectSize.Y),
				Disabled = props.Disabled or props.SelectedCount == 0,
				Icon = FIT_ICON,

				GetColor = function(modifier)
					return getImageButtonColor(theme, modifier)
				end,

				OnActivated = function()
					print("Fit!")
				end,
			}),
		}),
	})
end

return ActionBar
