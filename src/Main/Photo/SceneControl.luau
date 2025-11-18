--!strict
local Lighting = game:GetService("Lighting")

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Trove = require(pluginRoot.Packages.Trove)
local State = require(pluginRoot.Main.State)

local photoRoot = script:FindFirstAncestor("Photo")
local Screenshot = require(photoRoot.Captures.Screenshot)
local UIHider = require(photoRoot.Tools.UIHider)

local RunService = game:GetService("RunService") :: RunService
local UserInputService = game:GetService("UserInputService") :: UserInputService

local SceneControl = {}

-- Private

local function hideMouse()
	local trove = Trove.new()

	pcall(function()
		local studioSettings = settings().Studio
		local showHoverOver = studioSettings["Show Hover Over"]
		studioSettings["Show Hover Over"] = false

		trove:Add(function()
			studioSettings["Show Hover Over"] = showHoverOver
		end)
	end)

	local wasMouseIconEnabled = UserInputService.MouseIconEnabled
	UserInputService.MouseIconEnabled = true

	return SceneControl.once(function()
		trove:Destroy()
		UserInputService.MouseIconEnabled = wasMouseIconEnabled
	end)
end

local function freezeCamera()
	local camera = workspace.CurrentCamera

	local prevCameraType = camera.CameraType
	local prevCameraCFrame = camera.CFrame
	local prevCameraFocus = camera.Focus

	camera.CameraType = Enum.CameraType.Scriptable

	return SceneControl.once(function()
		camera.CameraType = prevCameraType
		camera.CFrame = prevCameraCFrame
		camera.Focus = prevCameraFocus
	end)
end

local function freezeEmitters()
	local map: { [string]: { [string]: any } } = {
		["Beam"] = { TextureSpeed = 0 },

		["Fire"] = { TimeScale = 0 },
		["Smoke"] = { TimeScale = 0 },
		["Sparkles"] = { TimeScale = 0 },
		["ParticleEmitter"] = { TimeScale = 0 },

		["Terrain"] = { WaterWaveSpeed = 0 },
	}

	local undoCallbacks = {}
	for _, descendant in workspace:GetDescendants() do
		for className, properties in map do
			if descendant:IsA(className) then
				local prevProperties = {}
				for property, value in properties do
					prevProperties[property] = descendant[property]
					descendant[property] = value
				end

				table.insert(undoCallbacks, function()
					for property, value in prevProperties do
						descendant[property] = value
					end
				end)
			end
		end
	end

	return SceneControl.once(function()
		for _, undo in undoCallbacks do
			undo()
		end
	end)
end

-- Public

function SceneControl.once<T..., U...>(callback: (T...) -> U...)
	local hasRun = false
	return function(...: T...)
		if not hasRun then
			hasRun = true
			return callback(...)
		end
	end
end

function SceneControl.freeze(isViewport: boolean, callback: () -> ())
	local trove = Trove.new()

	trove:Add(hideMouse())
	if isViewport then
		trove:Add(freezeCamera())
		trove:Add(freezeEmitters())
	end

	local success, err: string? = pcall(callback)
	trove:Destroy()
	return success, err
end

function SceneControl.hideScreenUI(rect: Rect)
	local scaleOS = State.read().temporary.scaleOS

	local exclusions = {}
	if UIHider.ViewportApp and not Screenshot.isFullscreenRect(rect) and Screenshot.isUnitScaleOS(scaleOS) then
		table.insert(exclusions, UIHider.ViewportApp)
	end

	local uiHider = UIHider.new({
		exclusions = exclusions,
		hiddenClasses = { "ScreenGui" },
	})

	return SceneControl.once(function()
		uiHider:Destroy()
	end)
end

function SceneControl.getAppliedColorCorrectionCopy()
	local effects = {}
	for _, child in Lighting:GetChildren() do
		if child:IsA("ColorCorrectionEffect") then
			table.insert(effects, child)
		end
	end

	for i = #effects, 1, -1 do
		if effects[i].Enabled then
			return effects[i]:Clone()
		end
	end

	return Instance.new("ColorCorrectionEffect")
end

function SceneControl.hideAtmosphere()
	local atmospheres = {}
	for _, child in Lighting:GetChildren() do
		if child:IsA("Atmosphere") then
			child.Parent = nil
			table.insert(atmospheres, child)
		end
	end

	return SceneControl.once(function()
		for _, atmosphere in atmospheres do
			atmosphere.Parent = Lighting
		end
	end)
end

function SceneControl.isGradedLightingRequired()
	if not Lighting:FindFirstChildWhichIsA("Atmosphere") then
		local children = Lighting:GetChildren()
		for i = #children, 1, -1 do
			local child = children[i]
			if child:IsA("ColorGradingEffect") and child.Enabled then
				return child.TonemapperPreset ~= Enum.TonemapperPreset.Retro
			end
		end
	end
	return true
end

function SceneControl.applyGradedLighting()
	local clouds = {}
	for _, child in workspace.Terrain:GetChildren() do
		if child:IsA("Clouds") then
			child.Parent = nil
			table.insert(clouds, child)
		end
	end

	return SceneControl.once(function()
		for _, cloud in clouds do
			cloud.Parent = workspace.Terrain
		end
	end)
end

function SceneControl.applyRetroLighting()
	local undoGradedLighting = SceneControl.applyGradedLighting()
	local undoHideAtmosphere = SceneControl.hideAtmosphere()

	local exposureCompensation = Lighting.ExposureCompensation
	Lighting.ExposureCompensation = 0

	local effects = {}
	for _, child in Lighting:GetChildren() do
		if child:IsA("ColorGradingEffect") then
			child.Parent = nil
			table.insert(effects, child)
		end
	end

	local retroGrading = Instance.new("ColorGradingEffect")
	retroGrading.Name = "PhotoboothRetroGrading"
	retroGrading.TonemapperPreset = Enum.TonemapperPreset.Retro
	retroGrading.Parent = Lighting

	return SceneControl.once(function()
		undoGradedLighting()
		undoHideAtmosphere()
		Lighting.ExposureCompensation = exposureCompensation

		retroGrading:Destroy()
		for _, effect in effects do
			effect.Parent = Lighting
		end
	end)
end

function SceneControl.yieldUntilNextFrame()
	RunService.PreRender:Wait()
	RunService.Heartbeat:Wait()
end

return SceneControl
