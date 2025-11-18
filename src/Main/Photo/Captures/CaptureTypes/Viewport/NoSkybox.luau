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
	if Lighting:FindFirstChildWhichIsA("Atmosphere") then
		error("WARN: Skybox cannot be removed when Atmosphere is present.", 0)
	end

	local background = Background.new(workspace)
	trove:Add(function()
		background:Destroy()
	end)

	local colorCorrection = SceneControl.Lighting.getAppliedColorCorrectionCopy()
	trove:Add(colorCorrection)

	local redoColorCorrection = SceneControl.Lighting.removeColorCorrection()
	trove:Add(redoColorCorrection)

	local redoCloudsAndFog = SceneControl.Lighting.removeCloudsAndFog()
	trove:Add(redoCloudsAndFog)

	background:SetEnabled(true)
	background:SetColor(Color3.new(0, 0, 0))

	local isRetroTonemapper = SceneControl.Lighting.getTonemapperPreset() == Enum.TonemapperPreset.Retro

	local exposureCompensation = Lighting.ExposureCompensation
	local redoExposureCompensation = trove:Add(SceneControl.Utils.oneTimeCallback(function()
		Lighting.ExposureCompensation = exposureCompensation
	end))

	local onBlack: Image.Image?
	if not (isRetroTonemapper and exposureCompensation == 0) then
		SceneControl.yieldUntilNextFrame()
		onBlack = Screenshot.rect(options.rect)
	end

	Lighting.ExposureCompensation = 0

	local undoRetroGrading = SceneControl.Lighting.applyRetroColorGrading()
	trove:Add(undoRetroGrading)

	SceneControl.yieldUntilNextFrame()
	local onBlackRetro = Screenshot.rect(options.rect)

	background:SetColor(Color3.new(1, 1, 1))
	SceneControl.yieldUntilNextFrame()
	local onWhiteRetro = Screenshot.rect(options.rect)

	background:SetEnabled(false)
	redoExposureCompensation()
	redoCloudsAndFog()
	undoRetroGrading()
	redoColorCorrection()

	local capture = Composers.reverseBlend(onWhiteRetro, onBlackRetro, onBlack, colorCorrection)
	if options.alphaBleed then
		capture = Composers.alphaBleed(capture)
	end

	return capture
end

return operation
