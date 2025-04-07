--!strict

local Invoke = require(script.Parent.Parent.Invoke)

local criticalRoots = {}

local function packAsCallback<T...>(...: T...): () -> T...
	local n = select("#", ...)
	local packed = { select(1, ...) }
	return function()
		return unpack(packed, 1, n)
	end
end

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

local function critical<T..., U...>(level: number, callback: (T...) -> U...)
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
		local unpackCallback
		local future = quickFuture()
		criticalRoots[rootCallback] = future
		task.spawn(function()
			unpackCallback = packAsCallback(callback())
			future.complete(nil)
		end)
		future.expect()
		return unpackCallback()
	else
		return callback()
	end
end

local function wrap(callback: () -> ())
	criticalRoots[callback] = quickFuture()

	local identifier = Invoke("tryBeginRecording") :: string

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
			Invoke("finishRecording", identifier, Enum.FinishRecordingOperation.Commit)
		else
			Invoke("finishRecording", identifier, Enum.FinishRecordingOperation.Cancel)
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
