--!strict

local CoreGui = game:GetService("CoreGui") :: CoreGui

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Image = require(pluginRoot.Utilities.Image)
local Trove = require(pluginRoot.Packages.Trove)

local Configuration = require(script.Configuration)
local Flags = require(script.Flags)

local SceneControl = require(script.SceneControl)
local Captures = require(script.Captures)

local Background = require(script.Tools.Background)
local UIBounds = require(script.Tools.UIBounds)
local UIHider = require(script.Tools.UIHider)

export type Configuration = Configuration.Configuration

local Photo = {}

-- Private

local function createIsCapturingTrove()
	assert(not Flags.get("isCapturing"), "A capture is already in progress.")

	Flags.set("isCapturing", true)
	local trove = Trove.new()
	trove:Add(function()
		Flags.set("isCapturing", false)
	end)

	return trove
end

local function captureUI(subject: GuiObject, processor: (UIBounds.UIBounds, Trove.Trove) -> { Image.Image })
	local results: { Image.Image }
	local trove = createIsCapturingTrove()

	local uiBounds = UIBounds.new(CoreGui, subject, Configuration.get().ScaleOS)
	local uiHider = UIHider.new({ uiBounds.surfaceGui })

	trove:Add(function()
		uiBounds:Destroy()
		uiHider:Destroy()
	end)

	local success, err = SceneControl.apply({
		hideMouse = true,

		freezeCamera = true,
		freezeEmitters = false,

		callback = function()
			results = processor(uiBounds, trove)
		end,
	})

	trove:Destroy()

	if not success then
		error(err, 2)
	end

	return results
end

local function captureViewport(rect: Rect, processor: (Rect, Background.Background, Trove.Trove) -> { Image.Image })
	local results: { Image.Image }
	local trove = createIsCapturingTrove()

	local hide = {}
	local _success = pcall(function()
		local folder = CoreGui:FindFirstChild("EgoMoosePhotobooth")
		local app = folder and folder:FindFirstChild("ViewportApp")
		if app and app:IsA("LayerCollector") then
			table.insert(hide, app)
		end
	end)

	local uiHider = UIHider.new(hide, function(layerCollector)
		return layerCollector:IsA("ScreenGui")
	end)

	trove:Add(function()
		uiHider:Destroy()
	end)

	local success, err = SceneControl.apply({
		hideMouse = true,

		freezeCamera = true,
		freezeEmitters = true,

		callback = function()
			local background = Background.new(workspace)
			trove:Add(function()
				background:Destroy()
			end)

			results = processor(rect, background, trove)
		end,
	})

	trove:Destroy()

	if not success then
		error(err, 2)
	end

	return results
end

-- Public

Photo.Flags = Flags
Photo.Configuration = Configuration

function Photo.captureUI(subject: GuiObject, captureType: Captures.UICaptureTypes)
	return captureUI(subject, Captures.UserInterface.Processors[captureType])
end

function Photo.captureViewport(rect: Rect, captureType: Captures.ViewportCaptureTypes)
	return captureViewport(rect, Captures.Viewport.Processors[captureType])
end

function Photo.export(imgs: { Image.Image }, parent: Instance?)
	local results = {}
	for i, img in imgs do
		local meshPart = Instance.new("MeshPart")
		meshPart.Locked = true
		meshPart.Archivable = false
		meshPart.Anchored = true
		meshPart.CanCollide = false
		meshPart.CanTouch = false
		meshPart.Transparency = 0 -- cannot be transparent
		meshPart.Name = `{DateTime.now():ToIsoDate()}_{i}`
		meshPart.Size = Vector3.new(1, 1, 1)
		meshPart.TextureContent = Content.fromObject(img:Save())
		meshPart.Parent = parent

		table.insert(results, meshPart)
	end
	return results
end

--

return Photo
