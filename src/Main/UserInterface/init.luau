--!strict

local CoreGui = game:GetService("CoreGui") :: CoreGui
local StarterGui = game:GetService("StarterGui") :: StarterGui
local HttpService = game:GetService("HttpService") :: HttpService
local SelectionService = game:GetService("Selection") :: Selection
local AssetService = game:GetService("AssetService") :: AssetService
local ScriptEditorService = game:GetService("ScriptEditorService") :: ScriptEditorService

local pluginRoot = script:FindFirstAncestor("PluginRoot")

local StudioComponents = require(pluginRoot.Packages.StudioComponents)
local ReactRoblox = require(pluginRoot.Packages.ReactRoblox)
local React = require(pluginRoot.Packages.React)
local Trove = require(pluginRoot.Packages.Trove)

local Constants = require(pluginRoot.Constants)
local Wally = require(pluginRoot.Wally)

local State = require(pluginRoot.Main.State)
local Photo = require(pluginRoot.Main.Photo)

local RenderRect = require(pluginRoot.Main.Bindings.Interface.Helpers.RenderRect)
local Captures = require(pluginRoot.Main.Photo.Captures)
local UIHider = require(pluginRoot.Main.Photo.Tools.UIHider)

local Hooks = require(script.Hooks)
local Icons = require(script.Icons)

local Gallery = require(script.Components.Gallery)
local FullViewport = require(script.Components.FullViewport)
local CroppedViewport = require(script.Components.CroppedViewport2)

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
		if selection and not State.read().temporary.isCapturing then
			local captureTypeIndex = State.read().temporary.uiCaptureTypeIndex
			local captureType = assert(Captures.UserInterface.Order[captureTypeIndex], "No capture type found")

			local captures = Photo.captureUI({
				subject = selection,
				type = captureType :: Captures.UICaptureTypes,
			})

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

	local function onThemeChanged()
		openButton.Icon = getIcon("camera-plugin-button")
	end

	onThemeChanged()
	settings().Studio.ThemeChanged:Connect(onThemeChanged)

	local folder = Instance.new("Folder")
	folder.Name = "EgoMoosePhotobooth"
	folder.Archivable = false
	folder.Parent = CoreGui

	local function ViewportApp(): React.ReactNode?
		local isEnabled, setIsEnabled = React.useState(false)

		local isCapturing = Hooks.useStatePath(function(state)
			return state.temporary.isCapturing
		end)

		local isFullscreen = Hooks.useStatePath(function(state)
			return state.temporary.isFullscreen
		end)

		local captureRectRef = React.useRef(RenderRect.fromViewportCenter(workspace.CurrentCamera.ViewportSize / 2))
		local prevCaptureRectRef = React.useRef(captureRectRef.current)

		local screenGuiRef = React.useRef(nil :: ScreenGui?)

		local updatePrevCaptureRectRef = React.useCallback(function()
			local captureRect = captureRectRef.current
			if not State.read().temporary.isFullscreen and captureRect then
				prevCaptureRectRef.current = captureRect
			end
		end, {})

		React.useEffect(function()
			local trove = Trove.new()
			trove:Add(openButton.Click:Connect(function()
				updatePrevCaptureRectRef()
				setIsEnabled(not isEnabled)
			end))

			return function()
				trove:Destroy()
			end
		end, { isEnabled })

		local onCapture = React.useCallback(function(rect: Rect)
			local captureTypeIndex = State.read().temporary.viewportCaptureTypeIndex
			local captureType = assert(Captures.Viewport.Order[captureTypeIndex], "No capture type found")

			local trove = Trove.new()
			if screenGuiRef.current and UIHider.isViewportAppExcluded(rect) then
				trove:Add(UIHider.addExclusion(screenGuiRef.current))
			end

			local captures, err = Photo.captureViewport({
				rect = rect,
				type = captureType :: Captures.ViewportCaptureTypes,
			})

			trove:Destroy()

			local selection = Photo.export(captures, StarterGui)
			SelectionService:Set(selection :: any)
			return not err, err
		end, {})

		local onMinMax = React.useCallback(function()
			local prevRect = prevCaptureRectRef.current
			updatePrevCaptureRectRef()
			captureRectRef.current = prevRect
			State.mutate(function(state)
				state.temporary.isFullscreen = not state.temporary.isFullscreen
			end)
		end, {})

		openButton:SetActive(isEnabled)

		-- stylua: ignore
		return isEnabled and React.createElement("ScreenGui", {
			Name = "ViewportApp",
			Archivable = false,
			IgnoreGuiInset = true,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			ref = screenGuiRef,
		}, {
			Fullscreen = isFullscreen and React.createElement(FullViewport, {
				CaptureRectRef = captureRectRef,
				OnMinimize = onMinMax,
				OnCapture = onCapture,
				Disabled = isCapturing,
			}),

			Cropped = not isFullscreen and React.createElement(CroppedViewport, {
				CaptureRectRef = captureRectRef,
				OnMaximize = onMinMax,
				OnCapture = onCapture,
				Disabled = isCapturing,
			}),
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
		Constants.DockWidgetSize.X, -- Default width of the floating window
		Constants.DockWidgetSize.Y, -- Default height of the floating window
		Constants.DockWidgetSize.X, -- Minimum width of the floating window
		Constants.DockWidgetSize.Y -- Minimum height of the floating window
	)

	local dock = plugin:CreateDockWidgetPluginGuiAsync("PhotoboothGallery", info)
	dock.Name = "PhotoboothGallery"
	dock.Title = "Photobooth"
	dock.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local function GalleryApp(): React.ReactNode
		local isEnabled, setIsEnabled = React.useState(dock.Enabled)

		local isCapturing = Hooks.useStatePath(function(state)
			return state.temporary.isCapturing
		end)

		local galleryListExpanded = Hooks.useStatePath(function(state)
			return state.saved.galleryListExpanded
		end)

		local backgroundType, setBackgroundType = React.useState("Checkerboard")

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

		return isEnabled
			and React.createElement(Gallery, {
				IsExpanded = galleryListExpanded,
				SetIsExpanded = function()
					State.mutate(function(state)
						state.saved.galleryListExpanded = not state.saved.galleryListExpanded
					end)
				end,

				BackgroundType = backgroundType,
				SetBackgroundType = setBackgroundType,

				TryUpload = function(_i, name, editImage)
					local result: Enum.CreateAssetResult
					local value: number | string

					result, value = AssetService:CreateAssetAsync(editImage, Enum.AssetType.Image, {
						Name = name,
						Description = table.concat({
							"Uploaded with the Photobooth plugin.",
							"",
							HttpService:JSONEncode({
								Dimensions = { editImage.Size.X, editImage.Size.Y },
								Version = Wally.package.version,
							}),
						}, "\n"),
					})

					if result == Enum.CreateAssetResult.Success then
						return value :: number
					end

					warn(value :: string)
					return nil
				end,
				OnUploadComplete = function(completed)
					local module = Instance.new("ModuleScript")
					module.Name = `{DateTime.now():ToIsoDate()} - Photobooth Upload`
					ScriptEditorService:UpdateSourceAsync(module, function()
						local output = "return {\n"
						for _, entry in completed do
							output = output .. `\t["{entry.Name}"] = "rbxassetid://{entry.AssetId}",\n`
						end
						return output .. "}"
					end)
					module.Parent = StarterGui

					ScriptEditorService:OpenScriptDocumentAsync(module)
					SelectionService:Set({ module })
				end,

				OnImport = function()
					local result = Photo.importFiles(StarterGui)
					SelectionService:Set(result :: { any })
				end,

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

return UserInterface
