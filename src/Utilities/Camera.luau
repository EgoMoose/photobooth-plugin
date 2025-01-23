--!strict

local Camera = {}

type Distortion = {
	anchor: Vector2,
	position: Vector2,
	size: Vector2,
	zoom: number,
	nearZ: number,
	rotation: number,
}

function Camera.distort(camera: Camera, distortion: Distortion)
	local viewportSize = camera.ViewportSize
	local aspectRatio = viewportSize.X / viewportSize.Y

	local hFactor = math.tan(math.rad(camera.FieldOfView) / 2)
	local wFactor = hFactor * aspectRatio

	local center = distortion.position - distortion.size * distortion.anchor + distortion.size / 2

	local w, h = distortion.size.X, distortion.size.Y
	local dx = 2 * wFactor * (0.5 - center.X)
	local dy = -2 * hFactor * (0.5 - center.Y)
	local dz = distortion.zoom

	local m = math.max(math.abs(w), math.abs(h), math.abs(dx), math.abs(dy), math.abs(dz))
	local nz = ((camera.NearPlaneZ + distortion.nearZ) / camera.NearPlaneZ) * (dz / m)

	-- stylua: ignore
	return CFrame.fromEulerAnglesXYZ(0, 0, distortion.rotation) * CFrame.new(0, 0, 0,
		w / m, 0, 0,
		0, h / m, 0,
		dx / m, dy / m, dz / m
	) * CFrame.new(0, 0, 0,
		1 / nz, 0, 0,
		0, 1 / nz, 0,
		0, 0, 1 / nz
	)
end

function Camera.focus(camera: Camera, instance: PVInstance, size: Vector2)
	local viewportSize = camera.ViewportSize
	local aspect = size.X / size.Y
	local scaleY = size.Y / viewportSize.Y
	local scaledFov2 = math.atan(math.tan(math.rad(camera.FieldOfView / 2)) * scaleY)
	local sinFov2 = math.sin(scaledFov2 * math.min(1, aspect))

	-- get the bounding box of focus
	local boundCF, boundSize
	if instance:IsA("BasePart") then
		boundCF = instance.CFrame
		boundSize = instance.Size
	elseif instance:IsA("Model") then
		boundCF, boundSize = instance:GetBoundingBox()
	end

	local radius = boundSize.Magnitude / 2
	local focusCF = camera.CFrame.Rotation + boundCF.Position

	camera.Focus = focusCF
	camera.CFrame = focusCF * CFrame.new(0, 0, radius / sinFov2)
end

return Camera
