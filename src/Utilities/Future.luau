--!strict

-- Using this as a lightweight alternative to Promises that also supports
-- typing. Futures in this context are not nearly as useful as promises, but I
-- prefer to having typing over a feature rich alternative

local FutureClass = {}
FutureClass.__index = FutureClass
FutureClass.ClassName = "Future"

export type Future<T> = typeof(setmetatable(
	{} :: {
		_typecast: T,

		type: "Pending" | "Completed",
		awaiting: { [thread]: boolean },
		value: T?,
	},
	FutureClass
))

-- Constructors

function FutureClass.raw<T>()
	local self = setmetatable({}, FutureClass) :: Future<T>

	self._typecast = (nil :: any) :: T

	self.type = "Pending"
	self.awaiting = {}
	self.value = nil

	return self
end

function FutureClass.race<T>(futures: { Future<any> })
	for _, future in futures do
		if future.type == "Completed" then
			return future
		end
	end

	local future = FutureClass.raw() :: Future<T>

	task.spawn(function()
		local thread = coroutine.running()
		for _, future in futures do
			assert(future.type == "Pending")
			future.awaiting[thread] = true
		end

		local value = coroutine.yield()
		for _, future in futures do
			if future.type == "Pending" then
				future.awaiting[thread] = nil
			end
		end

		future:complete(value)
	end)

	return future
end

-- Public

function FutureClass.isCompleted<T>(self: Future<T>)
	return self.type == "Completed"
end

function FutureClass.complete<T>(self: Future<T>, value: T)
	assert(self.type ~= "Completed", "Cannot complete a future that is already completed")

	self.type = "Completed"
	self.value = value

	local awaiting = self.awaiting
	self.awaiting = {}
	for thread, _ in awaiting do
		task.spawn(thread, value)
	end
end

function FutureClass.expect<T>(self: Future<T>): T
	if self.type == "Completed" then
		return self.value :: T
	end

	local thread = coroutine.running()
	self.awaiting[thread] = true
	return coroutine.yield()
end

--

return FutureClass
