--!strict

local ServerStorage = game:GetService("ServerStorage") :: ServerStorage

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Trove = require(pluginRoot.Packages.Trove)
local gt = require(pluginRoot.Packages.GreenTea)

local SceneControl = require(pluginRoot.Main.Photo.SceneControl)
local Captures = require(pluginRoot.Main.Photo.Captures)
local Camera = require(pluginRoot.Utilities.Camera)
local Photo = require(pluginRoot.Main.Photo)

local BindingExporter = require(script.BindingExporter)
local Templates = require(script.Templates)

local Bindings = {}
local trove = Trove.new()

-- Private

local function getOSScale()
	return Photo.Configuration.get().ScaleOS
end

local function captureViewport(rect: Rect, captureType: Captures.ViewportCaptureTypes)
	local scaleOS = Photo.Configuration.get().ScaleOS

	local camera = workspace.CurrentCamera
	local viewportSize = camera.ViewportSize
	local corner = ((viewportSize * scaleOS) - viewportSize) / 2

	-- stylua: ignore
	local scaledRect = Rect.new(
		(rect.Min + corner):Ceil(),
		(rect.Max + corner):Ceil()
	)

	local prevCameraCF = camera.CFrame
	local prevCameraType = camera.CameraType
	if not (scaleOS.X == 1 and scaleOS.Y == 1) then
		camera.CameraType = Enum.CameraType.Scriptable

		-- stylua: ignore
		camera.CFrame = prevCameraCF * Camera.distort(camera, {
			anchor = Vector2.new(0.5, 0.5),
			position = Vector2.new(0.5, 0.5),
			size = 1 / scaleOS,
			zoom = 1,
			nearZ = 0,
			rotation = 0,
		})

		SceneControl.yieldUntilNextFrame()
	end

	local exported = {}
	local success, err = pcall(function()
		local result = Photo.captureViewport(scaledRect, captureType)
		exported = Photo.export(result, nil)
	end)

	if not success then
		warn(err)
	end

	camera.CFrame = prevCameraCF
	camera.CameraType = prevCameraType

	return exported[1]
end

local function captureUI(subject: GuiObject, captureType: Captures.UICaptureTypes)
	local exported = {}
	local success, err = pcall(function()
		local result = Photo.captureUI(subject, captureType)
		exported = Photo.export(result, nil)
	end)

	if not success then
		warn(err)
	end

	return exported[1]
end

local function gtUnion(literals: { any })
	local gtTypes = {}
	for i, value in literals do
		gtTypes[i] = gt.literal(value)
	end
	return gt.union(unpack(gtTypes))
end

local function createBindings()
	local exportableBinding = BindingExporter.new()

	local headerLines = {
		`export type ViewportCaptureTypes = "{table.concat(Captures.Viewport.Order, '" | "')}"`,
		`export type UICaptureTypes = "{table.concat(Captures.UserInterface.Order, '" | "')}"`,
	}

	local helperImports = {}
	for _, child in script.Helpers:GetChildren() do
		local name = child.Name
		local camelCase = name:sub(1, 1):lower() .. name:sub(2)
		local line = `Bindings.{camelCase} = require(script.Helpers.{name})`
		table.insert(helperImports, line)
	end

	if #helperImports > 0 then
		table.insert(headerLines, `\n{table.concat(helperImports, "\n")}`)
	end

	exportableBinding:SetHeader(headerLines)

	exportableBinding:Add({
		parameters = {},
		returnTypes = { "Vector2" },
		-- stylua: ignore
		typechecker = gt.fn(
			gt.args(),
			gt.returns(gt.Vector2())
		),
	}, getOSScale)

	exportableBinding:Add({
		parameters = { "rect: Rect", "captureType: ViewportCaptureTypes" },
		returnTypes = { "MeshPart" },
		-- stylua: ignore
		typechecker = gt.fn(
			gt.args(gt.Rect(), gtUnion(Captures.Viewport.Order)),
			gt.returns(gt.isA.MeshPart())
		),
	}, captureViewport)

	exportableBinding:Add({
		parameters = { "subject: GuiObject", "captureType: UICaptureTypes" },
		returnTypes = { "MeshPart" },
		-- stylua: ignore
		typechecker = gt.fn(
			gt.args(gt.isA("GuiObject"), gtUnion(Captures.UserInterface.Order)),
			gt.returns(gt.isA.MeshPart())
		),
	}, captureUI)

	exportableBinding:Add({
		parameters = {},
		returnTypes = {},
		typechecker = gt.fn(gt.args(), gt.returns()),
	}, SceneControl.yieldUntilNextFrame)

	local interface = exportableBinding:Create()
	interface.Name = "PhotoboothBindings"
	interface.Archivable = false
	trove:Add(interface)

	local helpers = script.Helpers:Clone()
	helpers.Parent = interface

	local templates = Templates.create()
	templates.Parent = interface

	for _, descendant in interface:GetDescendants() do
		descendant.Archivable = false
		trove:Add(descendant)
	end

	return interface
end

local isEnabled = false
local function setEnabled(enabled: boolean)
	if isEnabled ~= enabled then
		isEnabled = enabled
		trove:Clean()

		if isEnabled then
			local interface = createBindings()
			interface.Parent = ServerStorage
		end
	end
end

-- Public

function Bindings.setup(plugin: Plugin)
	setEnabled(Photo.Configuration.get().BindingsEnabled)
	local disconnect = Photo.Configuration.onChanged(function()
		setEnabled(Photo.Configuration.get().BindingsEnabled)
	end)

	plugin.Unloading:Connect(function()
		disconnect()
		setEnabled(false)
	end)
end

--

return Bindings
