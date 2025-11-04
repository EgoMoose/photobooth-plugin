--!strict

local CoreGui = game:GetService("CoreGui") :: CoreGui
local AssetService = game:GetService("AssetService") :: AssetService
local StudioService = game:GetService("StudioService") :: StudioService

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Image = require(pluginRoot.Utilities.Image)
local Trove = require(pluginRoot.Packages.Trove)

local State = require(pluginRoot.Main.State)

local Screenshot = require(script.Captures.Screenshot)
local SceneControl = require(script.SceneControl)
local Captures = require(script.Captures)

local Background = require(script.Tools.Background)
local UIBounds = require(script.Tools.UIBounds)
local UIHider = require(script.Tools.UIHider)

local Photo = {}
local viewportApp: LayerCollector?

-- Private

local function createIsCapturingTrove()
	assert(not State.read().temporary.isCapturing, "A capture is already in progress.")

	State.mutate(function(state)
		state.temporary.isCapturing = true
	end)

	local trove = Trove.new()
	trove:Add(function()
		State.mutate(function(state)
			state.temporary.isCapturing = false
		end)
	end)

	return trove
end

local function captureUI(
	subject: GuiObject,
	processor: (UIBounds.UIBounds, Trove.Trove) -> { Image.Image },
	captureDelay: number
)
	local results: { Image.Image }
	local trove = createIsCapturingTrove()

	local uiBounds = UIBounds.new(CoreGui, subject, State.read().temporary.scaleOS)
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
			if captureDelay > 0 then
				task.wait(captureDelay)
			end
			results = processor(uiBounds, trove)
		end,
	})

	trove:Destroy()

	if not success then
		if err then
			if err:sub(1, 4) == "WARN" then
				err = err:sub(7)
				warn(err)
			else
				task.spawn(error, err)
			end
		end
		results = {}
	end

	return results, err
end

local function captureViewport(rect: Rect, processor: (Rect, Background.Background, Trove.Trove) -> { Image.Image })
	local results: { Image.Image }
	local trove = createIsCapturingTrove()

	local exclusions = {}
	if
		viewportApp
		and not Screenshot.isFullscreenRect(rect)
		and Screenshot.isUnitScaleOS(State.read().temporary.scaleOS)
	then
		table.insert(exclusions, viewportApp)
	end

	local uiHider = UIHider.new(exclusions, function(layerCollector)
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
		if err then
			if err:sub(1, 4) == "WARN" then
				err = err:sub(7)
				warn(err)
			else
				task.spawn(error, err)
			end
		end
		results = {}
	end

	return results, err
end

-- Public

function Photo.setViewportApp(app: LayerCollector?)
	viewportApp = app
end

function Photo.captureUI(subject: GuiObject, captureType: Captures.UICaptureTypes, captureDelay: number?)
	return captureUI(subject, Captures.UserInterface.Processors[captureType], captureDelay or 0)
end

function Photo.captureViewport(rect: Rect, captureType: Captures.ViewportCaptureTypes)
	return captureViewport(rect, Captures.Viewport.Processors[captureType])
end

function Photo.export(imgs: { Image.Image }, parent: Instance?)
	local results = {}

	for i, img in imgs do
		local name = `{DateTime.now():ToIsoDate()}_{i}`
		local meshPart = Instance.new("MeshPart")
		meshPart.Locked = true
		meshPart.Archivable = false
		meshPart.Anchored = true
		meshPart.CanCollide = false
		meshPart.CanTouch = false
		meshPart.Transparency = 0 -- cannot be transparent
		meshPart.Name = name
		meshPart.Size = Vector3.new(1, 1, 1)
		meshPart.TextureContent = Content.fromObject(img:Save())
		meshPart.Parent = parent

		table.insert(results, meshPart)
	end
	return results
end

function Photo.importFiles(parent: Instance?)
	local results = {}

	local files = (StudioService:PromptImportFiles({ "png" }) :: any) :: { File }
	for _, file in files do
		local content = Content.fromUri(file:GetTemporaryId())
		local editImage = AssetService:CreateEditableImageAsync(content)

		local meshPart = Instance.new("MeshPart")
		meshPart.Locked = true
		meshPart.Archivable = false
		meshPart.Anchored = true
		meshPart.CanCollide = false
		meshPart.CanTouch = false
		meshPart.Transparency = 0 -- cannot be transparent
		meshPart.Name = file.Name:match("(.+)%.[^.]*$") or file.Name
		meshPart.Size = Vector3.new(1, 1, 1)
		meshPart.TextureContent = Content.fromObject(editImage)
		meshPart.Parent = parent

		table.insert(results, meshPart)
	end

	return results
end

--

return Photo
