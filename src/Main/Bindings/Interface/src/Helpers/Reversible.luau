local SelectionService = game:GetService("Selection") :: Selection
local ChangeHistoryService = game:GetService("ChangeHistoryService") :: ChangeHistoryService

local Reversible = {}

-- Private

local pcall: <T...>((T...) -> (), T...) -> (boolean, string?) = pcall :: any

local function simpleFuture<T>()
	local result: T
	local completed = false
	local awaiting: { [thread]: boolean } = {}

	local function isCompleted()
		return completed
	end

	local function resolve(value: T)
		assert(not completed, "Already completed")

		completed = true
		result = value

		local threads = awaiting
		awaiting = {}
		for thread, _ in threads do
			coroutine.resume(thread)
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
		isCompleted = isCompleted,
		resolve = resolve,
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

	local identifier
	if ChangeHistoryService:IsRecordingInProgress() then
		-- stylua: ignore
		warn("Unable to use Reversible.wrap since ChangeHistoryService is already recording. This may be due to the multi-line command bar.")
	else
		identifier = assert(ChangeHistoryService:TryBeginRecording("photobooth_bindings", "Photobooth"))
	end

	local callbackFuture = simpleFuture()
	local callbackThread = task.spawn(function()
		local success, err = pcall(function()
			callback()
		end)

		if not success then
			if identifier then
				ChangeHistoryService:FinishRecording(identifier, Enum.FinishRecordingOperation.Cancel)
			end

			SelectionService:Set(selection)
			revertCamera()
		elseif identifier then
			ChangeHistoryService:FinishRecording(identifier, Enum.FinishRecordingOperation.Commit)
		end

		callbackFuture.resolve({
			success = success,
			err = err,
		})
	end)

	local alreadyCalled = false
	local function cancel()
		if not alreadyCalled then
			alreadyCalled = true

			if not callbackFuture.isCompleted() then
				while coroutine.status(callbackThread) ~= "suspended" do
					task.wait()
				end

				coroutine.close(callbackThread)

				if not callbackFuture.isCompleted() then
					if identifier then
						ChangeHistoryService:FinishRecording(identifier, Enum.FinishRecordingOperation.Cancel)
					end

					SelectionService:Set(selection)
					revertCamera()

					callbackFuture.resolve({
						success = false,
						err = "Cancelled",
					})
				end
			end
		end
	end

	local function expect()
		local result = callbackFuture.expect() :: any
		return result.success :: boolean, result.err :: string?
	end

	return expect :: () -> (boolean, string?), cancel :: () -> ()
end

--

return Reversible
