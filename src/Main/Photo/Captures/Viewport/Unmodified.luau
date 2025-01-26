--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Trove = require(pluginRoot.Packages.Trove)

local photoRoot = script:FindFirstAncestor("Photo")
local Screenshot = require(photoRoot.Captures.Screenshot)
local Background = require(photoRoot.Tools.Background)

local function operation(rect: Rect, _background: Background.Background, _trove: Trove.Trove)
	return Screenshot.rect(rect)
end

return operation
