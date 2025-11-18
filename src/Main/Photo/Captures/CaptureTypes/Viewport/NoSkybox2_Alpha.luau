--!strict

local Lighting = game:GetService("Lighting") :: Lighting

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Image = require(pluginRoot.Utilities.Image)
local Trove = require(pluginRoot.Packages.Trove)

local Types = require(pluginRoot.Main.Bindings.Interface.Types)

local photoRoot = script:FindFirstAncestor("Photo")
local Screenshot = require(photoRoot.Captures.Screenshot)
local Background = require(photoRoot.Tools.Background)
local SceneControl = require(photoRoot.SceneControl)

local capturesRoot = script:FindFirstAncestor("Captures")
local Composers = require(capturesRoot.Composers)

local function operation(options: Types.CaptureViewportOptions, trove: Trove.Trove): ...Image.Image
	trove:Add(SceneControl.hideScreenUI(options.rect))
	local colorCorrection = trove:Add(SceneControl.getAppliedColorCorrectionCopy())

	-- capture on neon black
	local undoGradedLighting = trove:Add(SceneControl.applyGradedLighting())

	local neonBackground = Background.neon(workspace)
	neonBackground:SetColor(Color3.new(0, 0, 0))
	neonBackground:SetEnabled(true)

	local undoNeonBackground = trove:Add(SceneControl.once(function()
		neonBackground:Destroy()
	end))

	SceneControl.yieldUntilNextFrame()
	local gradedOnBlack = Screenshot.rect(options.rect)

	undoNeonBackground()
	undoGradedLighting()

	-- prepare for retro scene capturing
	trove:Add(SceneControl.applyRetroLighting())

	local fogBackground = Background.new(workspace)
	fogBackground:SetColor(Color3.new(0, 0, 0))
	fogBackground:SetEnabled(true)

	trove:Add(SceneControl.once(function()
		fogBackground:Destroy()
	end))

	-- capture on retro black
	for _i = 1, 100 do
		-- yield until the atmosphere updates
		SceneControl.yieldUntilNextFrame()
	end

	local onBlackRetro = Screenshot.rect(options.rect)

	-- capture on retro white
	fogBackground:SetColor(Color3.new(1, 1, 1))
	SceneControl.yieldUntilNextFrame()
	local onWhiteRetro = Screenshot.rect(options.rect)

	-- remove background & alpha bleed
	local capture = Composers.reverseBlend(onWhiteRetro, onBlackRetro, gradedOnBlack, colorCorrection)
	if options.alphaBleed then
		capture = Composers.alphaBleed(capture)
	end

	return capture
end

return operation
