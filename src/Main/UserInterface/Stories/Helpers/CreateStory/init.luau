--!strict

--[[
From srcfenner's StudioComponents:
https://github.com/sircfenner/StudioComponents

The MIT License (MIT)

Copyright (c) 2024 sircfenner

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
--]]

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local StudioComponents = require(pluginRoot.Packages.StudioComponents)
local React = require(pluginRoot.Packages.React)

local GetStoryPlugin = require(script.GetStoryPlugin)

local themes = settings().Studio:GetAvailableThemes()
themes[1], themes[2] = themes[2], themes[1]

local function StoryTheme(props: {
	Theme: StudioTheme,
	Size: UDim2,
	LayoutOrder: number,
} & {
	children: React.ReactNode,
})
	return React.createElement("Frame", {
		Size = props.Size,
		LayoutOrder = props.LayoutOrder,
		BackgroundColor3 = props.Theme:GetColor(Enum.StudioStyleGuideColor.MainBackground),
		BorderSizePixel = 0,
	}, {
		Provider = React.createElement(StudioComponents.ThemeContext.Provider, {
			value = props.Theme,
		}, {
			Inner = React.createElement(StudioComponents.ScrollFrame, {
				Layout = {
					ClassName = "UIListLayout",
					SortOrder = Enum.SortOrder.LayoutOrder,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					Padding = UDim.new(0, 10),
				},
				PaddingLeft = UDim.new(0, 10),
				PaddingRight = UDim.new(0, 10),
				PaddingTop = UDim.new(0, 10),
				PaddingBottom = UDim.new(0, 10),
			}, props.children),
		}),
	})
end

local function readFlipbookTheme(screenFrame: Frame)
	local color = screenFrame:GetStyled("BackgroundColor3") :: Color3
	if color == Color3.new(1, 1, 1) then
		return settings().Studio:GetAvailableThemes()[1]
	else
		return settings().Studio:GetAvailableThemes()[2]
	end
end

local function createSplitThemeStory(component: React.FC<any>)
	return function(props: any)
		local order = 0
		local function getOrder()
			order += 1
			return order
		end

		local items: { React.ReactNode } = {}
		for i, theme in themes do
			local widthOffset = if #themes > 2 and i == #themes then -1 else 0
			if i == 1 and #themes > 1 then
				widthOffset -= 1
			end
			table.insert(
				items,
				React.createElement(StoryTheme, {
					Theme = theme,
					Size = UDim2.new(1 / #themes, widthOffset, 1, 0),
					LayoutOrder = getOrder(),
				}, React.createElement(component, props))
			)
			-- invisible divider to prevent scrollframe edges overlapping as
			-- they have default borders (outside, not inset)
			if i < #themes then
				table.insert(
					items,
					React.createElement("Frame", {
						Size = UDim2.new(0, 2, 1, 0),
						BackgroundTransparency = 1,
						LayoutOrder = getOrder(),
					})
				)
			end
		end

		return React.createElement(StudioComponents.PluginProvider, {
			Plugin = GetStoryPlugin(),
		}, {
			Container = React.createElement("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, -1, 1, 0),
			}, {
				Layout = React.createElement("UIListLayout", {
					SortOrder = Enum.SortOrder.LayoutOrder,
					FillDirection = Enum.FillDirection.Horizontal,
				}),
			}, items),
		})
	end
end

local function createFlipbookStory(component: React.FC<any>)
	return function(props: any)
		local scroll = props.container :: ScrollingFrame
		local screenFrame = scroll:FindFirstAncestor("Screen") :: Frame
		local theme, setTheme = React.useState(readFlipbookTheme(screenFrame))

		React.useEffect(function()
			local prevEnabled = scroll.ScrollingEnabled
			local prevThickness = scroll.ScrollBarThickness

			scroll.ScrollingEnabled = false
			scroll.ScrollBarThickness = 0

			setTheme(readFlipbookTheme(screenFrame))
			local connection = screenFrame:GetStyledPropertyChangedSignal("BackgroundColor3"):Connect(function()
				setTheme(readFlipbookTheme(screenFrame))
			end)

			return function()
				scroll.ScrollingEnabled = prevEnabled
				scroll.ScrollBarThickness = prevThickness
				connection:Disconnect()
			end
		end, {})

		return React.createElement(StudioComponents.PluginProvider, {
			Plugin = GetStoryPlugin(),
		}, {
			Provider = React.createElement(StudioComponents.ThemeContext.Provider, {
				value = theme,
			}, {
				Container = React.createElement("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(1, 1),
				}, {
					Component = React.createElement(component, props),
				}),
			}),
		})
	end
end

return {
	split = createSplitThemeStory,
	flipbook = createFlipbookStory,
}
