--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Matrix = require(pluginRoot.Utilities.Matrix)
local Image = require(pluginRoot.Utilities.Image)
local Trove = require(pluginRoot.Packages.Trove)

local photoRoot = script:FindFirstAncestor("Photo")
local BillboardBackground = require(photoRoot.Tools.BillboardBackground)
local Screenshot = require(photoRoot.Captures.Screenshot)
local SceneControl = require(photoRoot.SceneControl)

local COMPARE_MARGIN = 0

type BillboardBackground = BillboardBackground.BillboardBackground

local function compareByMargin(a: { number }, b: { number }, margin: number): boolean
	-- stylua: ignore
	return (
			math.abs(a[1] - b[1]) <= margin 
		and math.abs(a[2] - b[2]) <= margin
		and math.abs(a[3] - b[3]) <= margin
	)
end

local function reverseBlend(Wo: { number }, Wb: { number }, Bo: { number }, Bb: { number })
	local rgb = {}
	for i = 1, 3 do
		local d = Bo[i] - Bb[i] + Wb[i] - Wo[i]

		if d ~= 0 then
			rgb[i] = (Wb[i] * Bo[i] - Bb[i] * Wo[i]) / d
		else
			rgb[i] = 0
		end
	end

	local A = {
		{ rgb[1] - Wb[1] },
		{ rgb[2] - Wb[2] },
		{ rgb[3] - Wb[3] },
		{ rgb[1] - Bb[1] },
		{ rgb[2] - Bb[2] },
		{ rgb[3] - Bb[3] },
	}

	local b = {
		{ Wo[1] - Wb[1] },
		{ Wo[2] - Wb[2] },
		{ Wo[3] - Wb[3] },
		{ Bo[1] - Bb[1] },
		{ Bo[2] - Bb[2] },
		{ Bo[3] - Bb[3] },
	}

	local x = Matrix.leastSquares(A, b)
	return { rgb[1], rgb[2], rgb[3], x[1][1] * 255 }
end

local function compose(onWhiteRetro: Image.Image, onBlackRetro: Image.Image)
	local Wb = { 255, 255, 255, 255 }
	local Bb = { 0, 0, 0, 255 }

	for h = 1, onBlackRetro.size.Y do
		for w = 1, onBlackRetro.size.X do
			local pixelIndex = onBlackRetro:GetPixelIndex(w, h)

			local Wo = { onWhiteRetro:GetRGBA255(pixelIndex) }
			local Bo = { onBlackRetro:GetRGBA255(pixelIndex) }

			if compareByMargin(Wo, Wb, 0) and compareByMargin(Bo, Bb, 0) then
				-- in both samples the pixels match their backgrounds perfectly
				-- this means that this pixel is guaranteed to be a background pixel
				onBlackRetro:SetRGBA255(pixelIndex, 255, 255, 255, 0)
			elseif not compareByMargin(Wo, Bo, COMPARE_MARGIN) then
				-- the pixels differ between the two versions of the image
				-- this means their must be some alpha we have to calculate
				local rgba = reverseBlend(Wo, Wb, Bo, Bb)
				onBlackRetro:SetRGBA255(pixelIndex, rgba[1], rgba[2], rgba[3], rgba[4])
			end
		end
	end

	return onBlackRetro
end

local function operation(rect: Rect, billboardBackground: BillboardBackground, trove: Trove.Trove)
	if game:GetService("Lighting"):FindFirstChildWhichIsA("Atmosphere") then
		warn("Skybox cannot be removed when Atmosphere is present.")
		return
	end

	local redoCloudsAndFog = SceneControl.Lighting.removeCloudsAndFog()
	local undoRetroGrading = SceneControl.Lighting.applyRetroColorGrading()
	trove:Add(redoCloudsAndFog)
	trove:Add(undoRetroGrading)

	billboardBackground:SetEnabled(true)

	billboardBackground:SetColor(Color3.new(0, 0, 0))
	SceneControl.yieldUntilNextFrame()
	local onBlack = Screenshot.rect(rect)
	trove:Add(onBlack :: any)

	billboardBackground:SetColor(Color3.new(1, 1, 1))
	SceneControl.yieldUntilNextFrame()
	local onWhite = Screenshot.rect(rect)
	trove:Add(onBlack :: any)

	billboardBackground:SetEnabled(false)
	redoCloudsAndFog()
	undoRetroGrading()

	return compose(onWhite, onBlack)
end

return operation
