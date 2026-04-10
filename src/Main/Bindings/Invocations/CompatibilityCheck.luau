--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local CargoSemver = require(pluginRoot.Packages.CargoSemver)
local Semver = require(pluginRoot.Packages.Semver)
local gt = require(pluginRoot.Packages.GreenTea)

local Wally = require(pluginRoot.Wally)

-- stylua: ignore
local typechecker = gt.fn(
	gt.args(gt.string()),
	gt.returns(gt.boolean())
)

local function callback(version: string)
	if Semver.validateVersion(Wally.package.version) and Semver.validateVersion(version) then
		local wallyVersion = CargoSemver.Version.parse(Wally.package.version)
		local checkVersion = CargoSemver.Version.parse(version)
		return checkVersion.major == wallyVersion.major and checkVersion.minor >= wallyVersion.minor
	end
	return false
end

return {
	identifier = "compatibilityCheck",
	callback = gt.wrapFn(typechecker, callback),
}
