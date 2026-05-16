-- Generic
local useConstant = require(script.Generic.useConstant)
local useMouseDrag = require(script.Generic.useMouseDrag)
local useSelection = require(script.Generic.useSelection)
local useRefProperty = require(script.Generic.useRefProperty)
local useBindingState = require(script.Generic.useBindingState)

-- Animation
local useShake = require(script.Animation.useShake)

-- Plugin
local usePlugin = require(script.Plugin.usePlugin)
local useIsStory = require(script.Plugin.useIsStory)
local usePluginMenu = require(script.Plugin.usePluginMenu)
local useIsLocalPlugin = require(script.Plugin.useIsLocalPlugin)
local useHasCreateAssetPermission = require(script.Plugin.useHasCreateAssetPermission)

-- Photobooth specific
local useState = require(script.Photobooth.useState)
local useStatePath = require(script.Photobooth.useStatePath)
local useLatestVersion = require(script.Photobooth.useLatestVersion)
local useEditableImageInfos = require(script.Photobooth.useEditableImageInfos)

export type EditableImageInfo = useEditableImageInfos.EditableImageInfo

-- Exported

return {
	useConstant = useConstant,
	useMouseDrag = useMouseDrag,
	useSelection = useSelection,
	useRefProperty = useRefProperty,
	useBindingState = useBindingState,

	useShake = useShake,

	usePlugin = usePlugin,
	useIsStory = useIsStory,
	usePluginMenu = usePluginMenu,
	useIsLocalPlugin = useIsLocalPlugin,
	useHasCreateAssetPermission = useHasCreateAssetPermission,

	useState = useState,
	useStatePath = useStatePath,
	useLatestVersion = useLatestVersion,
	useEditableImageInfos = useEditableImageInfos,
}
