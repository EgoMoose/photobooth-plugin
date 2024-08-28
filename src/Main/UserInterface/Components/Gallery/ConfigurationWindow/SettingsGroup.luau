--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local StudioComponents = require(pluginRoot.Packages.StudioComponents)
local Lucide = require(pluginRoot.Packages.Lucide)
local React = require(pluginRoot.Packages.React)

local CAN_TOGGLE_EXPANDS = false

type NodeInfo = {
	Name: string,
	Node: React.Node,
}

export type Props = {
	Title: string,
	List: { NodeInfo },
	HorizontalSplit: number,

	LayoutOrder: number,
	Disabled: boolean,
}

local function ExpandedElements(props: Props)
	local theme = StudioComponents.useTheme()

	local elements: { [string]: React.Node } = {}
	for i, entry in props.List do
		elements[entry.Name] = React.createElement("Frame", {
			LayoutOrder = i,
			Size = UDim2.fromScale(1, 1 / #props.List),
			BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainBackground),
			BorderColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Border),
		}, {
			LeftSection = React.createElement("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(props.HorizontalSplit, -1, 1, 0),
			}, {
				Padding = React.createElement("UIPadding", {
					PaddingLeft = UDim.new(0, 20),
					PaddingRight = UDim.new(0, 4),
					PaddingTop = UDim.new(0, 4),
					PaddingBottom = UDim.new(0, 4),
				}),
				Label = React.createElement(StudioComponents.Label, {
					Position = UDim2.fromOffset(0, 0),
					Size = UDim2.new(1, 0, 1, 0),
					Text = entry.Name,
					TextTruncate = Enum.TextTruncate.SplitWord,
					TextXAlignment = Enum.TextXAlignment.Left,
				}),
			}),
			Line = React.createElement("Frame", {
				BorderSizePixel = 0,
				Size = UDim2.new(0, 1, 1, 0),
				Position = UDim2.fromScale(props.HorizontalSplit, 0),
				BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Border),
			}),
			RightSection = React.createElement("Frame", {
				BackgroundTransparency = 1,
				Position = UDim2.new(props.HorizontalSplit, 0, 0, 0),
				Size = UDim2.new(1 - props.HorizontalSplit, 0, 1, 0),
			}, {
				Content = entry.Node,
			}),
		})
	end

	return React.createElement(React.Fragment, {}, {
		Layout = React.createElement("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			FillDirection = Enum.FillDirection.Vertical,
			VerticalAlignment = Enum.VerticalAlignment.Top,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0, 0),
		}),
		Elements = React.createElement(React.Fragment, {}, elements),
	})
end

local function SettingsGroup(props: Props)
	local theme = StudioComponents.useTheme()
	local expanded, setExpanded = React.useState(true)

	local arrowIcon = if expanded
		then assert(Lucide.GetAsset("chevron-down", 16))
		else assert(Lucide.GetAsset("chevron-right", 16))

	return React.createElement("Frame", {
		Size = UDim2.new(1, 0, 0, 26 + 24 * (if expanded then #props.List else 0)),
		BackgroundTransparency = 0.1,
		LayoutOrder = props.LayoutOrder,
	}, {
		TitleBar = React.createElement("Frame", {
			Size = UDim2.new(1, 0, 0, 26),
			BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Titlebar),
			BorderColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Border),
			[React.Event.InputBegan] = function(_, input: InputObject)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					if CAN_TOGGLE_EXPANDS and not props.Disabled then
						setExpanded(not expanded)
					end
				end
			end,
		}, {
			Arrow = React.createElement("ImageLabel", {
				Image = arrowIcon.Url,
				ImageRectSize = arrowIcon.ImageRectSize,
				ImageRectOffset = arrowIcon.ImageRectOffset,

				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0, 9, 0.5, 0),
				Size = UDim2.fromOffset(arrowIcon.ImageRectSize.X, arrowIcon.ImageRectSize.Y),
				BackgroundTransparency = 1,
				ImageColor3 = theme:GetColor(Enum.StudioStyleGuideColor.TitlebarText),
			}),
			Label = React.createElement(StudioComponents.Label, {
				Position = UDim2.fromOffset(20, 0),
				Size = UDim2.new(1, 0, 1, 0),
				Text = `<b>{props.Title}</b>`,
				RichText = true,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
		}),
		List = expanded and React.createElement("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(0, 26),
			Size = UDim2.new(1, 0, 1, -26),
		}, {
			Content = React.createElement(ExpandedElements, props),
		}),
	})
end

return SettingsGroup
