--!strict

local function packAsCallback<T...>(...: T...): () -> T...
	local n = select("#", ...)
	local packed = { select(1, ...) }
	return function()
		return unpack(packed, 1, n)
	end
end

-- Class

local FutureStatic = {}

local FutureClass = {}
FutureClass.__index = FutureClass
FutureClass.ClassName = "Future"

export type Future<T...> = typeof(setmetatable(
	{} :: {
		type: "Pending" | "Completed",
		awaiting: { [thread]: boolean },
		value: () -> T...,
	},
	FutureClass
))

-- Constructors

function FutureStatic.raw<T...>()
	local self = setmetatable({}, FutureClass) :: Future<T...>

	self.type = "Pending"
	self.awaiting = {}
	self.value = nil :: any

	return self
end

function FutureStatic.race<T...>(futures: { Future<...any> })
	for _, future in futures do
		if future.type == "Completed" then
			return future
		end
	end

	local future = FutureStatic.raw() :: Future<T...>

	task.spawn(function()
		local thread = coroutine.running()
		for _, racingFuture in futures do
			assert(racingFuture.type == "Pending", "Future is already completed.")
			racingFuture.awaiting[thread] = true
		end

		local packedValues = packAsCallback(coroutine.yield())
		for _, racingFuture in futures do
			if racingFuture.type == "Pending" then
				racingFuture.awaiting[thread] = nil
			end
		end

		future:complete(packedValues())
	end)

	return future
end

-- Public

function FutureClass.isCompleted<T...>(self: Future<T...>)
	return self.type == "Completed"
end

function FutureClass.complete<T...>(self: Future<T...>, ...: T...)
	assert(self.type ~= "Completed", "Cannot complete a future that is already completed")

	self.type = "Completed"
	self.value = packAsCallback(...)

	local awaiting = self.awaiting
	self.awaiting = {}
	for thread, _ in awaiting do
		task.spawn(thread, ...)
	end
end

function FutureClass.expect<T...>(self: Future<T...>): T...
	if self.type == "Completed" then
		return self.value()
	end

	local thread = coroutine.running()
	self.awaiting[thread] = true
	return coroutine.yield()
end

--

return FutureStatic
