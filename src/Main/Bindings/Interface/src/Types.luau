export type UICaptureTypes = "NoBackground" | "AlphaMask"
export type ViewportCaptureTypes = "Unmodified" | "NoSkybox"

export type CaptureViewportOptions = {
	rect: Rect,
	type: ViewportCaptureTypes,

	delay: number?,
	scale: Vector2?,
	alphaBleed: boolean?,
}

export type CaptureUIOptions = {
	subject: GuiObject,
	type: UICaptureTypes,

	delay: number?,
	scale: Vector2?,
	alphaBleed: boolean?,
}

return {}
