local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Timeout = require(pluginRoot.Utilities.Timeout)
local Image = require(pluginRoot.Utilities.Image)

local COMPARE_MARGIN = 0

local Wb = { 255, 255, 255, 255 }
local Bb = { 0, 0, 0, 255 }

local function compareByMargin(a: { number }, b: { number }, margin: number): boolean
	-- stylua: ignore
	return (
			math.abs(a[1] - b[1]) <= margin 
		and math.abs(a[2] - b[2]) <= margin
		and math.abs(a[3] - b[3]) <= margin
	)
end

local function workerAction(
	size: Vector2,
	colorCorrection: ColorCorrectionEffect,
	whiteRetroBuffer: buffer,
	blackRetroBuffer: buffer,
	blackBuffer: buffer?
)
	local brightness = colorCorrection.Brightness
	local contrast = colorCorrection.Contrast + 1
	local saturation = colorCorrection.Saturation + 1

	local tintColor = colorCorrection.TintColor
	local tint = { tintColor.R, tintColor.G, tintColor.B }

	local onWhiteRetro = Image.fromBuffer(whiteRetroBuffer, size)
	local onBlackRetro = Image.fromBuffer(blackRetroBuffer, size)
	local onBlack = if blackBuffer then Image.fromBuffer(blackBuffer, size) else onBlackRetro:Clone()

	for h = 1, onBlack.size.Y do
		for w = 1, onBlack.size.X do
			Timeout.tryYield()

			local pixelIndex = onBlack:GetPixelIndex(w, h)

			local Wo = { onWhiteRetro:GetRGBA255(pixelIndex) }
			local Bo = { onBlackRetro:GetRGBA255(pixelIndex) }

			if compareByMargin(Wo, Wb, 0) and compareByMargin(Bo, Bb, 0) then
				-- in both samples the pixels match their backgrounds perfectly
				-- this means that this pixel is guaranteed to be a background pixel
				onBlack:SetRGBA255(pixelIndex, 0, 0, 0, 0)
				continue
			end

			if not compareByMargin(Wo, Bo, COMPARE_MARGIN) then
				-- the pixels differ between the two versions of the image
				-- this means their must be some alpha we have to calculate
				local uBo = { onBlack:GetRGBA255(pixelIndex) }

				local maxAlpha = 0
				for i = 1, 3 do
					local alpha = (Wo[i] - Wb[i] - Bo[i] + Bb[i]) / (Bb[i] - Wb[i])
					maxAlpha = math.max(maxAlpha, math.clamp(alpha, 0, 1))
				end

				local rgb = { 0, 0, 0 }
				for i = 1, 3 do
					rgb[i] = math.clamp(Bb[i] + (uBo[i] - Bb[i]) / maxAlpha, 0, 255)
				end

				onBlack:SetRGBA255(pixelIndex, rgb[1], rgb[2], rgb[3], maxAlpha * 255)
			end

			-- apply color correction
			local rgba = { onBlack:GetRGBA(pixelIndex) }
			local gray = 0.345 * rgba[1] + 0.553 * rgba[2] + 0.114 * rgba[3]

			for i = 1, 3 do
				local component = rgba[i]
				component = component * saturation + (1 - saturation) * gray -- saturation
				component = ((component - 0.5) * math.max(0, contrast)) + 0.5 -- contrast
				component = component + brightness -- brightness
				component = component * tint[i] -- tint
				rgba[i] = math.clamp(component, 0, 1)
			end

			onBlack:SetRGBA(pixelIndex, rgba[1], rgba[2], rgba[3], rgba[4])
		end
	end

	return onBlack.buffer
end

return workerAction
