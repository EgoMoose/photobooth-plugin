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

local Camera = require(pluginRoot.Utilities.Camera)
local Image = require(pluginRoot.Utilities.Image)
local Photo = require(pluginRoot.Main.Photo)

local Hooks = require(script.Hooks)
local Constants = require(script.Constants)

local Gallery = require(script.Components.Gallery)
local Viewport = require(script.Components.Viewport)

local UserInterface = {}

-- Public

function UserInterface.mountCaptureUIButton(plugin: Plugin, button: PluginToolbarButton)
	local function getSelectedGuiObject()
		local selection = SelectionService:Get()
		local singleSelection = if #selection == 1 then selection[1] else nil
		return if singleSelection and singleSelection:IsA("GuiObject") then singleSelection else nil
	end

	local selection: GuiObject?
	local function refreshSelection()
		selection = getSelectedGuiObject()
		button.Enabled = not not selection
	end

	refreshSelection()
	local selectionChangedConnection = SelectionService.SelectionChanged:Connect(function()
		refreshSelection()
	end)

	local clickConnection = button.Click:Connect(function()
		if selection and not Photo.Flags.get("isCapturing") then
			local captures = Photo.captureUI(selection, Photo.Configuration.get().UserInterfaceCaptureType)
			local selection = Photo.export(captures, StarterGui)
			SelectionService:Set(selection :: any)
		end
	end)

	plugin.Unloading:Connect(function()
		selectionChangedConnection:Disconnect()
		clickConnection:Disconnect()
	end)
end

function UserInterface.mountOpenViewportButton(plugin: Plugin, button: PluginToolbarButton)
	local focusAction = plugin:CreatePluginAction(
		"photobooth_focus",
		"Photobooth Focus",
		"Focuses the camera to fit the selected PVInstance to the Photobooth capture viewport."
	)

	local folder = Instance.new("Folder")
	folder.Name = "EgoMoosePhotobooth"
	folder.Archivable = false
	folder.Parent = CoreGui

	local function ViewportApp(): React.ReactNode?
		local isEnabled, setIsEnabled = React.useState(false)
		local isCapturing = Hooks.usePhotoFlag("isCapturing")

		button:SetActive(isEnabled)

		React.useEffect(function()
			local trove = Trove.new()
			trove:Add(button.Click:Connect(function()
				setIsEnabled(not isEnabled)
			end))

			return function()
				trove:Destroy()
			end
		end)
		
		-- stylua: ignore
		return isEnabled and React.createElement("ScreenGui", {
			Name = "ViewportApp",
			Archivable = false,
			IgnoreGuiInset = true,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		}, {
			Content = React.createElement(Viewport, {
				OnCapture = function(rect)
					local captures = Photo.captureViewport(rect, Photo.Configuration.get().ViewportCaptureType)
					local selection = Photo.export(captures, StarterGui)
					SelectionService:Set(selection :: any)
				end,
				OnFocus = {
					Trigger = focusAction.Triggered,
					Callback = function(size)
						local selection = SelectionService:Get()
						local singleSelection = if #selection == 1 then selection[1] else nil

						if singleSelection and singleSelection:IsA("PVInstance") then
							Camera.focus(workspace.CurrentCamera, singleSelection, size)
						end
					end,
				},
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
		focusAction:Destroy()
		folder:Destroy()
	end)
end

function UserInterface.mountOpenGalleryButton(plugin: Plugin, button: PluginToolbarButton)
	local info = DockWidgetPluginGuiInfo.new(
		Enum.InitialDockState.Float, -- Widget will be initialized in floating panel
		false, -- Widget will be initially enabled
		false, -- Don't override the previous enabled state
		Constants.DockWidgetSize.X, -- Default width of the floating window
		Constants.DockWidgetSize.Y, -- Default height of the floating window
		Constants.DockWidgetSize.X, -- Minimum width of the floating window
		Constants.DockWidgetSize.Y -- Minimum height of the floating window
	)

	local dock = plugin:CreateDockWidgetPluginGui("PhotoboothViewer", info)
	dock.Title = "Photobooth"
	dock.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local function GalleryApp(): React.ReactNode
		local isEnabled, setIsEnabled = React.useState(dock.Enabled)
		local isCapturing = Hooks.usePhotoFlag("isCapturing")

		React.useEffect(function()
			local buttonConnection = button.Click:Connect(function()
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
		button:SetActive(isEnabled)

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

function UserInterface.mountImportPngButton(plugin: Plugin, button: PluginToolbarButton)
	local clickConnection = button.Click:Connect(function()
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
