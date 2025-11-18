--!strict

local StudioService = game:GetService("StudioService") :: StudioService
local AssetService = game:GetService("AssetService") :: AssetService

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Image = require(pluginRoot.Utilities.Image)
local Trove = require(pluginRoot.Packages.Trove)
local Sift = require(pluginRoot.Packages.Sift)

local Types = require(pluginRoot.Main.Bindings.Interface.Types)
local State = require(pluginRoot.Main.State)

local SceneControl = require(script.SceneControl)
local Captures = require(script.Captures)

local Photo = {}

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

-- Public

function Photo.captureUI(options: Types.CaptureUIOptions)
	options = Sift.Dictionary.merge({
		alphaBleed = State.read().saved.alphaBleedingEnabled,
		delay = 0,
	}, options)

	local processor = Captures.UserInterface.Processors[options.type]

	local results: { Image.Image }
	local trove = createIsCapturingTrove()
	local success, err = SceneControl.freeze(false, function()
		if options.delay and options.delay > 0 then
			task.wait(options.delay)
		end
		results = processor(options, trove)
	end)

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

function Photo.captureViewport(options: Types.CaptureViewportOptions)
	options = Sift.Dictionary.merge({
		alphaBleed = State.read().saved.alphaBleedingEnabled,
		delay = 0,
	}, options)

	local processor = Captures.Viewport.Processors[options.type]

	local results: { Image.Image }
	local trove = createIsCapturingTrove()
	local success, err = SceneControl.freeze(true, function()
		if options.delay and options.delay > 0 then
			task.wait(options.delay)
		end
		results = processor(options, trove)
	end)

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
