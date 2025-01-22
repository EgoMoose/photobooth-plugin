--!nocheck

--[[
	Instructions:
		1. Copy this template to the StarterGui.
		2. Create a folder in the workspace named "FitToFrame_Targets" and put all the models you want to capture in it.
		3. Hide everything that is not in the target folder so that it is not visible in the workspace.
		4. Resize the "CaptureFrame" to your desired dimensions.
		5. Make any rotational adjustments to the targets as the camera will have identity rotation when taking the captures.
		6. Run `require(game.ServerStorage.PhotoboothBindings).execute(game.StarterGui.FitToFrame.Action)` in the command bar.
		7. After completion your captures will be in a timestamped folder under the StarterGui.

	UNIFORM_SCALE
		> If you have some capture targets that are larger than others you may want to use a consistent camera distance so
		> that all targets are captured showing their relative size to each other.
	
	DELAY_BETWEEN_CAPTURES
		> This represents how much time to delay once the capture target is about to be captured. This can be useful
		> when your targets have particles that need time to emit before capturing.
--]]

local UNIFORM_SCALE = false
local DELAY_BETWEEN_CAPTURES = 0

local StarterGui = game:GetService("StarterGui")
local ServerStorage = game:GetService("ServerStorage")

local Photobooth = require(ServerStorage.PhotoboothBindings)

local frame = script.Parent.CaptureFrame
local folder = workspace:FindFirstChild("FitToFrame_Targets") :: Folder

-- Helpers

local function validate()
	-- we turn streaming turned off so that we can move models in/out of the workspace very quickly.
	assert(not workspace.StreamingEnabled, "Cannot capture with streaming enabled turned on")
	assert(folder, "No target folder found!")

	assert(
		frame.AnchorPoint == Vector2.new(0.5, 0.5) and frame.Position == UDim2.fromScale(0.5, 0.5),
		"CaptureFrame must be in the center of the screen."
	)
end

local function getRectFromGuiObject(subject: GuiObject)
	local absPosition = subject.AbsolutePosition
	return Rect.new(absPosition:Ceil(), (absPosition + subject.AbsoluteSize):Ceil())
end

-- Capture

local function capture()
	local camera = workspace.CurrentCamera
	local viewportSize = camera.ViewportSize

	local prevCameraCFrame = camera.CFrame
	local prevCameraType = camera.CameraType
	camera.CameraType = Enum.CameraType.Scriptable
	folder.Parent = nil

	-- figure out the rect we're capturing and some math values we'll need to fit inside it
	local rect = getRectFromGuiObject(frame)
	local aspect = rect.Width / rect.Height
	local scaleY = rect.Height / viewportSize.Y
	local scaledFov2 = math.atan(math.tan(math.rad(camera.FieldOfView / 2)) * scaleY)
	local sinFov2 = math.sin(scaledFov2 * math.min(1, aspect))

	local maxRadius = 0
	local radiusByChild = {}
	for _, child in folder:GetChildren() do
		local model = Instance.new("Model")
		child.Parent = model

		-- measure the radius as hypotenuse / 2 of the bounding box facing the camera
		local _, boundSize = model:GetBoundingBox()
		local radius = boundSize.Magnitude / 2

		maxRadius = math.max(maxRadius, radius)
		radiusByChild[child] = radius

		child.Parent = folder
		model:Destroy()
	end

	local outputFolder = Instance.new("Folder")
	for _, child in folder:GetChildren() do
		local model = Instance.new("Model")
		child.Parent = model
		model.Parent = workspace

		local centerCF = model:GetPivot()
		local rotationCF = centerCF.Rotation
		model:PivotTo(rotationCF)

		-- adjust the camera such that model is contained in the rect
		local radius = if UNIFORM_SCALE then maxRadius else radiusByChild[child]
		camera.CFrame = CFrame.fromEulerAnglesYXZ(0, math.pi, 0) * CFrame.new(0, 0, radius / sinFov2)

		-- let the camera render since we just changed our scene
		Photobooth.yieldUntilNextFrame()
		if DELAY_BETWEEN_CAPTURES > 0 then
			task.wait(DELAY_BETWEEN_CAPTURES)
		end

		-- use photobooth to capture
		local result = Photobooth.captureViewport(rect, "NoSkybox")
		result.Name = child.Name
		result.Parent = outputFolder

		model:PivotTo(centerCF)
		child.Parent = folder
		model:Destroy()
	end

	camera.CFrame = prevCameraCFrame
	camera.CameraType = prevCameraType
	folder.Parent = workspace

	return outputFolder
end

validate()

local _success, err = Photobooth.cancellable(script, function()
	local results = capture()
	results.Name = DateTime.now():ToIsoDate()
	results.Archivable = false
	results.Parent = StarterGui
end)

if err then
	error("Photobooth: " .. err)
end
