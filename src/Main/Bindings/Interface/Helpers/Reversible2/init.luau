--!strict

local ChangeHistoryService = game:GetService("ChangeHistoryService") :: ChangeHistoryService

local Future = require(script.FutureLite)

local Reversible = {}
local criticalFutures = {}

function Reversible.critical(level: number, callback: () -> ())
	local stack = level
	local wrappedCallback: (() -> ())?

	repeat
		stack = stack + 1
		wrappedCallback = debug.info(stack, "f")
	until not wrappedCallback or criticalFutures[wrappedCallback]

	if wrappedCallback then
		criticalFutures[wrappedCallback] = Future.new()
		callback()
		criticalFutures[wrappedCallback]:complete(nil)
	else
		callback()
	end
end

function Reversible.wrap(callback: () -> ())
	criticalFutures[callback] = Future.resolve(nil)

	local identifier = assert(ChangeHistoryService:TryBeginRecording("photobooth_bindings", "Photobooth"))

	local success: boolean, err: string?
	local callbackFuture = Future.new()
	local callbackThread = task.spawn(function()
		success, err = pcall(function()
			callback()
		end)

		if success then
			ChangeHistoryService:FinishRecording(identifier, Enum.FinishRecordingOperation.Commit)
		end

		callbackFuture:complete(nil)
	end)

	local alreadyCalled = false
	local function undo()
		if not alreadyCalled then
			alreadyCalled = true

			if coroutine.status(callbackThread) == "running" then
				-- wait until critical step is done
				while not criticalFutures[callback]:isComplete() do
					criticalFutures[callback]:expect()
				end

				-- cancel the thread before reverting
				task.cancel(callbackThread)
				success, err = false, "Cancelled"
				callbackFuture:complete(nil)
			end

			if success then
				ChangeHistoryService:FinishRecording(identifier, Enum.FinishRecordingOperation.Cancel)
			end
		end
	end

	local function expect()
		callbackFuture:expect()
		return success, err
	end

	return expect, undo
end

return Reversible
