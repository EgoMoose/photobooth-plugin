--!strict

local AssetService = game:GetService("AssetService") :: AssetService

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local React = require(pluginRoot.Packages.React)

local success = false
local finished = Instance.new("BindableEvent")
task.spawn(function()
	local model = Instance.new("Model")
	-- attempt to upload something as Roblox which will error if the api isn't available this includes uploading from a cloud plugin
	-- the request itself will fail but not error if the api is enabled b/c chances are that you're not roblox
	success = pcall(AssetService.CreateAssetAsync, AssetService, model, Enum.AssetType.Model, { CreatorId = 1 })
	model:Destroy()
	finished:Fire()
end)

local function useHasCreateAssetPermission()
	local hasPermission, setHasPermission = React.useState(success)

	React.useEffect(function()
		setHasPermission(success)
		local connection = finished.Event:Connect(function()
			setHasPermission(success)
		end)

		return function()
			connection:Disconnect()
		end
	end)

	return hasPermission
end

return useHasCreateAssetPermission
