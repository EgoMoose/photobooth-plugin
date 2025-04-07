--!strict

local ChangeHistoryService = game:GetService("ChangeHistoryService") :: ChangeHistoryService

local criticalRoots = {}

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
			awaiting = {}
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

local function critical(level: number, callback: () -> ())
	local stack = level
	local rootCallback: (() -> ())?
	while not rootCallback do
		stack = stack + 1
		local potentialCallback = debug.info(stack, "f")
		if not potentialCallback then
			break
		end
		rootCallback = if criticalRoots[potentialCallback] then potentialCallback else nil
	end

	if rootCallback then
		local future = quickFuture()
		criticalRoots[rootCallback] = future
		task.spawn(function()
			callback()
			future.complete(nil)
		end)
		future.expect()
	else
		callback()
	end
end

local function wrap(callback: () -> ())
	criticalRoots[callback] = quickFuture()

	local identifier = assert(ChangeHistoryService:TryBeginRecording("photobooth_bindings", "Photobooth"))

	local callbackFuture = quickFuture()
	local finishedFuture = quickFuture()

	local success: boolean, err: string?
	local thread = task.spawn(function()
		success, err = pcall(function()
			callback()
		end)
		callbackFuture.complete(nil)
	end)

	local hasCancelled = false
	local function cancel()
		if not hasCancelled and not callbackFuture.isComplete() then
			hasCancelled = true

			while criticalRoots[callback].isComplete() do
				criticalRoots[callback].expect()
			end

			coroutine.close(thread)
			success, err = false, "Cancelled"
			callbackFuture.complete(nil)
		end
	end

	local function expectResult()
		finishedFuture.expect()
		return success, err
	end

	task.spawn(function()
		callbackFuture.expect()
		if success then
			ChangeHistoryService:FinishRecording(identifier, Enum.FinishRecordingOperation.Commit)
		else
			ChangeHistoryService:FinishRecording(identifier, Enum.FinishRecordingOperation.Cancel)
		end
		criticalRoots[callback] = nil
		finishedFuture.complete(nil)
	end)

	return expectResult, cancel
end

return {
	critical = critical,
	wrap = wrap,
}
