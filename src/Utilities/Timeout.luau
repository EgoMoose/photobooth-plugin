--!strict

local RunService = game:GetService("RunService") :: RunService

local Timeout = {}

local function killThread(thread: thread)
	local status = coroutine.status(thread)
	if status ~= "dead" then
		task.cancel(thread)
	end
end

function Timeout.getStudioTimeoutLength(default: number)
	local duration = default
	if RunService:IsStudio() then
		pcall(function()
			duration = settings().Studio.ScriptTimeoutLength - 0.1
		end)
	end
	return duration
end

function Timeout.async<T..., U...>(duration: number, callback: (T...) -> U..., ...: T...): (boolean, string?, U...)
	local success, err: string?
	local rootThread = coroutine.running()

	local packedResults
	local packedArgs = table.pack(...)

	local callbackThread = task.spawn(function()
		success, err = pcall(function()
			packedResults = table.pack(callback(table.unpack(packedArgs :: { any }, 1, packedArgs.n)))
		end)
		coroutine.resume(rootThread)
	end)

	local timeoutThread = task.delay(duration, function()
		if duration > 0 then
			success, err = false, "Execution time exceeded."
			coroutine.resume(rootThread)
		end
	end)

	while success == nil do
		coroutine.yield()
	end

	killThread(callbackThread)
	killThread(timeoutThread)

	return success, err, table.unpack(packedResults :: { any }, 1, packedResults.n)
end

return Timeout
