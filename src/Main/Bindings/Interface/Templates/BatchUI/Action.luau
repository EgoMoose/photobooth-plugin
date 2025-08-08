--!strict

--[[
	Instructions:
		1. Copy this template to the StarterGui.
		2. Place all the UI elements you'd like to capture in the CaptureFolder.
		3. Run `require(game.ServerStorage.PhotoboothBindings).execute(game.StarterGui.BatchUI.Action)` in the command bar.
		4. After completion your captures will be in a timestamped folder under the StarterGui.
	
	CAPTURE_DELAY
		> This represents how much time to delay once the capture target is about to be captured. This can be useful
		> when your targets have elements that may need a moment to fully render (i.e. viewport frames)
--]]

local CAPTURE_DELAY = 0

local StarterGui = game:GetService("StarterGui")
local ServerStorage = game:GetService("ServerStorage")

local Photobooth = require(ServerStorage.PhotoboothBindings)

local screen = script.Parent
local folder = screen.CaptureFolder

local function capture()
	local outputFolder = Instance.new("Folder")
	for _, child in folder:GetChildren() do
		if child:IsA("GuiObject") and child.Visible then
			local result = Photobooth.captureUI(child, "NoBackground", CAPTURE_DELAY)
			result.Name = child.Name
			result.Parent = outputFolder
		end
	end
	return outputFolder
end

local expect, _revert = Photobooth.reversible(function()
	local results = capture()
	results.Name = DateTime.now():ToIsoDate()
	results.Archivable = false
	results.Parent = StarterGui
end)

local success, err = expect()
if not success then
	error(err)
end
