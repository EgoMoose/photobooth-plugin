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

local IsStoryContext = require(script.IsStoryContext)
local GetStoryPlugin = require(script.GetStoryPlugin)

local themes = settings().Studio:GetAvailableThemes()
themes[1], themes[2] = themes[2], themes[1]

local THEME_NAME_MAP = {
	["Dark"] = "dark",
	["Light"] = "light",
}

local function useMyStudioTheme()
	local value, setValue = React.useState(settings().Studio.Theme)

	React.useEffect(function()
		setValue(settings().Studio.Theme)
		local connection = settings().Studio.ThemeChanged:Connect(function()
			setValue(settings().Studio.Theme)
		end)

		return function()
			connection:Disconnect()
		end
	end, {})

	return value
end

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

local function createSplitThemeStory(component: React.FC<any>)
	return function(props: any)
		local order = 0
		local function getOrder()
			order += 1
			return order
		end

		local items: { [string]: React.ReactNode } = {}
		for i, theme in themes do
			local widthOffset = if #themes > 2 and i == #themes then -1 else 0
			if i == 1 and #themes > 1 then
				widthOffset -= 1
			end

			items[theme.Name] = React.createElement(StoryTheme, {
				Theme = theme,
				Size = UDim2.new(1 / #themes, widthOffset, 1, 0),
				LayoutOrder = getOrder(),
			}, {
				Component = React.createElement(component, props),
			})

			-- invisible divider to prevent scrollframe edges overlapping as
			-- they have default borders (outside, not inset)
			if i < #themes then
				items["Divider" .. i] = React.createElement("Frame", {
					Size = UDim2.new(0, 2, 1, 0),
					BackgroundTransparency = 1,
					LayoutOrder = getOrder(),
				})
			end
		end

		return React.createElement(IsStoryContext.Provider, {
			value = true,
		}, {
			PluginProvider = React.createElement(StudioComponents.PluginProvider, {
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
			}),
		})
	end
end

local function createThemeStory(component: React.FC<any>, theme: ("dark" | "light")?)
	return function(props: any)
		local myTheme = useMyStudioTheme()
		local themeName = "dark"

		if props.controls.darkMode ~= nil then
			themeName = if props.controls.darkMode then "dark" else "light"
		else
			themeName = theme or THEME_NAME_MAP[props.theme] or myTheme.Name:lower()
		end

		return React.createElement(IsStoryContext.Provider, {
			value = true,
		}, {
			PluginProvider = React.createElement(StudioComponents.PluginProvider, {
				Plugin = GetStoryPlugin(),
			}, {
				ThemeProvider = React.createElement(StudioComponents.ThemeContext.Provider, {
					value = if themeName == "dark" then themes[1] else themes[2],
				}, {
					Container = React.createElement("Frame", {
						BackgroundTransparency = 1,
						Size = UDim2.fromScale(1, 1),
					}, {
						Component = React.createElement(component, props),
					}),
				}),
			}),
		})
	end
end

return {
	split = createSplitThemeStory,
	theme = createThemeStory,
}
