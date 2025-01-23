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

function Camera.focus(camera: Camera, selection: { Instance }, viewportSize: Vector2)
	local bounds = {}
	local centerSum = Vector3.zero
	for _, selected in selection do
		if selected:IsA("PVInstance") then
			local boundCF, boundSize
			if selected:IsA("BasePart") then
				boundCF = selected.CFrame
				boundSize = selected.Size
			elseif selected:IsA("Model") then
				boundCF, boundSize = selected:GetBoundingBox()
			end

			table.insert(bounds, {
				CFrame = boundCF,
				Size = boundSize,
			})

			centerSum = centerSum + boundCF.Position
		end
	end

	if #bounds > 0 then
		local center = centerSum / #bounds

		local maxRadius = 0
		for _, bound in bounds do
			local radius = (bound.Size / 2).Magnitude
			local distance = (bound.CFrame.Position - center).Magnitude
			maxRadius = math.max(maxRadius, distance + radius)
		end

		local aspect = viewportSize.X / viewportSize.Y
		local scaleY = viewportSize.Y / camera.ViewportSize.Y
		local scaledFov2 = math.atan(math.tan(math.rad(camera.FieldOfView / 2)) * scaleY)
		local sinFov2 = math.sin(scaledFov2 * math.min(1, aspect))

		local focusCF = camera.CFrame.Rotation + center

		camera.Focus = focusCF
		camera.CFrame = focusCF * CFrame.new(0, 0, maxRadius / sinFov2)
	end
end

return Camera
