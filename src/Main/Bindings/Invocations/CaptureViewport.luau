local pluginRoot = script:FindFirstAncestor("PluginRoot")
local gt = require(pluginRoot.Packages.GreenTea)
local Sift = require(pluginRoot.Packages.Sift)

local RenderRect = require(pluginRoot.Main.Bindings.Interface.Helpers.RenderRect)
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
	scale = gt.opt(gt.Vector2()),
	alphaBleed = gt.opt(gt.bool()),
})

-- stylua: ignore
local typechecker = gt.fn(
	gt.args(gtOptions),
	gt.returns(gt.opt(gt.IsA("MeshPart")))
)

local function callback(options: typeof(gtOptions))
	local scaleOS = State.read().temporary.scaleOS
	local captureScale = options.scale or Vector2.new(1, 1)

	local camera = workspace.CurrentCamera
	local viewportSize = camera.ViewportSize

	local prevCameraCF = camera.CFrame
	local prevCameraType = camera.CameraType
	camera.CameraType = Enum.CameraType.Scriptable

	local scaledRect: Rect
	if options.rect.Min == Vector2.zero and options.rect.Max == viewportSize then
		local scaledViewportX = math.round(viewportSize.X * scaleOS.X)
		local scaledViewportY = math.round(viewportSize.Y * scaleOS.Y)
		scaledRect = Rect.new(Vector2.new(0, 0), Vector2.new(scaledViewportX, scaledViewportY))
	else
		local viewportDelta = (viewportSize * scaleOS) - viewportSize
		local absPosition = options.rect.Min + viewportDelta / 2
		local absSize = options.rect.Max - options.rect.Min

		local center = absPosition + absSize / 2
		local offset = (absSize / 2) * captureScale
		scaledRect = RenderRect.fromRect(Rect.new(center - offset, center + offset))

		local cameraScale = captureScale / scaleOS
		if not (cameraScale.X == 1 and cameraScale.Y == 1) then
			local distortion = Camera.distort(camera, {
				anchor = Vector2.new(0.5, 0.5),
				position = Vector2.new(0.5, 0.5),
				size = cameraScale,
				zoom = 1,
				rotation = 0,
			})

			camera.CFrame = prevCameraCF * distortion
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
