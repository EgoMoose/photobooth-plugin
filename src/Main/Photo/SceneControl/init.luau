--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Trove = require(pluginRoot.Packages.Trove)

local SceneUtils = require(script.SceneUtils)

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

	return function()
		trove:Destroy()
		UserInputService.MouseIconEnabled = wasMouseIconEnabled
	end
end

local function freezeCamera()
	local camera = workspace.CurrentCamera

	local prevCameraType = camera.CameraType
	local prevCameraCFrame = camera.CFrame
	local prevCameraFocus = camera.Focus

	camera.CameraType = Enum.CameraType.Scriptable

	return function()
		camera.CameraType = prevCameraType
		camera.CFrame = prevCameraCFrame
		camera.Focus = prevCameraFocus
	end
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

	local filterCallbacks = {}
	for className, _ in map do
		filterCallbacks[className] = function(instance)
			return SceneUtils.isAny(instance, { className })
		end
	end

	local filtered = SceneUtils.filterInstancesMap(workspace:GetDescendants(), filterCallbacks)

	local undoCallbacks = {}
	for className, tempProperties in map do
		table.insert(undoCallbacks, SceneUtils.setTemporaryProperties(filtered[className], tempProperties))
	end

	return SceneUtils.oneTimeCallback(function()
		for _, undo in undoCallbacks do
			undo()
		end
	end)
end

-- Public

export type Options = {
	callback: () -> (),

	hideMouse: boolean?,

	freezeCamera: boolean?,
	freezeEmitters: boolean?,
}

function SceneControl.apply(options: Options)
	local trove = Trove.new()

	if options.hideMouse then
		trove:Add(hideMouse())
	end

	if options.freezeCamera then
		trove:Add(freezeCamera())
	end

	if options.freezeEmitters then
		trove:Add(freezeEmitters())
	end

	local success, err = pcall(function()
		options.callback()
	end)

	trove:Destroy()

	return success, err :: string?
end

function SceneControl.yieldUntilNextFrame()
	RunService.PreRender:Wait()
	RunService.Heartbeat:Wait()
end

SceneControl.Utils = SceneUtils
SceneControl.Lighting = require(script.LightingUtils)

return SceneControl
