--!strict

local MarketplaceService = game:GetService("MarketplaceService") :: MarketplaceService

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Signal = require(pluginRoot.Packages.Signal)
local React = require(pluginRoot.Packages.React)
local Wally = require(pluginRoot.Wally)

local finished = Signal.new()
local resultVersion = Wally.package.version

task.spawn(function()
	local success, result =
		pcall(MarketplaceService.GetProductInfo, MarketplaceService, 87864471469006, Enum.InfoType.Asset)
	if success then
		resultVersion = result.Description
		finished:Fire()
	end
end)

local function useLatestVersion()
	local latestVersion, setLatestVersion = React.useState(resultVersion)

	React.useEffect(function()
		setLatestVersion(resultVersion)
		local connection = finished:Connect(function()
			setLatestVersion(resultVersion)
		end)

		return function()
			connection:Disconnect()
		end
	end, {})

	return latestVersion
end

return useLatestVersion
