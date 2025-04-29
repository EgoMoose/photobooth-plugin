--!strict

local CurrentVersion = require(script.V1)

local Versions = {}

export type Configuration = CurrentVersion.Configuration
export type Serialized = CurrentVersion.Serialized

type VersionFormat = {
	migrate: (any) -> any,
	serialize: (any) -> any,
	deserialize: (any) -> any,
	version: number,
	index: number,
}

Versions.ByOrder = {}
Versions.ByVersion = {}
Versions.Current = CurrentVersion

local function init()
	for _, child in script:GetChildren() do
		local versionModule = require(child) :: VersionFormat
		Versions.ByVersion[versionModule.version] = versionModule
		table.insert(Versions.ByOrder, versionModule)
	end

	table.sort(Versions.ByOrder, function(a, b)
		return a.version < b.version
	end)

	for index, versionModule in Versions.ByOrder do
		versionModule.index = index
	end

	assert(
		Versions.ByOrder[#Versions.ByOrder].version == CurrentVersion.version,
		"Not using the latest save format version."
	)
end

init()
return Versions
