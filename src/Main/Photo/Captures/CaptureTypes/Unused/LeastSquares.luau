--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Matrix = require(pluginRoot.Utilities.Matrix)
local Image = require(pluginRoot.Utilities.Image)
local Trove = require(pluginRoot.Packages.Trove)

local photoRoot = script:FindFirstAncestor("Photo")
local Screenshot = require(photoRoot.Captures.Screenshot)
local Background = require(photoRoot.Tools.Background)
local SceneControl = require(photoRoot.SceneControl)

local COLOR_SAMPLES = { Color3.new(0, 0, 0), Color3.new(1, 1, 1) }

type Background = Background.Background

local function compareByMargin(a: { number }, b: { number }, margin: number): boolean
	-- stylua: ignore
	return (
			math.abs(a[1] - b[1]) <= margin 
		and math.abs(a[2] - b[2]) <= margin
		and math.abs(a[3] - b[3]) <= margin
	)
end

local function compose(unmodified: Image.Image, samples: { [Image.Image]: Color3 })
	for h = 1, unmodified.size.Y do
		for w = 1, unmodified.size.X do
			local pixelIndex = unmodified:GetPixelIndex(w, h)

			local AMatrixComponents = {}
			local bMatrixComponents = {}

			local sampleCount = 0
			local matchesCount = 0
			for onBackground, background in samples do
				sampleCount = sampleCount + 1

				local rgbaOnBackground = { onBackground:GetRGBA(pixelIndex) }
				local rgbaBackground = { background.R, background.G, background.B, 1 }

				if compareByMargin(rgbaOnBackground, rgbaBackground, 0) then
					matchesCount = matchesCount + 1
				end

				table.insert(AMatrixComponents, { 1, 0, 0, rgbaBackground[1] - rgbaOnBackground[1] })
				table.insert(AMatrixComponents, { 0, 1, 0, rgbaBackground[2] - rgbaOnBackground[2] })
				table.insert(AMatrixComponents, { 0, 0, 1, rgbaBackground[3] - rgbaOnBackground[3] })

				table.insert(bMatrixComponents, { rgbaBackground[1] })
				table.insert(bMatrixComponents, { rgbaBackground[2] })
				table.insert(bMatrixComponents, { rgbaBackground[3] })
			end

			if sampleCount == matchesCount then
				-- the pixels in both samples are the same as the background
				-- this implies that we can safely assume
				local r, g, b = unmodified:GetRGBA(pixelIndex)
				unmodified:SetRGBA(pixelIndex, r, g, b, 0)
			else
				local x = Matrix.leastSquares(AMatrixComponents, bMatrixComponents)
				unmodified:SetRGBA(pixelIndex, x[1][1], x[2][1], x[3][1], 1 / x[4][1])
			end
		end
	end

	return unmodified
end

local function operation(rect: Rect, background: Background, trove: Trove.Trove)
	if game:GetService("Lighting"):FindFirstChildWhichIsA("Atmosphere") then
		error("WARN: Skybox cannot be removed when Atmosphere is present.", 0)
	end

	local unmodified = Screenshot.rect(rect)

	local redoCloudsAndFog = SceneControl.Lighting.removeCloudsAndFog()
	local undoRetroGrading = SceneControl.Lighting.applyRetroColorGrading()
	trove:Add(redoCloudsAndFog)
	trove:Add(undoRetroGrading)

	background:SetEnabled(true)

	local onBackgrounds = {}
	for i = 1, #COLOR_SAMPLES do
		background:SetColor(COLOR_SAMPLES[i])
		SceneControl.yieldUntilNextFrame()
		onBackgrounds[i] = Screenshot.rect(rect)
	end

	background:SetEnabled(false)
	redoCloudsAndFog()
	undoRetroGrading()

	local samples = {}
	for i = 1, #COLOR_SAMPLES do
		samples[onBackgrounds[i]] = COLOR_SAMPLES[i]
	end

	return compose(unmodified, samples)
end

return operation
