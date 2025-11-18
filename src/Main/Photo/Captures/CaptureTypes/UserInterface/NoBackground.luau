--!strict

local CoreGui = game:GetService("CoreGui") :: CoreGui

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Trove = require(pluginRoot.Packages.Trove)

local Types = require(pluginRoot.Main.Bindings.Interface.Types)
local State = require(pluginRoot.Main.State)

local photoRoot = script:FindFirstAncestor("Photo")
local Screenshot = require(photoRoot.Captures.Screenshot)
local SceneControl = require(photoRoot.SceneControl)
local UIBounds = require(photoRoot.Tools.UIBounds)
local UIHider = require(photoRoot.Tools.UIHider)

local capturesRoot = script:FindFirstAncestor("Captures")
local Composers = require(capturesRoot.Composers)

local function operation(options: Types.CaptureUIOptions, trove: Trove.Trove)
	local uiBounds = UIBounds.new(CoreGui, options.subject, State.read().temporary.scaleOS)
	local uiHider = UIHider.new({
		hiddenClasses = { "LayerCollector" },
		exclusions = { uiBounds.surfaceGui },
	})

	trove:Add(function()
		uiBounds:Destroy()
		uiHider:Destroy()
	end)

	local targetRect = uiBounds:GetRect()

	uiBounds:SetColor(Color3.new(1, 1, 1))
	SceneControl.yieldUntilNextFrame()
	local onWhite = Screenshot.rect(targetRect)

	uiBounds:SetColor(Color3.new(0, 0, 0))
	SceneControl.yieldUntilNextFrame()
	local onBlack = Screenshot.rect(targetRect)

	local colorCorrection = Instance.new("ColorCorrectionEffect")
	trove:Add(colorCorrection)

	local capture = Composers.reverseBlend(onWhite, onBlack, nil, colorCorrection)
	if options.alphaBleed then
		capture = Composers.alphaBleed(capture)
	end

	return capture
end

return operation
