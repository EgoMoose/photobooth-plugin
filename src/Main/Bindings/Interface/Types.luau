--!strict

export type UICaptureTypes = "NoBackground" | "AlphaMask"
export type ViewportCaptureTypes = "Unmodified" | "NoSkybox"

export type CaptureViewportOptions = {
	rect: Rect,
	type: ViewportCaptureTypes,

	delay: number?,
	alphaBleed: boolean?,
	disableOSScaleCameraFix: boolean?,
}

export type CaptureUIOptions = {
	subject: GuiObject,
	type: UICaptureTypes,

	delay: number?,
	alphaBleed: boolean?,
}

return {}
