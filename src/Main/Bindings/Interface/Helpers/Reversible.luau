--!strict

local SelectionService = game:GetService("Selection") :: Selection
local ChangeHistoryService = game:GetService("ChangeHistoryService") :: ChangeHistoryService

local Reversible = {}

-- Private

local function simpleFuture<T>()
	local isComplete = false
	local awaiting: { [thread]: boolean } = {}
	local result: T

	local function isCompleted()
		return isComplete
	end

	local function complete(value: T)
		assert(not isComplete, "Already completed")

		isComplete = true
		result = value

		local threads = awaiting
		awaiting = {}
		for thread, _ in threads do
			coroutine.resume(thread)
		end
	end

	local function expect()
		if not isCompleted then
			local thread = coroutine.running()
			awaiting[thread] = true
			coroutine.yield()
		end
		return result
	end

	return {
		isCompleted = isCompleted,
		complete = complete,
		expect = expect,
	}
end

local function createRevertCameraCallback()
	local camera = workspace.CurrentCamera :: Camera
	local properties = {
		CameraType = camera.CameraType,
		CameraSubject = camera.CameraSubject,
		FieldOfView = camera.FieldOfView,
		CFrame = camera.CFrame,
		Focus = camera.Focus,
	}

	return function()
		local currentCamera = workspace.CurrentCamera :: Camera
		currentCamera.CameraType = properties.CameraType
		currentCamera.CameraSubject = properties.CameraSubject
		currentCamera.FieldOfView = properties.FieldOfView
		currentCamera.CFrame = properties.CFrame
		currentCamera.Focus = properties.Focus
	end
end

-- Public

function Reversible.wrap(callback: () -> ())
	local selection = SelectionService:Get()
	local revertCamera = createRevertCameraCallback()
	local identifier = assert(ChangeHistoryService:TryBeginRecording("photobooth_bindings", "Photobooth"))

	local callbackFuture = simpleFuture()
	local callbackThread = task.spawn(function()
		local success, err = pcall(function()
			callback()
		end)

		callbackFuture.complete({
			success = success,
			err = err,
		})
	end)

	local alreadyCalled = false
	local function cancel()
		if not alreadyCalled then
			alreadyCalled = true

			if not callbackFuture.isCompleted() then
				-- wait until the callback thread is suspended so we can cancel it
				while coroutine.status(callbackThread) ~= "suspended" do
					task.wait()
				end

				-- cancel the thread
				coroutine.close(callbackThread)

				if not callbackFuture.isCompleted() then
					callbackFuture.complete({
						success = false,
						err = "Cancelled",
					})

					-- finish recording w/ cancel arg which will undo everything up to when the recording started
					ChangeHistoryService:FinishRecording(identifier, Enum.FinishRecordingOperation.Cancel)

					-- for some reason when cancelling studio selects a lot of random stuff in the explorer
					SelectionService:Set(selection)

					-- manually reset camera properties b/c change history service doesn't seem to work w/ cameras
					revertCamera()
				end
			end
		end
	end

	local function expect()
		local result = callbackFuture.expect()
		return result.success, result.err
	end

	return expect, cancel
end

--

return Reversible
