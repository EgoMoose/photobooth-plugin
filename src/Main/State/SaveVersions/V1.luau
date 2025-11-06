--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Sift = require(pluginRoot.Packages.Sift)

local SaveFormatV1 = {}

export type Serialized = {
	alphaBleedingEnabled: boolean,
	bindingsEnabled: boolean,
	galleryListExpanded: boolean,
}

export type Deserialized = {
	alphaBleedingEnabled: boolean,
	bindingsEnabled: boolean,
	galleryListExpanded: boolean,
}

local function toboolean(bool: boolean)
	return if typeof(bool) == "boolean" then bool else nil
end

SaveFormatV1.version = 1

function SaveFormatV1.default(): Deserialized
	return {
		alphaBleedingEnabled = true,
		bindingsEnabled = false,
		galleryListExpanded = true,
	}
end

function SaveFormatV1.migrate(_previousSerialized: any)
	error(`[SaveFormatV{SaveFormatV1.version}]: Cannot migrate from V1`)
end

function SaveFormatV1.serialize(deserialized: Deserialized): Serialized
	return {
		alphaBleedingEnabled = not not deserialized.alphaBleedingEnabled,
		bindingsEnabled = not not deserialized.bindingsEnabled,
		galleryListExpanded = not not deserialized.galleryListExpanded,
	}
end

function SaveFormatV1.deserialize(serialized: Serialized): Deserialized
	return Sift.Dictionary.mergeDeep(SaveFormatV1.default(), {
		alphaBleedingEnabled = toboolean(serialized.alphaBleedingEnabled),
		bindingsEnabled = toboolean(serialized.bindingsEnabled),
		galleryListExpanded = toboolean(serialized.galleryListExpanded),
	})
end

return SaveFormatV1
