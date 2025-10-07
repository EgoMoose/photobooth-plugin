--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Sift = require(pluginRoot.Packages.Sift)

local Types = require(pluginRoot.Main.Bindings.Interface.Types)

local ConfigurationFormatV1 = {}

export type Configuration = {
	-- General
	ScaleOS: Vector2,
	AlphaBleedingEnabled: boolean,
	BindingsEnabled: boolean,
	GalleryListExpanded: boolean,

	-- Viewport
	IsFullscreen: boolean,
	ViewportCaptureType: Types.ViewportCaptureTypes,

	-- User Interface
	UserInterfaceCaptureType: Types.UICaptureTypes,
}

export type Serialized = {
	-- General
	AlphaBleedingEnabled: boolean,
	BindingsEnabled: boolean,
	GalleryListExpanded: boolean,

	-- Viewport
	ViewportCaptureType: Types.ViewportCaptureTypes,

	-- User Interface
	UserInterfaceCaptureType: Types.UICaptureTypes,
}

-- Public

ConfigurationFormatV1.version = 1

function ConfigurationFormatV1.default(): Configuration
	return {
		-- General
		ScaleOS = Vector2.new(1, 1),
		AlphaBleedingEnabled = true,
		BindingsEnabled = false,
		GalleryListExpanded = false,

		-- Viewport
		IsFullscreen = false,
		ViewportCaptureType = "NoSkybox",

		-- User Interface
		UserInterfaceCaptureType = "NoBackground",
	}
end

function ConfigurationFormatV1.migrate(_previousSerialized: any)
	error(
		`[ConfigurationFormatV{ConfigurationFormatV1.version}]: It should not be possible to migrate to this version since it's the first version ever!`
	)
end

function ConfigurationFormatV1.serialize(configuration: Configuration): Serialized
	return {
		-- General
		AlphaBleedingEnabled = configuration.AlphaBleedingEnabled,
		BindingsEnabled = configuration.BindingsEnabled,
		GalleryListExpanded = configuration.GalleryListExpanded,

		-- Viewport
		ViewportCaptureType = configuration.ViewportCaptureType,

		-- User Interface
		UserInterfaceCaptureType = configuration.UserInterfaceCaptureType,
	}
end

function ConfigurationFormatV1.deserialize(serialized: Serialized): Configuration
	return Sift.Dictionary.mergeDeep(ConfigurationFormatV1.default(), {
		-- General
		AlphaBleedingEnabled = serialized.AlphaBleedingEnabled,
		BindingsEnabled = serialized.BindingsEnabled,
		GalleryListExpanded = serialized.GalleryListExpanded,

		-- Viewport
		ViewportCaptureType = serialized.ViewportCaptureType,

		-- User Interface
		UserInterfaceCaptureType = serialized.UserInterfaceCaptureType,
	})
end

--

return ConfigurationFormatV1
