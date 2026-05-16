local StudioService = game:GetService("StudioService") :: StudioService
local AssetService = game:GetService("AssetService") :: AssetService

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Future = require(pluginRoot.Packages.Future)
local Trove = require(pluginRoot.Packages.Trove)
local Sift = require(pluginRoot.Packages.Sift)

local Timeout = require(pluginRoot.Utilities.Timeout)
local Image = require(pluginRoot.Utilities.Image)

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

	Timeout.tryYield(true)
	return trove
end

local quadFuture: Future.Future<MeshPart>
local function getQuadMeshPart()
	if not quadFuture then
		local editMesh = AssetService:CreateEditableMesh({ FixedSize = false })

		local v0 = editMesh:AddVertex(Vector3.new(-0.5, 0.5, 0))
		local v1 = editMesh:AddVertex(Vector3.new(0.5, 0.5, 0))
		local v2 = editMesh:AddVertex(Vector3.new(0.5, -0.5, 0))
		local v3 = editMesh:AddVertex(Vector3.new(-0.5, -0.5, 0))

		local n0 = editMesh:AddNormal(Vector3.new(0, 0, -1))
		local n1 = editMesh:AddNormal(Vector3.new(0, 0, -1))
		local n2 = editMesh:AddNormal(Vector3.new(0, 0, -1))
		local n3 = editMesh:AddNormal(Vector3.new(0, 0, -1))

		local uv0 = editMesh:AddUV(Vector2.new(0, 0))
		local uv1 = editMesh:AddUV(Vector2.new(1, 0))
		local uv2 = editMesh:AddUV(Vector2.new(1, 1))
		local uv3 = editMesh:AddUV(Vector2.new(0, 1))

		local f0 = editMesh:AddTriangle(v0, v1, v2)
		local f1 = editMesh:AddTriangle(v0, v2, v3)

		editMesh:SetFaceNormals(f0, { n0, n1, n2 })
		editMesh:SetFaceUVs(f0, { uv0, uv1, uv2 })
		editMesh:SetFaceNormals(f1, { n0, n2, n3 })
		editMesh:SetFaceUVs(f1, { uv0, uv2, uv3 })

		local fixedMesh = AssetService:CreateEditableMeshAsync(Content.fromObject(editMesh), { FixedSize = true })
		editMesh:Destroy()

		local meshPart = AssetService:CreateMeshPartAsync(Content.fromObject(fixedMesh))
		quadFuture = Future.completed(meshPart)
	end

	return quadFuture:expect()
end

-- Public

function Photo.captureUI(options: Types.CaptureUIOptions)
	options = Sift.Dictionary.merge({
		delay = 0,
		alphaBleed = State.read().saved.alphaBleedingEnabled,
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
		delay = 0,
		alphaBleed = State.read().saved.alphaBleedingEnabled,
	}, options)

	local processor = Captures.Viewport.Processors[options.type]

	if options.delay and options.delay > 0 then
		task.wait(options.delay)
	end

	local results: { Image.Image }
	local trove = createIsCapturingTrove()
	local success, err = SceneControl.freeze(true, function()
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
		local meshPart = getQuadMeshPart():Clone()
		meshPart.Archivable = false
		meshPart.Anchored = true
		meshPart.CanCollide = false
		meshPart.CanTouch = false
		meshPart.Transparency = 0 -- cannot be transparent
		meshPart.Name = name
		meshPart.Size = Vector3.new(1, 1, 0)
		meshPart.TextureContent = Content.fromObject(img:Save())
		meshPart.Parent = parent

		table.insert(results, meshPart)
	end
	return results
end

function Photo.importFiles(parent: Instance?)
	local results = {}

	local files = (StudioService:PromptImportFilesAsync({ "png" }) :: any) :: { File }
	for _, file in files do
		local content = Content.fromUri(file:GetTemporaryId())
		local editImage = AssetService:CreateEditableImageAsync(content)

		local meshPart = getQuadMeshPart():Clone()
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
