--!strict

local Lighting = game:GetService("Lighting") :: Lighting

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Image = require(pluginRoot.Utilities.Image)
local Trove = require(pluginRoot.Packages.Trove)

local photoRoot = script:FindFirstAncestor("Photo")
local Screenshot = require(photoRoot.Captures.Screenshot)
local Background = require(photoRoot.Tools.Background)
local SceneControl = require(photoRoot.SceneControl)
local Skybox = require(photoRoot.Tools.Skybox)

type Background = Background.Background

local function captureViewportMask(rect: Rect, trove: Trove.Trove)
	local descendants = SceneControl.Utils.filterInstancesMap(game:GetDescendants(), {
		adornedUI = function(instance)
			return instance:IsA("BillboardGui") or instance:IsA("SurfaceGui")
		end,
	})

	-- white skybox to guarantee that our black fog technique contrasts
	local skybox = Skybox.new()
	skybox:SetTexture(Skybox.Textures.White)
	skybox:SetEnabled(true)
	trove:Add(function()
		skybox:Destroy()
	end)

	local undoNeverOnTopUI = SceneControl.Utils.setTemporaryProperties(descendants.adornedUI, {
		AlwaysOnTop = false,
	})
	trove:Add(undoNeverOnTopUI)

	-- NOTE: the fog technique hides partially transparent neon parts...
	local undoFog = SceneControl.Utils.setTemporaryProperties({ Lighting }, {
		FogColor = Color3.new(0, 0, 0),
		FogStart = 0,
		FogEnd = 0,
	})
	trove:Add(undoFog)

	SceneControl.yieldUntilNextFrame()
	local fogMask = Screenshot.rect(rect)

	for h = 1, fogMask.size.Y do
		for w = 1, fogMask.size.X do
			local pixelIndex = fogMask:GetPixelIndex(w, h)

			local fogMaskR = fogMask:GetRGBA255(pixelIndex)
			local alpha = 255 - fogMaskR

			fogMask:SetRGBA255(pixelIndex, 255, 255, 255, alpha)
		end
	end

	skybox:Destroy()
	undoNeverOnTopUI()
	undoFog()

	return fogMask
end

local function compose(onBlack: Image.Image, mask: Image.Image)
	for h = 1, onBlack.size.Y do
		for w = 1, onBlack.size.X do
			local pixelIndex = onBlack:GetPixelIndex(w, h)

			local r, g, b = onBlack:GetRGBA(pixelIndex)
			local _, _, _, alpha = mask:GetRGBA(pixelIndex)

			if alpha > 0 and alpha < 1 then
				-- the foreground has some transparency in it so given we know the alpha and the skybox
				-- we should be able to calculate what we'd have to blend on top to get the final result

				-- rgbOutput = (rgbForeground * alphaForeground + rgbBackground * alphaBackground * (1 - alphaForeground)) / alphaOutput
				-- rgbForeground = (rgbOutput * alphaOutput - rgbBackground * alphaBackground * (1 - alphaForeground)) / alphaForeground

				-- this becomes even more simplified b/c we know the alphaBackground and alphaOutput both equal 1
				-- rgbForeground = (rgbOutput - rgbBackground * (1 - alphaForeground)) / alphaForeground

				-- and since the rgbBackground = 0
				-- rgbForeground = rgbOutput / alphaForeground

				r = r / alpha
				g = g / alpha
				b = b / alpha
			end

			onBlack:SetRGBA(pixelIndex, r, g, b, math.clamp(alpha, 0, 1))
		end
	end

	return onBlack
end

local function operation(rect: Rect, background: Background, trove: Trove.Trove)
	local redoCloudsAndFog = SceneControl.Lighting.removeCloudsAndFog()
	local undoRetroGrading = SceneControl.Lighting.applyRetroColorGrading()
	trove:Add(redoCloudsAndFog)
	trove:Add(undoRetroGrading)

	background:SetEnabled(true)
	background:SetColor(Color3.new(0, 0, 0))
	SceneControl.yieldUntilNextFrame()
	local onBlack = Screenshot.rect(rect)

	background:SetEnabled(false)
	local mask = captureViewportMask(rect, trove)

	redoCloudsAndFog()
	undoRetroGrading()

	return compose(onBlack, mask)
end

return operation
