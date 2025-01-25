--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Image = require(pluginRoot.Utilities.Image)
local Trove = require(pluginRoot.Packages.Trove)

local photoRoot = script:FindFirstAncestor("Photo")
local Screenshot = require(photoRoot.Captures.Screenshot)
local SceneControl = require(photoRoot.SceneControl)
local UIBounds = require(photoRoot.Tools.UIBounds)

local COMPARE_MARGIN = 0

local function compareByMargin(a: { number }, b: { number }, margin: number): boolean
	-- stylua: ignore
	return (
			math.abs(a[1] - b[1]) <= margin 
		and math.abs(a[2] - b[2]) <= margin
		and math.abs(a[3] - b[3]) <= margin
	)
end

local function reverseBlend(Wo: { number }, Wb: { number }, Bo: { number }, Bb: { number }): { number }
	local maxAlpha = 0
	local rgb = { 0, 0, 0 }

	for i = 1, 3 do
		local alpha = (Wo[i] - Wb[i] - Bo[i] + Bb[i]) / (Bb[i] - Wb[i])
		if alpha > 0 then
			rgb[i] = Bb[i] + (Bo[i] - Bb[i]) / alpha
		end
		maxAlpha = math.max(maxAlpha, alpha)
	end

	return { rgb[1], rgb[2], rgb[3], math.clamp(maxAlpha, 0, 1) * 255 }
end

local function compose(onWhite: Image.Image, onBlack: Image.Image)
	local Wb = { 255, 255, 255, 255 }
	local Bb = { 0, 0, 0, 255 }

	for h = 1, onBlack.size.Y do
		for w = 1, onBlack.size.X do
			local pixelIndex = onBlack:GetPixelIndex(w, h)

			local Wo = { onWhite:GetRGBA255(pixelIndex) }
			local Bo = { onBlack:GetRGBA255(pixelIndex) }

			if compareByMargin(Wo, Wb, 0) and compareByMargin(Bo, Bb, 0) then
				-- in both samples the pixels match their backgrounds perfectly
				-- this means that this pixel is guaranteed to be a background pixel
				onBlack:SetRGBA255(pixelIndex, 255, 255, 255, 0)
			elseif not compareByMargin(Wo, Bo, COMPARE_MARGIN) then
				-- the pixels differ between the two versions of the image
				-- this means their must be some alpha we have to calculate
				local rgba = reverseBlend(Wo, Wb, Bo, Bb)
				onBlack:SetRGBA255(pixelIndex, rgba[1], rgba[2], rgba[3], rgba[4])
			end
		end
	end

	return onBlack
end

local function operation(uiBounds: UIBounds.UIBounds, trove: Trove.Trove)
	local targetRect = uiBounds:GetRect()

	uiBounds:SetColor(Color3.new(1, 1, 1))
	SceneControl.yieldUntilNextFrame()
	local onWhite = Screenshot.rect(targetRect)

	uiBounds:SetColor(Color3.new(0, 0, 0))
	SceneControl.yieldUntilNextFrame()
	local onBlack = Screenshot.rect(targetRect)

	return compose(onWhite, onBlack)
end

return operation
