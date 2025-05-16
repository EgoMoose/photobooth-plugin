--!strict

local CoreGui = game:GetService("CoreGui") :: CoreGui
local StarterGui = game:GetService("StarterGui") :: StarterGui
local SelectionService = game:GetService("Selection") :: Selection
local AssetService = game:GetService("AssetService") :: AssetService
local StudioService = game:GetService("StudioService") :: StudioService

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local StudioComponents = require(pluginRoot.Packages.StudioComponents)
local ReactRoblox = require(pluginRoot.Packages.ReactRoblox)
local React = require(pluginRoot.Packages.React)
local Trove = require(pluginRoot.Packages.Trove)

local Constants = require(pluginRoot.Constants)

local Camera = require(pluginRoot.Utilities.Camera)
local Image = require(pluginRoot.Utilities.Image)
local Photo = require(pluginRoot.Main.Photo)

local Hooks = require(script.Hooks)
local Icons = require(script.Icons)

local Gallery = require(script.Components.Gallery)
local FullViewport = require(script.Components.FullViewport)
local CroppedViewport = require(script.Components.CroppedViewport)

local UserInterface = {}

-- Private

local function getIcon(iconName: string)
	local theme = settings().Studio.Theme
	return assert(Icons["processed"][theme.Name:lower()][iconName] :: string?)
end

-- Public

function UserInterface.mountCaptureUI(plugin: Plugin, toolbar: PluginToolbar)
	-- stylua: ignore
	local captureButton = toolbar:CreateButton(
		"egomoose_photobooth_capture_ui_button",
		"Capture UI images",
		"", "UI"
	)

	local function onThemeChanged()
		captureButton.Icon = getIcon("ui-plugin-button")
	end

	onThemeChanged()
	settings().Studio.ThemeChanged:Connect(onThemeChanged)

	local function getSelectedGuiObject()
		local selection = SelectionService:Get()
		local singleSelection = if #selection == 1 then selection[1] else nil
		return if singleSelection and singleSelection:IsA("GuiObject") then singleSelection else nil
	end

	local selection: GuiObject?
	local function refreshSelection()
		selection = getSelectedGuiObject()
		captureButton.Enabled = not not selection
	end

	refreshSelection()
	local selectionChangedConnection = SelectionService.SelectionChanged:Connect(function()
		refreshSelection()
	end)

	local clickConnection = captureButton.Click:Connect(function()
		if selection and not Photo.Flags.get("isCapturing") then
			local captures = Photo.captureUI(selection, Photo.Configuration.get().UserInterfaceCaptureType)
			local exported = Photo.export(captures, StarterGui)
			SelectionService:Set(exported :: any)
		end
	end)

	plugin.Unloading:Connect(function()
		selectionChangedConnection:Disconnect()
		clickConnection:Disconnect()
	end)
end

function UserInterface.mountCaptureViewport(plugin: Plugin, toolbar: PluginToolbar)
	-- stylua: ignore
	local openButton = toolbar:CreateButton(
		"egomoose_photobooth_viewport_button", 
		"Capture viewport images", 
		"", "Viewport"
	)

	local focusAction: PluginAction
	local actionTrove = Trove.new()

	local function onThemeChanged()
		openButton.Icon = getIcon("camera-plugin-button")
		actionTrove:Clean()

		focusAction = actionTrove:Add(
			plugin:CreatePluginAction(
				"egomoose_photobooth_focus_action",
				"Photobooth Viewport Focus",
				"Focuses the camera to fit the selected PVInstance to the Photobooth capture viewport.",
				getIcon("focus-plugin-action"),
				true
			)
		)
	end

	onThemeChanged()
	settings().Studio.ThemeChanged:Connect(onThemeChanged)

	local folder = Instance.new("Folder")
	folder.Name = "EgoMoosePhotobooth"
	folder.Archivable = false
	folder.Parent = CoreGui

	local function ViewportApp(): React.ReactNode?
		local isEnabled, setIsEnabled = React.useState(false)
		local isCapturing = Hooks.usePhotoFlag("isCapturing")
		local configuration = Hooks.usePhotoConfiguration()
		local focusLenseSizeRef = React.useRef(nil :: Vector2?)
		local screenGuiRef = React.useRef(nil :: ScreenGui?)

		openButton:SetActive(isEnabled)

		React.useEffect(function()
			Photo.setViewportApp(screenGuiRef.current)
		end, { isEnabled })

		React.useEffect(function()
			local trove = Trove.new()
			trove:Add(openButton.Click:Connect(function()
				setIsEnabled(not isEnabled)
			end))

			return function()
				trove:Destroy()
			end
		end)

		React.useEffect(function()
			local connection = focusAction.Triggered:Connect(function()
				if isEnabled then
					local focusLenseSize = focusLenseSizeRef.current
					if focusLenseSize then
						Camera.focus(workspace.CurrentCamera, SelectionService:Get(), focusLenseSize)
					end
				end
			end)

			return function()
				connection:Disconnect()
			end
		end, { isEnabled })

		-- stylua: ignore
		return isEnabled and React.createElement("ScreenGui", {
			Name = "ViewportApp",
			Archivable = false,
			IgnoreGuiInset = true,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			ref = screenGuiRef,
		}, {
			Content = React.createElement(if configuration.IsFullscreen then FullViewport else CroppedViewport, {
				OnCapture = function(rect)
					local captures = Photo.captureViewport(rect, Photo.Configuration.get().ViewportCaptureType)
					local selection = Photo.export(captures, StarterGui)
					SelectionService:Set(selection :: any)
				end,
				FocusLenseSizeRef = focusLenseSizeRef,
				Disabled = isCapturing,
			})
		})
	end

	local coreGuiRoot = ReactRoblox.createRoot(folder)
	coreGuiRoot:render(React.createElement(StudioComponents.PluginProvider, {
		Plugin = plugin,
	}, {
		App = React.createElement(ViewportApp),
	}))

	plugin.Unloading:Connect(function()
		coreGuiRoot:unmount()
		actionTrove:Destroy()
		folder:Destroy()
	end)
end

function UserInterface.mountGallery(plugin: Plugin, toolbar: PluginToolbar)
	-- stylua: ignore
	local openButton = toolbar:CreateButton(
		"egomoose_photobooth_gallery_button",
		"View photobooth images",
		"", "Gallery"
	)

	local function onThemeChanged()
		openButton.Icon = getIcon("gallery-plugin-button")
	end

	onThemeChanged()
	settings().Studio.ThemeChanged:Connect(onThemeChanged)

	local info = DockWidgetPluginGuiInfo.new(
		Enum.InitialDockState.Float, -- Widget will be initialized in floating panel
		false, -- Widget will be initially enabled
		false, -- Don't override the previous enabled state
		Constants.DockWidgetSize[1], -- Default width of the floating window
		Constants.DockWidgetSize[2], -- Default height of the floating window
		Constants.DockWidgetSize[1], -- Minimum width of the floating window
		Constants.DockWidgetSize[2] -- Minimum height of the floating window
	)

	local dock = plugin:CreateDockWidgetPluginGui("PhotoboothViewer", info)
	dock.Title = "Photobooth"
	dock.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local function GalleryApp(): React.ReactNode
		local backgroundType, setBackgroundType = React.useState("Checkerboard")
		local isEnabled, setIsEnabled = React.useState(dock.Enabled)
		local isCapturing = Hooks.usePhotoFlag("isCapturing")

		React.useEffect(function()
			local buttonConnection = openButton.Click:Connect(function()
				setIsEnabled(not dock.Enabled)
			end)

			dock:BindToClose(function()
				setIsEnabled(false)
			end)

			return function()
				dock:BindToClose(nil)
				buttonConnection:Disconnect()
			end
		end, {})

		dock.Enabled = isEnabled
		openButton:SetActive(isEnabled)

		-- stylua: ignore
		return isEnabled and React.createElement(Gallery, {
			UploadCallback = function(details)
				local result: Enum.CreateAssetResult
				local value: number | string

				result, value = AssetService:CreateAssetAsync(details.EditableImage, Enum.AssetType.Image, {
					Name = details.Title,
					Description = details.Description,
					IsPackage = false,
				})

				return result == Enum.CreateAssetResult.Success, value
			end,

			BackgroundType = backgroundType,
			SetBackgroundType = setBackgroundType,

			Disabled = isCapturing,
		})
	end

	local dockRoot = ReactRoblox.createRoot(dock)
	dockRoot:render(React.createElement(StudioComponents.PluginProvider, {
		Plugin = plugin,
	}, {
		App = React.createElement(GalleryApp),
	}))

	plugin.Unloading:Connect(function()
		dockRoot:unmount()
	end)
end

function UserInterface.mountServePng(plugin: Plugin, toolbar: PluginToolbar)
	if not Constants.ServeEnabled then
		return
	end

	-- stylua: ignore
	local serveButton = toolbar:CreateButton(
		"egomoose_photobooth_serve_button",
		"Send selected editable images to the photobooth localhost",
		"", "Serve"
	)

	local function onThemeChanged()
		serveButton.Icon = getIcon("serve-png-button")
	end

	onThemeChanged()
	settings().Studio.ThemeChanged:Connect(onThemeChanged)

	local classToContentProperty: { [string]: string } = {
		["MeshPart"] = "TextureContent",
	}

	local function tryGetEditImage(instance: Instance): EditableImage?
		for className, contentProperty in classToContentProperty do
			if instance:IsA(className) then
				local content = (instance :: any)[contentProperty] :: Content
				local object = content and content.Object

				if object and object:IsA("EditableImage") then
					return object
				end
			end
		end
		return nil
	end

	local clickConnection = serveButton.Click:Connect(function()
		serveButton.Enabled = false

		local gathered = {}
		for _, selected in SelectionService:Get() do
			local editImage = tryGetEditImage(selected)
			if editImage then
				table.insert(gathered, {
					name = selected.Name:gsub("[^a-z0-9%- ]+", "_"),
					img = Image.fromEditableImage(editImage),
				})
			end
		end

		local successCount = Photo.serve(Constants.ServePort, gathered)
		if successCount >= 0 then
			print(`Successfully sent {successCount} images.`)
		end

		serveButton:SetActive(false)
		serveButton.Enabled = true
	end)

	plugin.Unloading:Connect(function()
		clickConnection:Disconnect()
	end)
end

function UserInterface.mountImportPng(plugin: Plugin, toolbar: PluginToolbar)
	-- stylua: ignore
	local importButton = toolbar:CreateButton(
		"egomoose_photobooth_import_button",
		"Import Png",
		"", "Import"
	)

	local function onThemeChanged()
		importButton.Icon = getIcon("import-plugin-button")
	end

	onThemeChanged()
	settings().Studio.ThemeChanged:Connect(onThemeChanged)

	local clickConnection = importButton.Click:Connect(function()
		importButton:SetActive(false)

		-- only png is supported by Roblox currently
		local files = (StudioService:PromptImportFiles({ "png" }) :: any) :: { File }
		for _, file in files do
			local content = Content.fromUri(file:GetTemporaryId())
			local editImage = AssetService:CreateEditableImageAsync(content)
			local img = Image.fromEditableImage(editImage)

			local selection = Photo.export({ img }, StarterGui)
			SelectionService:Set(selection :: any)
		end
	end)

	plugin.Unloading:Connect(function()
		clickConnection:Disconnect()
	end)
end

return UserInterface
