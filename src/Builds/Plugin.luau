--!strict

local RunService = game:GetService("RunService") :: RunService

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Screenshot = require(pluginRoot.Main.Photo.Captures.Screenshot)
local UserInterface = require(pluginRoot.Main.UserInterface)
local Bindings = require(pluginRoot.Main.Bindings)
local Photo = require(pluginRoot.Main.Photo)

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

	local configuration = Photo.Configuration.get()
	configuration.ScaleOS = scale
	Photo.Configuration.set(configuration)

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

	task.spawn(function()
		-- the viewport size must remain unchanged for X seconds
		waitForViewportSettled(1)
		updateScaleOS()
	end)

	local theme = settings().Studio.Theme
	local toolbar = plugin:CreateToolbar("Photo Booth")

	local openViewportButton = toolbar:CreateButton(
		"egomoose_photobooth_viewport",
		"Capture viewport images",
		`rbxasset://studio_svg_textures/Shared/InsertableObjects/{theme.Name}/Standard/Camera@3x.png`,
		"Viewport"
	)
	UserInterface.mountOpenViewportButton(plugin, openViewportButton)

	local captureUIButton = toolbar:CreateButton(
		"egomoose_photobooth_ui",
		"Capture UI images",
		`rbxasset://studio_svg_textures/Shared/InsertableObjects/{theme.Name}/Standard/Interface@3x.png`,
		"UI"
	)
	UserInterface.mountCaptureUIButton(plugin, captureUIButton)

	local openViewerButton = toolbar:CreateButton(
		"egomoose_photobooth_viewer",
		"View photobooth images",
		`rbxasset://studio_svg_textures/Shared/InsertableObjects/{theme.Name}/Standard/ImageLabel@3x.png`,
		"Viewer"
	)
	UserInterface.mountOpenGalleryButton(plugin, openViewerButton)

	-- local importPngButton = toolbar:CreateButton(
	-- 	"egomoose_photobooth_importer",
	-- 	"Import Png",
	-- 	`rbxasset://studio_svg_textures/Lua/AssetManager/{theme.Name}/Standard/Import@3x.png`,
	-- 	"Import"
	-- )
	-- UserInterface.mountImportPngButton(plugin, importPngButton)

	Bindings.setup(plugin)
end

return Plugin
