--!strict

local RunService = game:GetService("RunService") :: RunService

local Timeout = {}

local function getStudioTimeoutLength(default: number)
	local duration = default
	if RunService:IsStudio() then
		pcall(function()
			local timeoutLength = settings().Studio.ScriptTimeoutLength - 0.1
			if timeoutLength > 0 then
				duration = timeoutLength
			end
		end)
	end
	return duration
end

function Timeout.benchmark<T..., U...>(callback: (T...) -> U..., ...: T...): (number, U...)
	local t = os.clock()
	local packed = table.pack(callback(...))
	local dt = os.clock() - t
	return dt, table.unpack(packed :: { any }, 1, packed.n)
end

function Timeout.scriptExhaustionStepper(default: number)
	local prevTick = os.clock()
	local duration = getStudioTimeoutLength(default)
	return function(reset: boolean?)
		if reset then
			prevTick = os.clock()
		end

		if os.clock() - prevTick >= duration then
			task.wait()
			prevTick = os.clock()
		end
	end
end

Timeout.tryYield = Timeout.scriptExhaustionStepper(10)

return Timeout
