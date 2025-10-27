--!strict

-- Generic
local useConstant = require(script.Generic.useConstant)
local useMouseDrag = require(script.Generic.useMouseDrag)
local useSelection = require(script.Generic.useSelection)
local useRefProperty = require(script.Generic.useRefProperty)
local useBindingState = require(script.Generic.useBindingState)

-- Animation
local useMotion = require(script.Animation.useMotion)
local useSpring = require(script.Animation.useSpring)
local useShake = require(script.Animation.useShake)

-- Plugin
local usePlugin = require(script.Plugin.usePlugin)
local usePluginMenu = require(script.Plugin.usePluginMenu)
local useIsLocalPlugin = require(script.Plugin.useIsLocalPlugin)
local useHasCreateAssetPermission = require(script.Plugin.useHasCreateAssetPermission)

-- Photobooth specific
local useEditableImageInfos = require(script.Photobooth.useEditableImageInfos)

export type EditableImageInfo = useEditableImageInfos.EditableImageInfo

-- Exported

return {
	useConstant = useConstant,
	useMouseDrag = useMouseDrag,
	useSelection = useSelection,
	useRefProperty = useRefProperty,
	useBindingState = useBindingState,

	useMotion = useMotion,
	useSpring = useSpring,
	useShake = useShake,

	usePlugin = usePlugin,
	usePluginMenu = usePluginMenu,
	useIsLocalPlugin = useIsLocalPlugin,
	useHasCreateAssetPermission = useHasCreateAssetPermission,

	useEditableImageInfos = useEditableImageInfos,
}
