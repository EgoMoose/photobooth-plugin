--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local StudioComponents = require(pluginRoot.Packages.StudioComponents)
local Lucide = require(pluginRoot.Packages.Lucide)
local React = require(pluginRoot.Packages.React)

local uiRoot = script:FindFirstAncestor("UserInterface")
local LucideButton = require(uiRoot.Components.Shared.LucideButton)
local Hooks = require(uiRoot.Hooks)

local ToggleScrollList = require(script.ToggleScrollList)
local ImageViewer = require(script.ImageViewer)

local SPLIT_UDIM = UDim.new(0.25, 0)

local MAXIMIZE_ICON = assert(Lucide.GetAsset("chevrons-right", 16))
local MINIMIZE_ICON = assert(Lucide.GetAsset("chevrons-left", 16))

export type Props = {
	AnchorPoint: Vector2,
	Position: UDim2,
	Size: UDim2,

	EditableImageInfos: { Hooks.EditableImageInfo },

	IsExpanded: boolean,
	SetIsExpanded: (boolean) -> (),

	SelectedIndex: number,
	SetSelectedIndex: (number) -> (),

	UploadExclusions: { [EditableImage]: boolean },
	SetUploadExclusions: ({ [EditableImage]: boolean }) -> (),

	BackgroundType: string,
	SetBackgroundType: (string) -> (),

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

local function ImageInterface(props: Props)
	local theme = StudioComponents.useTheme()

	local minMaxIcon = if props.IsExpanded then MINIMIZE_ICON else MAXIMIZE_ICON
	local splitUDim = if props.IsExpanded then SPLIT_UDIM else UDim.new(0, 0)

	local selectedInfo = props.EditableImageInfos[props.SelectedIndex]
	local prevSelectedEditImageRef = React.useRef(if selectedInfo then selectedInfo.EditableImage else nil)

	React.useEffect(function()
		local index = 1
		local exclusions = {}
		local prevSelectedEditImage = prevSelectedEditImageRef.current
		for i = #props.EditableImageInfos, 1, -1 do
			local info = props.EditableImageInfos[i]
			if prevSelectedEditImage and info.EditableImage == prevSelectedEditImage then
				index = i
			end

			if props.UploadExclusions[info.EditableImage] then
				exclusions[info.EditableImage] = true
			end
		end

		local info = props.EditableImageInfos[index]
		prevSelectedEditImageRef.current = if info then info.EditableImage else nil

		props.SetSelectedIndex(index)
		props.SetUploadExclusions(exclusions)
	end, { props.EditableImageInfos })

	return React.createElement("Frame", {
		AnchorPoint = props.AnchorPoint,
		Position = props.Position,
		Size = props.Size,
		BackgroundTransparency = 1,
	}, {
		Left = React.createElement("Frame", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0, 0),
			Position = UDim2.fromOffset(0, 0),
			Size = UDim2.new(splitUDim.Scale, splitUDim.Offset, 1, 0),
		}, {
			MinMaxButton = React.createElement(LucideButton, {
				AnchorPoint = Vector2.new(0, 0),
				Position = UDim2.new(1, 4, 0, 4),
				Size = UDim2.fromOffset(minMaxIcon.ImageRectSize.X, minMaxIcon.ImageRectSize.Y),

				Icon = minMaxIcon,
				GetColor = function(modifier)
					return getImageButtonColor(theme, modifier)
				end,

				OnActivated = function()
					props.SetIsExpanded(not props.IsExpanded)
				end,

				Disabled = props.Disabled,
			}),

			ImageList = React.createElement(ToggleScrollList, {
				AnchorPoint = Vector2.new(0, 0),
				Position = UDim2.fromOffset(0, 0),
				Size = UDim2.new(1, 0, 1, 0),

				SelectedIndex = props.SelectedIndex,
				SetSelectedIndex = function(i)
					local info = props.EditableImageInfos[i]
					prevSelectedEditImageRef.current = if info then info.EditableImage else nil
					props.SetSelectedIndex(i)
				end,

				UploadExclusions = props.UploadExclusions,
				SetUploadExclusions = props.SetUploadExclusions,

				TitleHeight = 24,
				ElementHeight = 24,

				EditableImageInfos = props.EditableImageInfos,

				Disabled = props.Disabled,
			}),
		}),

		Right = React.createElement("Frame", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.fromScale(1, 0),
			Size = UDim2.new(1 - splitUDim.Scale, -splitUDim.Offset, 1, 0),
			BackgroundTransparency = 0,
			BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainBackground),
			BorderColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Border),
			ZIndex = -1,
		}, {
			ImageViewer = React.createElement(ImageViewer, {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.new(1, 0, 1, 0),

				EditableImageInfo = props.EditableImageInfos[props.SelectedIndex],

				BackgroundType = props.BackgroundType,
				SetBackgroundType = props.SetBackgroundType,

				Padding = {
					PaddingLeft = UDim.new(0, 22),
					PaddingRight = UDim.new(0, 22),
					PaddingTop = UDim.new(0, 22),
					PaddingBottom = UDim.new(0, 22),
				},
			}),
		}),
	})
end

return ImageInterface
