--!strict

local FutureStatic = {}

local FutureClass = {}
FutureClass.__index = FutureClass
FutureClass.ClassName = "Future"

export type Future<T> = typeof(setmetatable(
	{} :: {
		type: "pending" | "completed",
		awaiting: { [thread]: boolean },
		value: T,
	},
	FutureClass
))

-- Constructors

function FutureStatic.new<T>()
	local self = setmetatable({}, FutureClass) :: Future<T>

	self.type = "pending"
	self.awaiting = {}
	self.value = (nil :: any) :: T

	return self
end

function FutureStatic.completed<T>(value: T)
	local future = FutureStatic.new()
	future:complete(value)
	return future
end

function FutureStatic.race<T>(racingFutures: { Future<T> })
	for _, racingFuture in racingFutures do
		if racingFuture.type == "completed" then
			return FutureStatic.completed(racingFuture.value)
		end
	end

	local future = FutureStatic.new() :: Future<T>

	task.spawn(function()
		for _, racingFuture in racingFutures do
			if racingFuture.type == "completed" then
				future:complete(racingFuture.value)
				return
			end
		end

		local thread = coroutine.running()
		for _, racingFuture in racingFutures do
			racingFuture.awaiting[thread] = true
		end

		local value = coroutine.yield()
		for _, racingFuture in racingFutures do
			racingFuture.awaiting[thread] = nil
		end

		future:complete(value)
	end)

	return future
end

-- Static

function FutureStatic.packAsCallback<T...>(...: T...)
	local packed = table.pack(...)
	return function(): T...
		return table.unpack(packed :: { any }, 1, packed.n)
	end
end

-- Public

function FutureClass.isCompleted<T>(self: Future<T>)
	return self.type == "completed"
end

function FutureClass.complete<T>(self: Future<T>, value: T)
	assert(self.type == "pending", "Cannot complete a future that is already completed")

	self.type = "completed"
	self.value = value

	local awaiting = self.awaiting
	self.awaiting = {}
	for thread, _ in awaiting do
		task.spawn(thread, value)
	end
end

function FutureClass.expect<T>(self: Future<T>)
	if self.type == "pending" then
		local thread = coroutine.running()
		self.awaiting[thread] = true
		coroutine.yield()
	end
	return self.value
end

--

return FutureStatic
