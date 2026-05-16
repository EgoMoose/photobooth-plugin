local CoreGui = game:GetService("CoreGui") :: CoreGui

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Types = require(pluginRoot.Main.Bindings.Interface.Types)
local Trove = require(pluginRoot.Packages.Trove)

local photoRoot = script:FindFirstAncestor("Photo")
local Screenshot = require(photoRoot.Captures.Screenshot)
local SceneControl = require(photoRoot.SceneControl)
local UIBounds = require(photoRoot.Tools.UIBounds)
local UIHider = require(photoRoot.Tools.UIHider)

local capturesRoot = script:FindFirstAncestor("Captures")
local Composers = require(capturesRoot.Composers)

local function operation(options: Types.CaptureUIOptions, trove: Trove.Trove)
	local uiBounds = UIBounds.new(CoreGui, options.subject, (options.scale or Vector2.new(1, 1)))
	local undoExclude = UIHider.addExclusion(uiBounds.surfaceGui)
	local uiHider = UIHider.new({ "LayerCollector" })

	trove:Add(function()
		uiBounds:Destroy()
		uiHider:Destroy()
		undoExclude()
	end)

	local targetRect = uiBounds:GetRect()

	uiBounds:SetColor(Color3.new(1, 1, 1))
	SceneControl.yieldUntilNextFrame()
	local onWhite = Screenshot.rect(targetRect)

	uiBounds:SetColor(Color3.new(0, 0, 0))
	SceneControl.yieldUntilNextFrame()
	local onBlack = Screenshot.rect(targetRect)

	local colorCorrection = Instance.new("ColorCorrectionEffect")
	colorCorrection.Brightness = 1
	trove:Add(colorCorrection)

	local capture = Composers.reverseBlend(onWhite, onBlack, nil, colorCorrection)
	if options.alphaBleed then
		capture = Composers.alphaBleed(capture)
	end

	return capture
end

return operation
