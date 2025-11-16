--!strict

local RunService = game:GetService("RunService") :: RunService

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Screenshot = require(pluginRoot.Main.Photo.Captures.Screenshot)
local UserInterface = require(pluginRoot.Main.UserInterface)
local Bindings = require(pluginRoot.Main.Bindings)
local State = require(pluginRoot.Main.State)

local Plugin = {}

local DISPLAY_SCALE_WARNING = false

-- Private

local function waitForViewportSettled(minTime: number)
	local timestamp = os.clock()
	local viewportSize = workspace.CurrentCamera.ViewportSize

	while os.clock() - timestamp < minTime do
		local newViewportSize = workspace.CurrentCamera.ViewportSize
		if newViewportSize ~= viewportSize then
			viewportSize = newViewportSize
			timestamp = os.clock()
		end
		RunService.Heartbeat:Wait()
	end
end

local function updateScaleOS()
	local scale = Screenshot.calculateScaleOS()
	State.mutate(function(state)
		state.temporary.scaleOS = scale
	end)

	if DISPLAY_SCALE_WARNING and not (scale.X == 1 and scale.Y == 1) then
		warn(table.concat({
			"",
			"Photobooth - OS scaling detected!",
			`The plugin will attempt to adjust for the following scale factor: ({scale.X}, {scale.Y})`,
			"For optimal results please use a resolution that matches your display and restart studio.",
		}, "\n"))
	end
end

-- Public

function Plugin.build(plugin: Plugin)
	if not (RunService:IsStudio() and RunService:IsEdit()) then
		return
	end

	State.setup(plugin)

	task.spawn(function()
		-- the viewport size must remain unchanged for X seconds
		waitForViewportSettled(1)
		updateScaleOS()
	end)

	local toolbar = plugin:CreateToolbar("Photobooth")

	UserInterface.mountCaptureViewport(plugin, toolbar)
	UserInterface.mountCaptureUI(plugin, toolbar)
	UserInterface.mountGallery(plugin, toolbar)

	Bindings.setup(plugin)
end

return Plugin
