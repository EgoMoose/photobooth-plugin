--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local ReactRoblox = require(pluginRoot.Packages.ReactRoblox)
local React = require(pluginRoot.Packages.React)

local SharedStoryAssets = require(script.Parent.SharedStoryAssets)
task.spawn(SharedStoryAssets.getMeshPart)

return {
	name = "Photobooth",
	storyRoots = { script.Parent.Parent },
	react = React,
	reactRoblox = ReactRoblox,
}
