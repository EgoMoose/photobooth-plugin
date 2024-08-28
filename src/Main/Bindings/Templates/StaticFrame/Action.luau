--!nocheck

--[[
	Instructions:
		1. Copy this template to the StarterGui.
		2. Create a folder in the workspace named "StaticFrame_Targets" and put all the models you want to capture in it.
		3. Hide everything that is not in the target folder so that it is not visible in the workspace.
		4. Resize the "CaptureFrame" to your desired dimensions.
		5. Adjust your camera and move any move any target models so that they're in the bounds of the capture frame.
		5. Run `require(game.ServerStorage.PhotoboothBindings).execute(game.StarterGui.StaticFrame.Action)` in the command bar.
		6. After completion your captures will be in a timestamped folder under the ServerStorage.

	DELAY_BETWEEN_CAPTURES
		> This represents how much time to delay once the capture target is about to be captured. This can be useful
		> when your targets have particles that need time to emit before capturing.
--]]

local DELAY_BETWEEN_CAPTURES = 0

local ServerStorage = game:GetService("ServerStorage")
local Photobooth = require(ServerStorage.PhotoboothBindings)

local frame = script.Parent.CaptureFrame
local folder = workspace:FindFirstChild("StaticFrame_Targets") :: Folder

-- Helpers

local function getRectFromGuiObject(subject: GuiObject)
	local absPosition = subject.AbsolutePosition
	return Rect.new(absPosition:Ceil(), (absPosition + subject.AbsoluteSize):Ceil())
end

-- Capture

local function validate()
	assert(not workspace.StreamingEnabled, "Cannot capture with streaming enabled turned on")
	assert(folder, "No target folder found!")

	assert(
		frame.AnchorPoint == Vector2.new(0.5, 0.5) and frame.Position == UDim2.fromScale(0.5, 0.5),
		"CaptureFrame must be in the center of the screen."
	)
end

local function capture()
	local camera = workspace.CurrentCamera

	local prevCameraCFrame = camera.CFrame
	local prevCameraType = camera.CameraType
	camera.CameraType = Enum.CameraType.Scriptable
	folder.Parent = nil

	local rect = getRectFromGuiObject(frame)
	local outputFolder = Instance.new("Folder")
	for _, child in folder:GetChildren() do
		child.Parent = workspace

		-- let the camera render since we just changed our scene
		Photobooth.yieldUntilNextFrame()
		if DELAY_BETWEEN_CAPTURES > 0 then
			task.wait(DELAY_BETWEEN_CAPTURES)
		end

		-- use photobooth to capture
		local result = Photobooth.captureViewport(rect, "NoSkybox")
		result.Name = child.Name
		result.Parent = outputFolder

		child.Parent = folder
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
	results.Parent = ServerStorage
end)

if err then
	error("Photobooth: " .. err)
end
