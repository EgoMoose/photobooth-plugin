--!strict

local HttpService = game:GetService("HttpService") :: HttpService
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

local function undoToWaypoint(waypoint: string)
	local undoFuture = quickFuture()
	local eventFuture = quickFuture()

	local connection = ChangeHistoryService.OnUndo:Connect(function(wp)
		if wp == waypoint then
			undoFuture.complete(nil)
		end
		eventFuture.complete(nil)
	end)

	task.spawn(function()
		while not undoFuture.isComplete() and ChangeHistoryService:GetCanUndo() do
			eventFuture = quickFuture()
			ChangeHistoryService:Undo()
			eventFuture.expect()
		end
	end)

	undoFuture.expect()
	connection:Disconnect()
end

local function cancellable(callback: () -> ())
	local identifier = HttpService:GenerateGUID()
	local startWaypoint = `{identifier}_start`
	ChangeHistoryService:SetWaypoint(startWaypoint)

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
			coroutine.close(thread)
			success, err = false, "Cancelled"
			callbackFuture.complete(nil)
		end
	end

	local function expectResult()
		finishedFuture.expect()
		return success, err
	end

	local waypointUndone = false
	local connection = ChangeHistoryService.OnUndo:Connect(function(wp)
		if wp == startWaypoint then
			waypointUndone = true
		end
		cancel()
	end)

	task.spawn(function()
		callbackFuture.expect()
		connection:Disconnect()
		if success then
			ChangeHistoryService:SetWaypoint(`{identifier}_finish`)
		elseif not waypointUndone then
			waypointUndone = true
			--undoToWaypoint(startWaypoint)
			print(startWaypoint)
		end
		finishedFuture.complete(nil)
	end)

	return expectResult, cancel
end

return cancellable
