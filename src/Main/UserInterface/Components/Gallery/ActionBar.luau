--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local StudioComponents = require(pluginRoot.Packages.StudioComponents)
local Lucide = require(pluginRoot.Packages.Lucide)
local React = require(pluginRoot.Packages.React)

local uiRoot = script:FindFirstAncestor("UserInterface")
local LucideButton = require(uiRoot.Components.Shared.LucideButton)

local UPLOAD_ICON = assert(Lucide.GetAsset("upload", 16))
local RIGHT_ICON = assert(Lucide.GetAsset("chevron-right", 16))
local LEFT_ICON = assert(Lucide.GetAsset("chevron-left", 16))

export type Props = {
	AnchorPoint: Vector2,
	Position: UDim2,
	Size: UDim2,

	SelectedIndex: number,
	SetSelectedIndex: (number) -> (),
	SelectedCount: number,

	OnUpload: () -> (),

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
	local hasCreateAssetPermission = true --Hooks.useHasCreateAssetPermission()
	local uploadDisabled = not (not props.Disabled and props.SelectedCount > 0)

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
			Size = UDim2.fromOffset(16 * 4, 16),
		}, {
			LeftButton = React.createElement(LucideButton, {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 0, 0.5, 0),
				Size = UDim2.fromOffset(LEFT_ICON.ImageRectSize.X, LEFT_ICON.ImageRectSize.Y),
				Disabled = props.Disabled,
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

				Text = `{props.SelectedIndex} / {props.SelectedCount}`,
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
				Disabled = props.Disabled,
				Icon = RIGHT_ICON,

				GetColor = function(modifier)
					return getImageButtonColor(theme, modifier)
				end,

				OnActivated = function()
					incrementIndex(1)
				end,
			}),
		}),

		Upload = hasCreateAssetPermission and React.createElement(StudioComponents.MainButton, {
			LayoutOrder = -1,
			Size = UDim2.new(0, 70, 1, 0),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.fromScale(1, 0.5),
			TextXAlignment = Enum.TextXAlignment.Center,
			Text = "Upload",
			Disabled = uploadDisabled,
			OnActivated = function()
				props.OnUpload()
			end,

			Icon = {
				Image = UPLOAD_ICON.Url,
				RectSize = UPLOAD_ICON.ImageRectSize,
				RectOffset = UPLOAD_ICON.ImageRectOffset,
				Transparency = if uploadDisabled and theme.Name == "Dark" then 0.7 else nil,
				Size = Vector2.new(UPLOAD_ICON.ImageRectSize.X, UPLOAD_ICON.ImageRectSize.Y),
			},
		}),
	})
end

return ActionBar
