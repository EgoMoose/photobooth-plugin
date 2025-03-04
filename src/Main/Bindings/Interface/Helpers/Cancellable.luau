--!strict

local ChangeHistoryService = game:GetService("ChangeHistoryService") :: ChangeHistoryService

local function reversible(callback: () -> ())
	local identifier = assert(ChangeHistoryService:TryBeginRecording("Photobooth"), "Could not start recording")

	local isComplete = false
	local awaiting: { [thread]: boolean } = {}

	local function complete()
		if not isComplete then
			isComplete = true
			for thread, _ in awaiting do
				task.spawn(thread)
			end
		end
	end

	local function yield()
		if not isComplete then
			local thread = coroutine.running()
			awaiting[thread] = true
			coroutine.yield()
		end
	end

	local success: boolean, err: string?
	local thread = task.spawn(function()
		success, err = pcall(callback)
		complete()
	end)

	task.spawn(function()
		yield()

		local operation = Enum.FinishRecordingOperation.Commit
		if not success then
			operation = Enum.FinishRecordingOperation.Cancel
		end

		ChangeHistoryService:FinishRecording(identifier, operation)
	end)

	local function cancel()
		if not isComplete then
			coroutine.close(thread)
			success, err = false, "Cancelled"
			complete()
		end
	end

	local function isSuccess()
		yield()
		return success, err
	end

	return isSuccess, cancel
end

local function cancellable(script: LuaSourceContainer, callback: () -> ())
	local isSuccess, cancel = reversible(callback)

	script:SetAttribute("Cancel", false)
	local connection = script:GetAttributeChangedSignal("Cancel"):Connect(function()
		if script:GetAttribute("Cancel") then
			cancel()
		end
	end)

	local success, err = isSuccess()
	connection:Disconnect()
	script:SetAttribute("Cancel", nil)

	return success, err
end

return cancellable
