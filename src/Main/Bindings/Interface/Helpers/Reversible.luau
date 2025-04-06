--!strict

local RECORDING_NAME = "photobooth_reversible"

local ChangeHistoryService = game:GetService("ChangeHistoryService") :: ChangeHistoryService

local function quickFuture<T>()
	local result: T
	local completed = false
	local awaiting: { [thread]: boolean } = {}

	local function isComplete()
		return completed
	end

	local function complete(value: T)
		if not completed then
			completed = true
			result = value
			for thread, _ in awaiting do
				task.spawn(thread)
			end
		end
	end

	local function expect()
		if not completed then
			local thread = coroutine.running()
			awaiting[thread] = true
			coroutine.yield()
		end
		return result
	end

	return {
		isComplete = isComplete,
		complete = complete,
		expect = expect,
	}
end

local function beginRecording()
	local identifier = assert(
		ChangeHistoryService:TryBeginRecording(RECORDING_NAME, "Photobooth"),
		"Failed to get recording identifier."
	)

	return function(operation: Enum.FinishRecordingOperation)
		ChangeHistoryService:FinishRecording(identifier, operation)
	end
end

local function cacheCameraProperties()
	local camera = workspace.CurrentCamera :: Camera
	local properties: { { any } } = {
		{ "CameraType", camera.CameraType },
		{ "CameraSubject", camera.CameraSubject },
		{ "Focus", camera.Focus },
		{ "CFrame", camera.CFrame },
		{ "FieldOfViewMode", camera.FieldOfViewMode },
		{ "FieldOfView", camera.FieldOfView },
	}

	return function()
		local cameraNow = workspace.CurrentCamera
		for _, cached in properties do
			cameraNow[cached[1]] = cached[2]
		end
	end
end

local function reversible(callback: () -> ())
	beginRecording()(Enum.FinishRecordingOperation.Commit) -- make a snapshot before anything occurs

	local finishRecording = beginRecording()
	local callbackFuture = quickFuture()
	local finishedFuture = quickFuture()

	local success: boolean, err: string?
	local thread = task.spawn(function()
		success, err = pcall(function()
			callback()
		end)
		callbackFuture.complete(nil)
	end)

	task.spawn(function()
		callbackFuture.expect()
		finishRecording(Enum.FinishRecordingOperation.Commit)
		if not success and ChangeHistoryService:GetCanUndo() then
			ChangeHistoryService:Undo()
		end
		finishedFuture.complete(nil)
	end)

	local function reverse()
		if not callbackFuture.isComplete() then
			coroutine.close(thread)
			success, err = false, "Reversed"
			callbackFuture.complete(nil)
		end
	end

	local function expectResult()
		finishedFuture.expect()
		return success, err
	end

	return expectResult, reverse
end

return reversible
