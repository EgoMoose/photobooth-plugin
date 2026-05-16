local pluginRoot = script:FindFirstAncestor("PluginRoot")
local React = require(pluginRoot.Packages.React)

local userInterfaceRoot = script:FindFirstAncestor("UserInterface")
local IsStoryContext = require(userInterfaceRoot.Stories.Helpers.CreateStory.IsStoryContext)

local function useIsStory()
	return React.useContext(IsStoryContext)
end

return useIsStory
