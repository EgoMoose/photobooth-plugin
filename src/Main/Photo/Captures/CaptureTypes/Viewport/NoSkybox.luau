--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Image = require(pluginRoot.Utilities.Image)
local Trove = require(pluginRoot.Packages.Trove)

local photoRoot = script:FindFirstAncestor("Photo")
local Screenshot = require(photoRoot.Captures.Screenshot)
local Background = require(photoRoot.Tools.Background)
local SceneControl = require(photoRoot.SceneControl)

local capturesRoot = script:FindFirstAncestor("Captures")
local Composers = require(capturesRoot.Composers)

type Background = Background.Background

local function operation(rect: Rect, background: Background, trove: Trove.Trove): ...Image.Image
	if game:GetService("Lighting"):FindFirstChildWhichIsA("Atmosphere") then
		warn("Skybox cannot be removed when Atmosphere is present.")
		error("SKIP", 0)
	end

	local colorCorrection = SceneControl.Lighting.getAppliedColorCorrectionCopy()
	trove:Add(colorCorrection)

	local redoColorCorrection = SceneControl.Lighting.removeColorCorrection()
	trove:Add(redoColorCorrection)

	local redoCloudsAndFog = SceneControl.Lighting.removeCloudsAndFog()
	trove:Add(redoCloudsAndFog)

	background:SetEnabled(true)
	background:SetColor(Color3.new(0, 0, 0))

	local onBlack: Image.Image?
	if SceneControl.Lighting.getTonemapperPreset() ~= Enum.TonemapperPreset.Retro then
		SceneControl.yieldUntilNextFrame()
		onBlack = Screenshot.rect(rect)
	end

	local undoRetroGrading = SceneControl.Lighting.applyRetroColorGrading()
	trove:Add(undoRetroGrading)

	SceneControl.yieldUntilNextFrame()
	local onBlackRetro = Screenshot.rect(rect)

	background:SetColor(Color3.new(1, 1, 1))
	SceneControl.yieldUntilNextFrame()
	local onWhiteRetro = Screenshot.rect(rect)

	background:SetEnabled(false)
	redoCloudsAndFog()
	undoRetroGrading()
	redoColorCorrection()

	return Composers.reverseBlend(onWhiteRetro, onBlackRetro, onBlack, colorCorrection)
end

return operation
