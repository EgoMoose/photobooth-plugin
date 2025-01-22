--!strict

local Lighting = game:GetService("Lighting") :: Lighting

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Sift = require(pluginRoot.Packages.Sift)

local SceneUtils = require(script.Parent.SceneUtils)

local LightingUtils = {}

-- Public

function LightingUtils.getTonemapperPreset()
	local gradingEffects = SceneUtils.filterInstances(Lighting:GetChildren(), function(child)
		return SceneUtils.isAny(child, {
			"ColorGradingEffect",
		})
	end)

	for i = #gradingEffects, 1, -1 do
		local lastEffect = gradingEffects[i]
		if lastEffect:IsA("ColorGradingEffect") and lastEffect.Enabled then
			return lastEffect.TonemapperPreset
		end
	end

	return Enum.TonemapperPreset.Default
end

function LightingUtils.getColorCorrection()
	local colorCorrectionEffects = SceneUtils.filterInstances(Lighting:GetChildren(), function(child)
		return SceneUtils.isAny(child, {
			"ColorCorrectionEffect",
		})
	end)

	for i = #colorCorrectionEffects, 1, -1 do
		local lastEffect = colorCorrectionEffects[i]
		if lastEffect:IsA("ColorCorrectionEffect") and lastEffect.Enabled then
			return lastEffect:Clone()
		end
	end

	return Instance.new("ColorCorrectionEffect")
end

function LightingUtils.removeColorCorrection()
	local colorCorrectionEffects = SceneUtils.filterInstances(Lighting:GetChildren(), function(child)
		return SceneUtils.isAny(child, {
			"ColorCorrectionEffect",
		})
	end)

	return SceneUtils.oneTimeCallback(SceneUtils.setTemporaryProperties(colorCorrectionEffects, {
		Parent = Sift.None,
	}))
end

function LightingUtils.applyRetroColorGrading()
	local retroColorGrading = Instance.new("ColorGradingEffect")
	retroColorGrading.Name = "PhotoboothRetroGrading"
	retroColorGrading.TonemapperPreset = Enum.TonemapperPreset.Retro
	retroColorGrading.Parent = Lighting

	return SceneUtils.oneTimeCallback(function()
		retroColorGrading:Destroy()
	end)
end

function LightingUtils.removeCloudsAndFog()
	local terrainFiltered = SceneUtils.filterInstances(workspace.Terrain:GetChildren(), function(child)
		return SceneUtils.isAny(child, {
			"Clouds",
		})
	end)

	local redoTerrainChildren = SceneUtils.setTemporaryProperties(terrainFiltered, {
		Parent = Sift.None,
	})

	local redoLightingProperties = SceneUtils.setTemporaryProperties({ Lighting }, {
		FogStart = math.huge,
		FogEnd = math.huge,
		FogColor = Color3.new(1, 1, 1),
	})

	return SceneUtils.oneTimeCallback(function()
		redoTerrainChildren()
		redoLightingProperties()
	end)
end

--

return LightingUtils
