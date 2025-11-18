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

	local fogBackground = Background.new(workspace)
	fogBackground:SetColor(Color3.new(0, 0, 0))
	fogBackground:SetEnabled(true)

	trove:Add(SceneControl.once(function()
		fogBackground:Destroy()
	end))

	-- capture on graded black
	local preRetroYieldCount = 1
	local gradedOnBlack: Image.Image?
	if SceneControl.isGradedCaptureRequired() then
		if Lighting:FindFirstChildWhichIsA("Atmosphere") then
			trove:Add(SceneControl.hideAtmosphere())
			preRetroYieldCount = 100
		end

		local undoGradedLighting = trove:Add(SceneControl.applyGradedLighting())

		SceneControl.yieldUntilNextFrame()
		gradedOnBlack = Screenshot.rect(options.rect)

		undoGradedLighting()
	end

	-- prepare for retro scene capturing
	trove:Add(SceneControl.applyRetroLighting())

	-- capture on retro black
	for _i = 1, preRetroYieldCount do
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
