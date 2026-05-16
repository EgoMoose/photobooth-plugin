local MarketplaceService = game:GetService("MarketplaceService") :: MarketplaceService

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Semver = require(pluginRoot.Packages.Semver)
local Signal = require(pluginRoot.Packages.Signal)
local React = require(pluginRoot.Packages.React)

local finished = Signal.new()
local resultVersion = "0.0.0"

task.spawn(function()
	local success, result =
		pcall(MarketplaceService.GetProductInfoAsync, MarketplaceService, 87864471469006, Enum.InfoType.Asset)
	if success then
		if Semver.validateVersion(result.Description) then
			resultVersion = result.Description
			finished:Fire()
		end
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
