--!strict

local CurrentVersion = require(script.V1)

local Versions = {}

export type Serialized = CurrentVersion.Serialized
export type Deserialized = CurrentVersion.Deserialized

export type VersionFormat = {
	migrate: (any) -> any,
	serialize: (any) -> any,
	deserialize: (any) -> any,
	version: number,
	index: number,
}

export type Saved = {
	version: number,
	serialized: any,
}

Versions.ByOrder = {}
Versions.ByVersion = {}
Versions.Current = (CurrentVersion :: any) :: VersionFormat

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

-- Public

function Versions.save(deserialized: Deserialized): Saved
	return {
		version = CurrentVersion.version,
		serialized = CurrentVersion.serialize(deserialized),
	}
end

function Versions.load(saved: Saved): Deserialized
	local matchedVersion = Versions.ByVersion[saved.version]
	assert(matchedVersion, "Unable to find a matching format version.")

	local serialized = saved.serialized
	local migrationIndex = matchedVersion.index
	for i = migrationIndex + 1, #Versions.ByOrder do
		local versionFormat = Versions.ByOrder[i]
		serialized = versionFormat.migrate(serialized)
	end

	return Versions.Current.deserialize(serialized)
end

--

init()
return Versions
