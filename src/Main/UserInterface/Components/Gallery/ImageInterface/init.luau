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

	UploadExclusions: { [Instance]: boolean },
	SetUploadExclusions: ({ [Instance]: boolean }) -> (),

	BackgroundType: string,
	SetBackgroundType: (string) -> (),

	OnUpload: () -> (),

	SinkInput: boolean,
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

	local leftRef = React.useRef(nil :: GuiObject?)
	local leftAbsSize = Hooks.useRefProperty(leftRef, "AbsoluteSize", Vector2.zero)

	local minMaxIcon = if props.IsExpanded then MINIMIZE_ICON else MAXIMIZE_ICON
	local splitUDim = if props.IsExpanded then SPLIT_UDIM else UDim.new(0, 0)

	local selectedInfo = props.EditableImageInfos[props.SelectedIndex]
	local prevSelectedInstanceRef = React.useRef(if selectedInfo then selectedInfo.Instance else nil)

	React.useEffect(function()
		local info = props.EditableImageInfos[props.SelectedIndex]
		prevSelectedInstanceRef.current = if info then info.Instance else nil
	end, { props.SelectedIndex })

	React.useEffect(function()
		local index = 1
		local exclusions = {}
		local prevSelectedInstance = prevSelectedInstanceRef.current
		for i = #props.EditableImageInfos, 1, -1 do
			local info = props.EditableImageInfos[i]
			if prevSelectedInstance and info.Instance == prevSelectedInstance then
				index = i
			end

			if props.UploadExclusions[info.Instance] then
				exclusions[info.Instance] = true
			end
		end

		local info = props.EditableImageInfos[index]
		prevSelectedInstanceRef.current = if info then info.Instance else nil

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
			BackgroundTransparency = 0,
			AnchorPoint = Vector2.new(0, 0),
			Position = UDim2.fromOffset(0, 0),
			Size = UDim2.new(splitUDim.Scale, splitUDim.Offset, 1, 0),
			BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainBackground),
			BorderColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Border),
			ref = leftRef,
		}, {
			-- UIStroke = React.createElement("UIStroke", {
			-- 	Thickness = 1,
			-- 	Transparency = 0,
			-- 	Color = theme:GetColor(Enum.StudioStyleGuideColor.Border),
			-- }),
			SizeConstraint = React.createElement("UISizeConstraint", {
				MinSize = Vector2.new(150, 0),
				MaxSize = Vector2.new(200, math.huge),
			}),

			MinMaxButton = React.createElement(LucideButton, {
				AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.new(1, 0, 1, 0),
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
					prevSelectedInstanceRef.current = if info then info.Instance else nil
					props.SetSelectedIndex(i)
				end,

				UploadExclusions = props.UploadExclusions,
				SetUploadExclusions = props.SetUploadExclusions,

				TitleHeight = 28,
				ElementHeight = 24,

				EditableImageInfos = props.EditableImageInfos,

				OnUpload = props.OnUpload,

				SinkInput = props.SinkInput,
				Disabled = props.Disabled,
			}),
		}),

		Right = React.createElement("Frame", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.fromScale(1, 0),
			Size = UDim2.new(1, -leftAbsSize.X, 1, 0),
			ZIndex = -1,
		}, {
			ImageViewer = React.createElement(ImageViewer, {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.new(1, 0, 1, 0),

				EditableImageInfo = props.EditableImageInfos[props.SelectedIndex],

				BackgroundType = props.BackgroundType,
				SetBackgroundType = props.SetBackgroundType,
			}),
		}),
	})
end

return ImageInterface
