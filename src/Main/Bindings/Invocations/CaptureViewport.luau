--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local gt = require(pluginRoot.Packages.GreenTea)
local Sift = require(pluginRoot.Packages.Sift)

local SceneControl = require(pluginRoot.Main.Photo.SceneControl)
local RenderRect = require(pluginRoot.Utilities.RenderRect)
local Captures = require(pluginRoot.Main.Photo.Captures)
local Camera = require(pluginRoot.Utilities.Camera)
local State = require(pluginRoot.Main.State)
local Photo = require(pluginRoot.Main.Photo)

local captureTypeLiterals = Sift.Array.map(Captures.Viewport.Order, function(value)
	return gt.literal(value)
end)

local gtOptions = gt.table({
	type = gt.union(unpack(captureTypeLiterals)),
	rect = gt.Rect(),
	delay = gt.opt(gt.number()),
	alphaBleed = gt.opt(gt.bool()),
	disableOSScaleCameraFix = gt.opt(gt.bool()),
})

-- stylua: ignore
local typechecker = gt.fn(
	gt.args(gtOptions),
	gt.returns(gt.IsA("MeshPart"))
)

local function callback(options: typeof(gtOptions))
	local scaleOS = State.read().temporary.scaleOS
	local disableCameraFix = not not options.disableOSScaleCameraFix

	local camera = workspace.CurrentCamera
	local viewportSize = camera.ViewportSize

	local prevCameraCF = camera.CFrame
	local prevCameraType = camera.CameraType
	camera.CameraType = Enum.CameraType.Scriptable

	local scaledRect: Rect
	if options.rect.Min == Vector2.zero and options.rect.Max == viewportSize then
		-- stylua: ignore
		local scaledViewportSize = Vector2.new(
			math.round(viewportSize.X * scaleOS.X),
			math.round(viewportSize.Y * scaleOS.Y)
		)

		scaledRect = Rect.new(Vector2.zero, scaledViewportSize)
	elseif disableCameraFix then
		-- stylua: ignore
		scaledRect = RenderRect.fromRect(Rect.new(
			options.rect.Min * scaleOS,
			options.rect.Max * scaleOS
		))
	else
		local corner = ((viewportSize * scaleOS) - viewportSize) / 2
		local scaledRectAbsPosition = (options.rect.Min + corner)
		local scaledRectAbsSize = (options.rect.Max + corner) - scaledRectAbsPosition
		scaledRect = RenderRect.fromAbs(scaledRectAbsPosition, scaledRectAbsSize)

		if not (scaleOS.X == 1 and scaleOS.Y == 1) then
			-- stylua: ignore
			camera.CFrame = prevCameraCF * Camera.distort(camera, {
				anchor = Vector2.new(0.5, 0.5),
				position = Vector2.new(0.5, 0.5),
				size = 1 / scaleOS,
				zoom = 1,
				nearZ = 0,
				rotation = 0,
			})

			SceneControl.yieldUntilNextFrame()
		end
	end

	local exported
	local success, err = pcall(function()
		local result = Photo.captureViewport(Sift.Dictionary.merge(options, {
			rect = scaledRect,
		}))

		exported = Photo.export(result, nil)
	end)

	camera.CFrame = prevCameraCF
	camera.CameraType = prevCameraType

	if not success then
		error(err)
	end

	return exported[1]
end

return {
	identifier = "captureViewport",
	callback = gt.wrapFn(typechecker, callback),
}
