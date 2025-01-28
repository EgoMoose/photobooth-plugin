--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Trove = require(pluginRoot.Packages.Trove)

local photoRoot = script:FindFirstAncestor("Photo")
local Screenshot = require(photoRoot.Captures.Screenshot)
local SceneControl = require(photoRoot.SceneControl)
local UIBounds = require(photoRoot.Tools.UIBounds)

local capturesRoot = script:FindFirstAncestor("Captures")
local reverseBlend = require(capturesRoot.Composers.Parallel.ReverseBlend)

local function operation(uiBounds: UIBounds.UIBounds, trove: Trove.Trove)
	local targetRect = uiBounds:GetRect()

	uiBounds:SetColor(Color3.new(1, 1, 1))
	SceneControl.yieldUntilNextFrame()
	local onWhite = Screenshot.rect(targetRect)

	uiBounds:SetColor(Color3.new(0, 0, 0))
	SceneControl.yieldUntilNextFrame()
	local onBlack = Screenshot.rect(targetRect)

	local colorCorrection = Instance.new("ColorCorrectionEffect")
	trove:Add(colorCorrection)

	return reverseBlend(onWhite, onBlack, nil, colorCorrection)
end

return operation
