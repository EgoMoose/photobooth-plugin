--!strict

export type UICaptureTypes = "NoBackground" | "AlphaMask"
export type ViewportCaptureTypes = "Unmodified" | "NoSkybox"

export type CaptureViewportOptions = {
	rect: Rect,
	type: ViewportCaptureTypes,
	alphaBleed: boolean?,
	delay: number?,
}

export type CaptureUIOptions = {
	subject: GuiObject,
	type: UICaptureTypes,
	alphaBleed: boolean?,
	delay: number?,
}

return {}
