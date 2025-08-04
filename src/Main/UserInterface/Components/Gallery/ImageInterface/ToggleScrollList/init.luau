local pluginRoot = script:FindFirstAncestor("PluginRoot")
local StudioComponents = require(pluginRoot.Packages.StudioComponents)
local Lucide = require(pluginRoot.Packages.Lucide)
local React = require(pluginRoot.Packages.React)

local uiRoot = script:FindFirstAncestor("UserInterface")
local Hooks = require(uiRoot.Hooks)

local VerticalScroll = require(script.VerticalScroll)

local UPLOAD_ICON = assert(Lucide.GetAsset("upload", 16))

export type Props = {
	AnchorPoint: Vector2,
	Position: UDim2,
	Size: UDim2,

	SelectedIndex: number,
	SetSelectedIndex: (number) -> (),

	UploadExclusions: { [Instance]: boolean },
	SetUploadExclusions: ({ [Instance]: boolean }) -> (),

	TitleHeight: number,
	ElementHeight: number,

	OnUpload: () -> (),

	EditableImageInfos: { Hooks.EditableImageInfo },

	SinkInput: boolean,
	Disabled: boolean,
}

local function ToggleScrollList(props: Props)
	local theme = StudioComponents.useTheme()
	local hasCreateAssetPermission = true --Hooks.useHasCreateAssetPermission()

	local nSelected = #props.EditableImageInfos
	local uploadHeight = if hasCreateAssetPermission then 36 else 0

	local lines: { [string]: React.Node } = {}
	for i, info in props.EditableImageInfos do
		lines[`Line{i}`] = React.createElement("TextButton", {
			Size = UDim2.new(1, 0, 0, props.ElementHeight),
			AutoButtonColor = false,
			Text = "",

			BackgroundColor3 = if i == props.SelectedIndex
				then theme:GetColor(Enum.StudioStyleGuideColor.DialogMainButton)
				else theme:GetColor(Enum.StudioStyleGuideColor.MainBackground),
			BorderColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Border),

			LayoutOrder = i,

			[React.Event.Activated] = function()
				props.SetSelectedIndex(i)
			end,
		}, {
			Padding = React.createElement("UIPadding", {
				PaddingLeft = UDim.new(0, 4),
				PaddingRight = UDim.new(0, 4),
				PaddingTop = UDim.new(0, 0),
				PaddingBottom = UDim.new(0, 0),
			}),
			Checkbox = React.createElement(StudioComponents.Checkbox, {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.fromScale(0, 0.5),
				Size = UDim2.new(0, StudioComponents.Constants.DefaultToggleHeight, 1, 0),

				Value = not props.UploadExclusions[info.Instance],
				OnChanged = function()
					props.UploadExclusions[info.Instance] = not props.UploadExclusions[info.Instance]
					props.SetUploadExclusions(table.clone(props.UploadExclusions))
				end,

				Disabled = props.Disabled,
			}),
			Label = React.createElement(StudioComponents.Label, {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, StudioComponents.Constants.DefaultToggleHeight + 2, 0.5, 0),
				Size = UDim2.new(1, -StudioComponents.Constants.DefaultToggleHeight, 1, 0),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Center,
				TextTruncate = Enum.TextTruncate.AtEnd,
				TextColorStyle = if i == props.SelectedIndex
					then Enum.StudioStyleGuideColor.DialogMainButtonText
					else Enum.StudioStyleGuideColor.MainText,
				Text = info.Name,
			}),
		})
	end

	local exclusionCount = React.useMemo(function()
		local count = 0
		for _, info in props.EditableImageInfos do
			if props.UploadExclusions[info.Instance] then
				count = count + 1
			end
		end
		return count
	end, { props.UploadExclusions })

	local inclusionCount = nSelected - exclusionCount

	return React.createElement("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = props.AnchorPoint,
		Position = props.Position,
		Size = props.Size,
	}, {
		Title = React.createElement("Frame", {
			AnchorPoint = Vector2.new(0, 0),
			Position = UDim2.fromScale(0, 0),
			Size = UDim2.new(1, 0, 0, props.TitleHeight),

			BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Light),
			BorderColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Border),

			ZIndex = 2,
		}, {
			Clipped = React.createElement("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				ClipsDescendants = true,
			}, {
				Padding = React.createElement("UIPadding", {
					PaddingLeft = UDim.new(0, 4),
					PaddingRight = UDim.new(0, 8),
					PaddingTop = UDim.new(0, 0),
					PaddingBottom = UDim.new(0, 0),
				}),
				Checkbox = React.createElement(StudioComponents.Checkbox, {
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.fromScale(0, 0.5),
					Size = UDim2.fromScale(1, 1),

					Value = inclusionCount > 0,
					OnChanged = function()
						if inclusionCount > 0 then
							local exclusions = {}
							for _, info in props.EditableImageInfos do
								exclusions[info.Instance] = true
							end
							props.SetUploadExclusions(exclusions)
						else
							props.SetUploadExclusions({})
						end
					end,

					Disabled = props.Disabled or (#props.EditableImageInfos == 0),
				}),
				Label = React.createElement(StudioComponents.Label, {
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.new(0, StudioComponents.Constants.DefaultToggleHeight + 2, 0.5, 0),
					Size = UDim2.new(1, -StudioComponents.Constants.DefaultToggleHeight, 1, 0),
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Center,
					TextTruncate = Enum.TextTruncate.AtEnd,
					TextColorStyle = Enum.StudioStyleGuideColor.MainText,
					Text = `{inclusionCount} selected`,
				}),
			}),
		}),

		Scroll = React.createElement(VerticalScroll, {
			AnchorPoint = Vector2.zero,
			Position = UDim2.fromOffset(0, props.TitleHeight),
			Size = UDim2.new(1, 0, 1, -props.TitleHeight - uploadHeight),

			GradientColor = theme:GetColor(Enum.StudioStyleGuideColor.MainBackground),
			GradientHeight = 8,

			Disabled = props.Disabled or props.SinkInput,
		}, {
			Layout = React.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 0),
			}),
		}, lines),

		Upload = React.createElement("Frame", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.fromScale(0, 1),
			Size = UDim2.new(1, 0, 0, uploadHeight),
			Visible = uploadHeight > 0,
			ClipsDescendants = true,
		}, {
			Padding = React.createElement("UIPadding", {
				PaddingLeft = UDim.new(0, 4),
				PaddingRight = UDim.new(0, 4),
				PaddingTop = UDim.new(0, 4),
				PaddingBottom = UDim.new(0, 4),
			}),
			Button = React.createElement(StudioComponents.Button, {
				LayoutOrder = -2,
				Size = UDim2.new(1, 0, 0, 28),
				TextXAlignment = Enum.TextXAlignment.Center,
				Text = "Upload",
				Disabled = props.Disabled or inclusionCount == 0,
				OnActivated = props.OnUpload,

				Icon = {
					Image = UPLOAD_ICON.Url,
					RectSize = UPLOAD_ICON.ImageRectSize,
					RectOffset = UPLOAD_ICON.ImageRectOffset,
					Size = Vector2.new(UPLOAD_ICON.ImageRectSize.X, UPLOAD_ICON.ImageRectSize.Y),
					UseThemeColor = true,
				},
			}),
		}),
	})
end

return ToggleScrollList
