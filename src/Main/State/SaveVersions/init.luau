local CurrentVersion = require(script.V1)

local SaveVersions = {}

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

SaveVersions.byOrder = {}
SaveVersions.byVersion = {}
SaveVersions.latest = (CurrentVersion :: any) :: VersionFormat

local function init()
	for _, child in script:GetChildren() do
		local versionModule = require(child) :: VersionFormat
		SaveVersions.byVersion[versionModule.version] = versionModule
		table.insert(SaveVersions.byOrder, versionModule)
	end

	table.sort(SaveVersions.byOrder, function(a, b)
		return a.version < b.version
	end)

	for index, versionModule in SaveVersions.byOrder do
		versionModule.index = index
	end

	assert(
		SaveVersions.byOrder[#SaveVersions.byOrder].version == CurrentVersion.version,
		"Not using the latest save format version."
	)
end

-- Public

function SaveVersions.save(deserialized: Deserialized): Saved
	return {
		version = CurrentVersion.version,
		serialized = CurrentVersion.serialize(deserialized),
	}
end

function SaveVersions.load(saved: Saved): Deserialized
	local matchedVersion = SaveVersions.byVersion[saved.version]
	assert(matchedVersion, "Unable to find a matching format version.")

	local serialized = saved.serialized
	local migrationIndex = matchedVersion.index
	for i = migrationIndex + 1, #SaveVersions.byOrder do
		local versionFormat = SaveVersions.byOrder[i]
		serialized = versionFormat.migrate(serialized)
	end

	return SaveVersions.latest.deserialize(serialized)
end

--

init()
return SaveVersions
